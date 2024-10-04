import 'package:flutter/material.dart';
import 'dart:math' as math;

class CurvyBackground extends StatelessWidget {
  final Widget child;

  CurvyBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: WavyPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class WavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    const double waveHeight = 20.0;
    const double waveWidth = 24.0;
    const double lineSpacing = 20.0;

    for (double y = -waveHeight;
        y < size.height;
        y += waveHeight * 2 + lineSpacing) {
      path.reset();
      for (double x = 0; x <= size.width + waveWidth; x += waveWidth) {
        path.relativeQuadraticBezierTo(
            waveWidth / 2, -waveHeight * 0.7, waveWidth, 0);
        path.relativeQuadraticBezierTo(
            waveWidth / 2, waveHeight * 0.7, waveWidth, 0);
      }
      canvas.save();
      canvas.translate(0, y);
      canvas.rotate(-math.pi * 0.7 / 4); // Rotate 45 degrees
      canvas.drawPath(path, paint);
      canvas.restore();

      // // Decrease opacity for gradient effect as we go down
      paint.color = paint.color.withOpacity(paint.color.opacity - 0.008);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
