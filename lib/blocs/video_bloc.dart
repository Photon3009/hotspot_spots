// video_bloc.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;

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
  final Uint8List frame;

  const VideoRecorded(this.path, this.duration, this.frame);

  @override
  List<Object> get props => [path, duration, frame];
}

class VideoPlaying extends VideoState {}

class VideoPaused extends VideoState {
  final Uint8List frame;

  const VideoPaused(this.frame);

  @override
  List<Object?> get props => [frame];
}

class VideoDeleted extends VideoState {}

// Bloc
class VideoBloc extends Bloc<VideoEvent, VideoState> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  String? _videoPath;
  CameraController? get cameraController => _cameraController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  Uint8List? _thumbnail;

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
      _thumbnail = await video_thumbnail.VideoThumbnail.thumbnailData(
        video: _videoPath!,
        imageFormat: video_thumbnail.ImageFormat.JPEG, // Use the alias
        maxHeight: 60, // specify the thumbnail height
        quality: 75,
      );
      // Initialize VideoPlayerController to get video duration
      _videoPlayerController = VideoPlayerController.file(File(_videoPath!));
      await _videoPlayerController!.initialize();
      //      // Capture a frame from the video at 1 second (or any other timestamp)
      // final frame = await _captureFrameAt(1); // 1 second
      // Generate a thumbnail from the recorded video

      final Duration duration = _videoPlayerController!.value.duration;
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;

      emit(VideoRecorded(_videoPath!, duration, _thumbnail!));
    }
  }

// Future<Uint8List?> _captureFrameAt(int second) async {
//   if (_videoPlayerController != null &&
//       _videoPlayerController!.value.isInitialized) {
//     await _videoPlayerController!.seekTo(Duration(seconds: second));
//     final frame = await _videoPlayerController!.getSnapshot();
//     return frame; // Returns a frame as Uint8List
//   }
//   return null;
// }
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
      emit(VideoPaused(_thumbnail!));
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

  @override
  Future<void> close() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    return super.close();
  }
}
