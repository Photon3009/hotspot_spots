import 'package:flutter/material.dart';

class WavyLinePainter extends CustomPainter {
  final int currentPage;
  final int totalPages;
  final double waveWidth; // Width of each wave

  WavyLinePainter({
    required this.currentPage,
    required this.totalPages,
    required this.waveWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF9196FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double waveWidth = size.width / 23;
    final double waveHeight = size.height * 0.1;

    // Create the curvy path
    final Path path = Path();
    path.moveTo(0, size.height / 2);

    for (int i = 0; i < 12; i++) {
      path.relativeQuadraticBezierTo(
        waveWidth / 2,
        -waveHeight,
        waveWidth,
        0,
      );
      path.relativeQuadraticBezierTo(
        waveWidth / 2,
        waveHeight,
        waveWidth,
        0,
      );
    }

    canvas.drawPath(path, borderPaint);

    final Path progressPath = Path();
    progressPath.moveTo(
        0, size.height / 2); // Start at the same position as the main path

    // Create the wavy path for the progress fill
    for (int i = 0; i < ((currentPage / totalPages) * 12).round(); i++) {
      progressPath.relativeQuadraticBezierTo(
          waveWidth / 2, -waveHeight, waveWidth, 0);
      progressPath.relativeQuadraticBezierTo(
          waveWidth / 2, waveHeight, waveWidth, 0);
    }
    canvas.drawPath(progressPath, fillPaint);
  }

  @override
  bool shouldRepaint(WavyLinePainter oldDelegate) {
    return oldDelegate.currentPage != currentPage ||
        oldDelegate.totalPages != totalPages ||
        oldDelegate.waveWidth != waveWidth;
  }
}
