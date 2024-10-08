import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotspot_hosts/blocs/audio_bloc.dart';
import 'package:hotspot_hosts/blocs/video_bloc.dart';
import 'package:hotspot_hosts/screens/experience_screen.dart';
import 'package:hotspot_hosts/screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => VideoBloc()),
        BlocProvider(create: (context) => AudioBloc()),
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => ExperienceSelectionScreen(),
          '/onboarding': (context) => const OnboardingScreen(), // Second screen
        },
      ),
    );
  }
}
