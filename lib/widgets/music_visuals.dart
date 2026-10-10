import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/melody_theme.dart';

class MelodyMark extends StatelessWidget {
  final double size;

  const MelodyMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B7DD5), MelodyColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x227757B9),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.headphones_rounded,
        color: Colors.white,
        size: size * 0.58,
      ),
    );
  }
}

/// Decorative record artwork, drawn locally without extra image assets.
class RecordIllustration extends StatelessWidget {
  final double size;

  const RecordIllustration({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _RecordPainter()),
      ),
    );
  }
}

class _RecordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF695283), Color(0xFF30213F), Color(0xFF493256)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x287F6A96);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(center, radius * (0.48 + i * 0.055), groove);
    }

    canvas.drawArc(
      bounds.deflate(radius * 0.12),
      -math.pi * 0.85,
      math.pi * 0.38,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.07
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x337D6696),
    );
    canvas.drawCircle(
      center,
      radius * 0.36,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE9C7DE), Color(0xFFB59AE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    canvas.drawCircle(
      center,
      radius * 0.07,
      Paint()..color = MelodyColors.dark,
    );
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _RecordPainter oldDelegate) => false;
}
