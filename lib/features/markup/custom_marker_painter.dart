import 'package:flutter/material.dart';

class CustomMarkerPainter extends CustomPainter {
  final Color borderColor;
  final Color dotColor;
  final Color highlightColor;

    CustomMarkerPainter({
    required this.borderColor,
    required this.dotColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 5;
    final innerRadius = outerRadius / 4;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // highlight
    paint.color = highlightColor.withAlpha(100);
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    // Draw the outer circle
    paint.strokeWidth = 3; 
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius + 2, paint);

    // remove blur
    paint.maskFilter = null;

    // draw the outer ring
    paint.color = borderColor; // Outer ring color
    paint.strokeWidth = 1;
    canvas.drawCircle(center, outerRadius, paint);

    // Draw the inner ring
    paint.color = dotColor;
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerRadius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
