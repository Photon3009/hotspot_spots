import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Replace this with your actual SquigglyWaveform widget.
class SquigglyWaveform extends StatelessWidget {
  final List<double> samples;
  final double height;
  final double strokeWidth;
  final bool showActiveWaveform;
  final double width;
  final Color activeColor;
  final Color inactiveColor;

  const SquigglyWaveform({
    super.key,
    required this.samples,
    required this.height,
    required this.strokeWidth,
    required this.showActiveWaveform,
    required this.width,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: WaveformPainter(samples, strokeWidth, activeColor),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double strokeWidth;
  final Color color;

  WaveformPainter(this.samples, this.strokeWidth, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Create a path for the wave
    Path path = Path();

    // Move to the starting point
    var startX = 0.0;
    final startY = size.height / 2; // Midline
    path.moveTo(startX, startY);

    for (int i = 0; i < samples.length; i++) {
      // Calculate X position for each sample
      final x = (i / (samples.length - 1)) * size.width;

      // Calculate height based on the sample value
      final lineHeight =
          (samples[i] / 100) * (size.height / 2); // Adjust divisor if needed

      // Draw the top part of the wave
      final topY = (size.height / 2) - lineHeight; // Y position for top wave
      final bottomY =
          (size.height / 2) + lineHeight; // Y position for bottom wave

      // If it's the first point, just move to it
      if (i == 0) {
        path.lineTo(x, topY);
        path.lineTo(x, bottomY);
      } else {
        // Use quadraticBezierTo for roundness between points
        path.quadraticBezierTo(
          (startX + x) / 2, // Control point for smoothness
          (startY + topY) / 2, // Control point Y for the top curve
          x, topY,
        );
        path.lineTo(x, bottomY);
      }

      startX = x; // Update startX for the next segment
    }

    // Draw the complete wave
    canvas.drawPath(path, paint);

    // Draw the bottom part of the wave
    path = Path();
    path.moveTo(0, size.height / 2); // Start at the middle line
    for (int i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final lineHeight = (samples[i] / 100) * (size.height / 2);
      final bottomY =
          (size.height / 2) + lineHeight; // Y position for bottom wave

      if (i == 0) {
        path.lineTo(x, bottomY);
      } else {
        path.quadraticBezierTo(
          (startX + x) / 2,
          (startY + bottomY) / 2,
          x,
          bottomY,
        );
      }

      startX = x; // Update startX for the next segment
    }

    // Draw the bottom wave
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class AudioWaveformPage extends StatefulWidget {
  const AudioWaveformPage({super.key});

  @override
  _AudioWaveformPageState createState() => _AudioWaveformPageState();
}

class _AudioWaveformPageState extends State<AudioWaveformPage> {
  final Random _random = Random();
  List<double> _waveformData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startGeneratingSamples();
  }

  void _startGeneratingSamples() {
    // Update the waveform data every 100 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _waveformData = List.generate(100, (index) => _random.nextDouble() * 100);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SquigglyWaveform(
      samples: _waveformData,
      height: 30,
      strokeWidth: 4,
      showActiveWaveform: true,
      width: MediaQuery.of(context).size.width * 0.6,
      activeColor: Colors.grey,
      inactiveColor: Colors.grey,
    );
  }
}
