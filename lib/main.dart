import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotspot_hosts/blocs/audio_bloc.dart';
import 'package:hotspot_hosts/blocs/video_bloc.dart';
import 'package:hotspot_hosts/screens/experience_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Experience Host App',
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AudioBloc>(create: (context) => AudioBloc()),
          BlocProvider<VideoBloc>(create: (context) => VideoBloc()),
        ],
        child: Builder(
          builder: (context) => ExperienceSelectionScreen(
            videoBloc: BlocProvider.of<VideoBloc>(context),
            audioBloc: BlocProvider.of<AudioBloc>(context),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
