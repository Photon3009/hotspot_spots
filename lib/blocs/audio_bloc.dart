import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';

// Events
abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object> get props => [];
}

class StartRecording extends AudioEvent {}

class StopRecording extends AudioEvent {}

class PlayAudio extends AudioEvent {}

class PauseAudio extends AudioEvent {}

class DeleteAudio extends AudioEvent {}

class UpdateDuration extends AudioEvent {
  final Duration duration;
  const UpdateDuration(this.duration);

  @override
  List<Object> get props => [duration];
}

class AudioPlaybackCompleted extends AudioEvent {}

// States
abstract class AudioState extends Equatable {
  final bool isAudioPlaying;
  final bool isAudioRecording;
  final bool isRecorderVisible;
  final RecorderController? recorderController;
  final PlayerController? playerController;
  final Duration? duration;

  const AudioState({
    required this.isRecorderVisible,
    required this.isAudioPlaying,
    required this.isAudioRecording,
    this.recorderController,
    this.playerController,
    this.duration,
  });

  @override
  List<Object?> get props => [
        isRecorderVisible,
        isAudioPlaying,
        isAudioRecording,
        recorderController,
        playerController,
        duration,
      ];
}

class AudioInitial extends AudioState {
  const AudioInitial()
      : super(
          isRecorderVisible: false,
          isAudioPlaying: false,
          isAudioRecording: false,
        );
}

class AudioRecording extends AudioState {
  const AudioRecording({
    required RecorderController recorderController,
    required Duration duration,
  }) : super(
          isRecorderVisible: true,
          isAudioPlaying: false,
          isAudioRecording: true,
          recorderController: recorderController,
          duration: duration,
        );
}

class AudioRecorded extends AudioState {
  final String path;

  const AudioRecorded({
    required this.path,
    required PlayerController playerController,
    required Duration duration,
  }) : super(
          isRecorderVisible: true,
          isAudioPlaying: false,
          isAudioRecording: false,
          playerController: playerController,
          duration: duration,
        );

  @override
  List<Object> get props => [super.props, path];
}

class AudioPlaying extends AudioState {
  const AudioPlaying({
    required PlayerController playerController,
    required Duration duration,
  }) : super(
          isRecorderVisible: true,
          isAudioPlaying: true,
          isAudioRecording: false,
          playerController: playerController,
          duration: duration,
        );
}

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  RecorderController? _recorderController;
  PlayerController? _playerController;
  String? _recordingPath;
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  AudioBloc() : super(const AudioInitial()) {
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<DeleteAudio>(_onDeleteAudio);
    on<UpdateDuration>(_onUpdateDuration);
    on<AudioPlaybackCompleted>(_onAudioPlaybackCompleted);
  }

  Future<void> _onStartRecording(
      StartRecording event, Emitter<AudioState> emit) async {
    final directory = await getApplicationDocumentsDirectory();
    _recordingPath = p.join(
        directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.wav');

    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    await _recorderController!.record(path: _recordingPath);

    _recordingDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      add(UpdateDuration(_recordingDuration));
    });

    debugPrint("State: AudioRecording");

    emit(AudioRecording(
      recorderController: _recorderController!,
      duration: _recordingDuration,
    ));
  }

  Future<void> _onStopRecording(
      StopRecording event, Emitter<AudioState> emit) async {
    final path = await _recorderController?.stop();
    _recorderController?.dispose();
    _durationTimer?.cancel();

    if (path != null) {
      _playerController = PlayerController();
      await _playerController!.preparePlayer(
        path: path,
        noOfSamples: 100,
      );
      debugPrint("State: AudioRecorded");
      emit(AudioRecorded(
        path: path,
        playerController: _playerController!,
        duration: _recordingDuration,
      ));
    } else {
      debugPrint("State: AudioInitial");
      emit(const AudioInitial());
    }
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<AudioState> emit) async {
    if (_recordingPath != null) {
      try {
        final currentState = _playerController!.playerState;

        // Reset player if it's not in a playable state
        if (currentState != PlayerState.initialized &&
            currentState != PlayerState.paused) {
          await _playerController!.stopPlayer();
          await _playerController!.preparePlayer(
            path: _recordingPath!,
            noOfSamples: 100,
          );
        }

        await _playerController!.startPlayer();
        _playerStateSubscription?.cancel();
        _playerStateSubscription =
            _playerController!.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.stopped) {
            add(AudioPlaybackCompleted());
          }
        });
        debugPrint("State: AudioPlaying");
        emit(AudioPlaying(
          playerController: _playerController!,
          duration: _recordingDuration,
        ));
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    } else {}
  }

  void _onPauseAudio(PauseAudio event, Emitter<AudioState> emit) async {
    if (_playerController != null) {
      try {
        await _playerController!.pausePlayer();
        debugPrint("State: AudioPaused");
        emit(AudioRecorded(
          path: _recordingPath!,
          playerController: _playerController!,
          duration: _recordingDuration,
        ));
      } catch (e) {
        debugPrint('Error pausing audio: $e');
      }
    }
  }

  void _onAudioPlaybackCompleted(
      AudioPlaybackCompleted event, Emitter<AudioState> emit) {
    if (state is AudioPlaying) {
      debugPrint("State: AudioRecorded/Completed");
      emit(AudioRecorded(
        path: _recordingPath!,
        playerController: _playerController!,
        duration: _recordingDuration,
      ));
    }
  }

  Future<void> _onDeleteAudio(
      DeleteAudio event, Emitter<AudioState> emit) async {
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _recordingPath = null;
      _recordingDuration = Duration.zero;
      await _audioPlayer.stop();
      _playerController?.dispose();
      _playerController = null;
      debugPrint("State: AudioInitial/deleted");
      emit(const AudioInitial());
    }
  }

  void _onUpdateDuration(UpdateDuration event, Emitter<AudioState> emit) {
    if (state is AudioRecording) {
      debugPrint("State: AudioRecording/duration");
      emit(AudioRecording(
        recorderController: _recorderController!,
        duration: event.duration,
      ));
    }
  }

  @override
  Future<void> close() async {
    _durationTimer?.cancel();
    await _audioPlayer.dispose();
    _recorderController?.dispose();
    _playerController?.dispose();
    return super.close();
  }
}
