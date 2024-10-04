import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotspot_hosts/blocs/audio_bloc.dart';
import 'package:hotspot_hosts/blocs/video_bloc.dart';
import 'package:hotspot_hosts/widgets/audio_wave.dart';
import 'package:hotspot_hosts/widgets/build_buttons.dart';
import 'package:hotspot_hosts/widgets/curvy_background.dart';
import 'package:hotspot_hosts/widgets/next_button.dart';
import 'package:hotspot_hosts/widgets/wavy_line_progress.dart';
import 'package:just_audio/just_audio.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dispatch InitializeCamera event to VideoBloc
    context.read<VideoBloc>().add(InitializeCamera());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Future<Duration> _getAudioDuration(AudioState state) async {
    if (state is! AudioRecording) {
      final player = AudioPlayer();
      await player.setFilePath(state is AudioRecorded ? state.path : '');
      final duration = player.duration ?? Duration.zero;
      await player.dispose();
      return duration;
    }
    return Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 2.0,
              colors: [
                Colors.grey[700]!,
                Colors.grey[900]!,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomPaint(
          size: const Size(double.infinity, 50),
          painter:
              WavyLinePainter(currentPage: 2, totalPages: 2, waveWidth: 10),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: CurvyBackground(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: BlocBuilder<VideoBloc, VideoState>(
              builder: (context, videoState) {
                // Determine if the video is recording or playing
                final isVideoActive =
                    videoState is VideoRecording || videoState is VideoPlaying;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isVideoActive) ...[
                      SizedBox(
                        height: screenHeight * 0.34,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 3, bottom: 5),
                        child: Text(
                          '02',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Text(
                        'Why do you want to host with us?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell us about your intent and what motivates you to create experiences.',
                        style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.grey[400],
                            fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(),
                      const SizedBox(height: 8),
                      BlocBuilder<AudioBloc, AudioState>(
                        builder: (context, audioState) {
                          if (audioState is AudioRecording ||
                              audioState is AudioRecorded ||
                              audioState is AudioPlaying ||
                              audioState is AudioPaused) {
                            return _buildRecorderSection(context, audioState);
                          }
                          return Container();
                        },
                      ),
                    ],
                    if (videoState is VideoRecording)
                      _buildVideoRecordingSection(context, videoState)
                    else if (videoState is VideoRecorded)
                      _buildVideoRecordedSection(context, videoState)
                    else if (videoState is VideoPlaying ||
                        videoState is VideoPaused)
                      _buildVideoPlaybackSection(context, videoState)
                    else
                      Container(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Row _buildAppBarTitle() {
    return Row(
      children: [
        Container(width: 20, height: 4, color: const Color(0xFF9196FF)),
        const SizedBox(width: 4),
        Container(width: 20, height: 4, color: Colors.grey),
      ],
    );
  }

  TextField _buildTextField() {
    return TextField(
      controller: _textController,
      style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w400),
      maxLines: 7,
      decoration: InputDecoration(
        fillColor: Colors.grey[900], // Add this line
        filled: true,
        hintText: '/Start typing here',
        hintStyle: TextStyle(color: Colors.grey[600]),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Colors.transparent, width: 0),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildRecorderSection(BuildContext context, AudioState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[800]!,
              Colors.black,
            ],
            stops: const [
              0.0, // Position of the first color
              0.5, // Position of the second color (center)
              1.0, // Position of the third color
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  state is AudioRecording
                      ? 'Recording Audio...'
                      : 'Audio Recorded',
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 20),
                ),
                IconButton(
                  onPressed: () {
                    if (state is AudioRecording ||
                        state is AudioPlaying ||
                        state is AudioPaused ||
                        state is AudioRecorded) {
                      context.read<AudioBloc>().add(DeleteAudio());
                    }
                  },
                  icon: const Icon(Icons.delete, color: Color(0xFF9196FF)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildRecorderControls(context, state),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRecorderControls(BuildContext context, AudioState state) {
    final audioBloc = context.read<AudioBloc>();
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF9196FF),
          ),
          child: IconButton(
            onPressed: () {
              if (state is AudioRecording) {
                audioBloc.add(StopRecording());
              } else if (state is AudioRecorded || state is AudioPaused) {
                audioBloc.add(PlayAudio());
              } else if (state is AudioPlaying) {
                audioBloc.add(PauseAudio());
              }
            },
            icon: Icon(
              state is AudioRecording
                  ? Icons.stop
                  : (state is AudioPlaying
                      ? Icons.pause
                      : (state is AudioPaused || state is AudioRecorded
                          ? Icons.play_arrow
                          : Icons.mic)),
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        BlocBuilder<AudioBloc, AudioState>(
          builder: (context, state) {
            if (state is! AudioRecording) {
              return const SizedBox.shrink();
            }
            return AudioWaveformPage();
          },
        ),
        const SizedBox(width: 8),
        if (state is AudioRecording)
          StreamBuilder<Duration>(
            stream: state.duration,
            builder: (context, snapshot) {
              final duration = snapshot.data;
              return Text(
                _formatDuration(duration ?? Duration.zero),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              );
            },
          ),
        if (state is AudioPlaying ||
            state is AudioPaused ||
            state is AudioRecorded)
          BlocBuilder<AudioBloc, AudioState>(
            builder: (context, state) {
              if (state is! AudioRecording) {
                return FutureBuilder<Duration>(
                  future: _getAudioDuration(state),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        _formatDuration(snapshot.data!),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      );
                    }
                    return Container();
                  },
                );
              }
              return Container();
            },
          ),
      ],
    );
  }

  Widget _buildVideoRecordingSection(
      BuildContext context, VideoRecording state) {
    return SizedBox(
      child: CameraPreview(state.controller),
    );
  }

  Widget _buildVideoRecordedSection(BuildContext context, VideoRecorded state) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.grey[800]!,
            Colors.black,
          ],
          stops: const [
            0.0, // Position of the first color
            0.5, // Position of the second color (center)
            1.0, // Position of the third color
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              context.read<VideoBloc>().add(PlayVideo());
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          const Text(
            "Video Recorded",
            style: TextStyle(fontFamily: 'SpaceGrotesk', color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              context.read<VideoBloc>().add(DeleteVideo());
            },
            icon: const Icon(Icons.delete, color: Color(0xFF9196FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaybackSection(BuildContext context, VideoState state) {
    final videoBloc = context.read<VideoBloc>();
    final videoPlayerController = videoBloc.videoPlayerController;

    if (videoPlayerController == null ||
        !videoPlayerController.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: videoPlayerController.value.aspectRatio,
            child: VideoPlayer(videoPlayerController),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF9196FF),
                ),
                child: IconButton(
                  onPressed: () {
                    if (videoPlayerController.value.isPlaying) {
                      videoBloc.add(PauseVideo());
                    } else {
                      videoBloc.add(PlayVideo());
                    }
                  },
                  icon: Icon(
                    videoPlayerController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                "Playing",
                style:
                    TextStyle(fontFamily: 'SpaceGrotesk', color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  videoBloc.add(DeleteVideo());
                },
                icon: const Icon(Icons.delete, color: Color(0xFF9196FF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BottomAppBar _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            (_textController.text.isEmpty)
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocBuilder<AudioBloc, AudioState>(
                            builder: (context, state) {
                          return buildButton(
                            context: context,
                            icon: Icons.mic,
                            isSelected: state is AudioRecording,
                            onPressed: () {
                              context.read<AudioBloc>().add(StartRecording());
                            },
                          );
                        }),
                        Container(
                          color: Colors.grey.withOpacity(0.3),
                          height: 25,
                          width: 2,
                        ),
                        BlocBuilder<VideoBloc, VideoState>(
                            builder: (context, state) {
                          return buildButton(
                            context: context,
                            icon: Icons.videocam,
                            isSelected: state is VideoRecording,
                            onPressed: () {
                              if (state is VideoRecording) {
                                context
                                    .read<VideoBloc>()
                                    .add(StopVideoRecording());
                              } else {
                                context
                                    .read<VideoBloc>()
                                    .add(StartVideoRecording());
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  )
                : Container(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  width: _textController.text.isNotEmpty
                      ? MediaQuery.of(context).size.width - 80
                      : 0,
                  curve: Curves.easeInOut, // Animation curve
                  child: SizedBox(
                    height: 56,
                    child: NextButton(
                      isActive: _textController.text.isNotEmpty,
                      onPressed: () {
                        // Navigate to the next screen
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
