import 'package:flutter/material.dart';
import 'dart:math' as math;

class SquigglyWaveform extends StatefulWidget {
  final List<double> samples;
  final double height;
  final double strokeWidth;
  final bool showActiveWaveform;
  final double width;
  final Color activeColor;
  final Color inactiveColor;

  const SquigglyWaveform({
    Key? key,
    required this.samples,
    required this.height,
    required this.strokeWidth,
    required this.showActiveWaveform,
    required this.width,
    required this.activeColor,
    required this.inactiveColor,
  }) : super(key: key);

  @override
  State<SquigglyWaveform> createState() => _SquigglyWaveformState();
}

class _SquigglyWaveformState extends State<SquigglyWaveform> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant SquigglyWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.samples.length > oldWidget.samples.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [widget.activeColor.withOpacity(0), widget.activeColor],
            stops: const [0.0, 0.2],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: CustomPaint(
            size: Size(widget.samples.length.toDouble() * 2, widget.height),
            painter: WaveformPainter(
              widget.samples,
              widget.strokeWidth,
              widget.activeColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    final path = Path();
    final midY = size.height / 2;

    if (samples.isNotEmpty) {
      path.moveTo(0, midY);

      for (int i = 0; i < samples.length; i++) {
        final x = i * 2.0; // Increase space between samples
        final normalizedSample = samples[i] / 100; // Assuming max value is 100
        final y = midY + (normalizedSample * midY * math.sin(i * 0.1));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = (i - 1) * 2.0;
          final prevY =
              midY + (samples[i - 1] / 100 * midY * math.sin((i - 1) * 0.1));
          final controlX = (prevX + x) / 2;
          path.quadraticBezierTo(controlX, prevY, x, y);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
