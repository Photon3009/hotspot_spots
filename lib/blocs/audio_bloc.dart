// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:rxdart/rxdart.dart';

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

// States
abstract class AudioState extends Equatable {
  final bool isAudioPlaying;
  final bool isAudioRecording;
  final bool isRecorderVisible;
  final List<double> waveformData;

  const AudioState({
    required this.isRecorderVisible,
    required this.isAudioPlaying,
    required this.isAudioRecording,
    this.waveformData = const [],
  });

  @override
  List<Object> get props =>
      [isRecorderVisible, isAudioPlaying, isAudioRecording, waveformData];
}

class AudioInitial extends AudioState {
  const AudioInitial()
      : super(
            isRecorderVisible: false,
            isAudioPlaying: false,
            isAudioRecording: false);
}

class AudioRecording extends AudioState {
  final Stream<Duration> duration;

  const AudioRecording({
    required this.duration,
    required super.waveformData,
  }) : super(
          isRecorderVisible: true,
          isAudioPlaying: false,
          isAudioRecording: true,
        );

  @override
  List<Object> get props => [
        duration,
        isRecorderVisible,
        isAudioPlaying,
        isAudioRecording,
        waveformData
      ];
}

class AudioRecorded extends AudioState {
  final String path;

  const AudioRecorded({required this.path, required super.waveformData})
      : super(
            isRecorderVisible: true,
            isAudioPlaying: false,
            isAudioRecording: false);

  @override
  List<Object> get props =>
      [path, isRecorderVisible, isAudioPlaying, isAudioRecording];
}

class AudioPlaying extends AudioState {
  const AudioPlaying({required super.waveformData})
      : super(
          isRecorderVisible: true,
          isAudioPlaying: true,
          isAudioRecording: false,
        );
}

class AudioPaused extends AudioState {
  const AudioPaused({required super.waveformData})
      : super(
            isRecorderVisible: true,
            isAudioPlaying: false,
            isAudioRecording: false);
}

class AudioDeletedState extends AudioState {
  const AudioDeletedState({required super.waveformData})
      : super(
            isRecorderVisible: false,
            isAudioPlaying: false,
            isAudioRecording: false);
}

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<double> _waveformData = [];

  String? _recordingPath;
  Stream<Duration> _durationTimer = Stream<Duration>.periodic(
      const Duration(seconds: 1), (count) => Duration(seconds: count));
  bool _isTimer = false;

  AudioBloc() : super(const AudioInitial()) {
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<DeleteAudio>(_onDeleteAudio);
  }

  Future<void> _onStartRecording(
      StartRecording event, Emitter<AudioState> emit) async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = p.join(
          directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.wav');

      await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
      _isTimer = true;

      // Initialize the duration timer
      _durationTimer = Stream<Duration>.periodic(
        const Duration(seconds: 1),
        (count) => Duration(seconds: count),
      ).takeWhile((_) => _isTimer);

      // Clear previous waveform data
      _waveformData.clear();

      // Create a broadcast stream for amplitude changes
      final amplitudeStream = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .asBroadcastStream();

      // Listen to the amplitude changes and emit a new state with updated waveform data
      amplitudeStream.listen((amp) {
        _waveformData.add(amp.current.toDouble());
        print("Waveform data updated: $_waveformData");

        // Emit a new AudioRecording state whenever there's an update
        emit(AudioRecording(
          duration: _durationTimer,
          waveformData: List.from(_waveformData),
        ));
      });

      // // Optional: Listen for duration changes and emit state updates
      // _durationTimer.listen((duration) {
      //   emit(AudioRecording(
      //     duration: _durationTimer,
      //     waveformData: List.from(_waveformData),
      //   ));
      // });
      emit(AudioRecording(
        duration: _durationTimer,
        waveformData: List.from(_waveformData),
      ));
      print("Recording started.");
    } else {
      print("Recording permission denied.");
    }
  }

  Future<void> _onStopRecording(
      StopRecording event, Emitter<AudioState> emit) async {
    _isTimer = false;
    final path = await _audioRecorder.stop();
    if (path != null) {
      print("audio recorded✨✨✨✨✨✨");
      emit(AudioRecorded(path: path, waveformData: List.from(_waveformData)));
    } else {
      emit(const AudioDeletedState(waveformData: []));
    }
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<AudioState> emit) async {
    if (_recordingPath != null) {
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
      print("audio playing✨✨✨✨✨✨");

      _audioPlayer.positionStream.listen((position) {
        final progress =
            position.inMilliseconds / _audioPlayer.duration!.inMilliseconds;
        final visibleWaveform =
            _waveformData.sublist(0, (_waveformData.length * progress).round());
        emit(AudioPlaying(waveformData: visibleWaveform));
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          print("audio paused✨✨✨✨✨✨");
          add(PauseAudio());
        }
      });
    }
  }

  Future<void> _onPauseAudio(PauseAudio event, Emitter<AudioState> emit) async {
    await _audioPlayer.pause();
    print("audio paused✨✨✨✨✨✨");
    emit(AudioPaused(waveformData: List.from(_waveformData)));
  }

  Future<void> _onDeleteAudio(
      DeleteAudio event, Emitter<AudioState> emit) async {
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _recordingPath = null;
      await _audioPlayer.stop();
      print("audio deletded✨✨✨✨✨✨");
      emit(const AudioDeletedState(waveformData: []));
    }
  }

  @override
  Future<void> close() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    return super.close();
  }
}
