// video_bloc.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

// Events
abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object> get props => [];
}

class StartVideoRecording extends VideoEvent {}

class InitializeCamera extends VideoEvent {}

class StopVideoRecording extends VideoEvent {}

class PlayVideo extends VideoEvent {}

class PauseVideo extends VideoEvent {}

class DeleteVideo extends VideoEvent {}

// States
abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {}

class CameraInitialized extends VideoState {
  final CameraController controller;
  const CameraInitialized(this.controller);

  @override
  List<Object> get props => [controller];
}

class VideoRecording extends VideoState {
  final CameraController controller;
  const VideoRecording(this.controller);

  @override
  List<Object> get props => [controller];
}

class VideoRecorded extends VideoState {
  final String path;
  final Duration duration;

  const VideoRecorded(this.path, this.duration);

  @override
  List<Object> get props => [path, duration];
}

class VideoPlaying extends VideoState {}

class VideoPaused extends VideoState {}

class VideoDeleted extends VideoState {}

// Bloc
class VideoBloc extends Bloc<VideoEvent, VideoState> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  String? _videoPath;

  VideoBloc() : super(VideoInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<StartVideoRecording>(_onStartVideoRecording);
    on<StopVideoRecording>(_onStopVideoRecording);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<DeleteVideo>(_onDeleteVideo);
  }

  Future<void> _onInitializeCamera(
      InitializeCamera event, Emitter<VideoState> emit) async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      emit(CameraInitialized(_cameraController!));
    }
  }

  Future<void> _onStartVideoRecording(
      StartVideoRecording event, Emitter<VideoState> emit) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final directory = await getApplicationDocumentsDirectory();
      _videoPath = p.join(
          directory.path, 'video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await _cameraController!.startVideoRecording();
      emit(VideoRecording(_cameraController!));
    }
  }

  Future<void> _onStopVideoRecording(
      StopVideoRecording event, Emitter<VideoState> emit) async {
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      final XFile file = await _cameraController!.stopVideoRecording();
      _videoPath = file.path;

      // Initialize VideoPlayerController to get video duration
      _videoPlayerController = VideoPlayerController.file(File(_videoPath!));
      await _videoPlayerController!.initialize();
      final Duration duration = _videoPlayerController!.value.duration;
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;

      emit(VideoRecorded(_videoPath!, duration));
    }
  }

  Future<void> _onPlayVideo(PlayVideo event, Emitter<VideoState> emit) async {
    if (_videoPath != null) {
      _videoPlayerController = VideoPlayerController.file(File(_videoPath!));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.play();
      emit(VideoPlaying());

      _videoPlayerController!.addListener(() {
        if (!_videoPlayerController!.value.isPlaying &&
            _videoPlayerController!.value.position >=
                _videoPlayerController!.value.duration) {
          add(PauseVideo());
        }
      });
    }
  }

  Future<void> _onPauseVideo(PauseVideo event, Emitter<VideoState> emit) async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.pause();
      emit(VideoPaused());
    }
  }

  Future<void> _onDeleteVideo(
      DeleteVideo event, Emitter<VideoState> emit) async {
    if (_videoPath != null) {
      final file = File(_videoPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _videoPath = null;
      await _videoPlayerController?.dispose();
      _videoPlayerController = null;
      emit(VideoDeleted());
    }
  }

  // Expose controllers if needed
  CameraController? get cameraController => _cameraController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  @override
  Future<void> close() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    return super.close();
  }
}
