import 'package:flutter/material.dart';

/// Custom painter for drawing the selection border around a rotated photo box
class SelectionBorderPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final Offset offset;

  SelectionBorderPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Adjust coordinates relative to the offset
    final adjustedTopLeft = topLeft - offset;
    final adjustedTopRight = topRight - offset;
    final adjustedBottomLeft = bottomLeft - offset;
    final adjustedBottomRight = bottomRight - offset;

    // Draw the border path
    path.moveTo(adjustedTopLeft.dx, adjustedTopLeft.dy);
    path.lineTo(adjustedTopRight.dx, adjustedTopRight.dy);
    path.lineTo(adjustedBottomRight.dx, adjustedBottomRight.dy);
    path.lineTo(adjustedBottomLeft.dx, adjustedBottomLeft.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SelectionBorderPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        topRight != oldDelegate.topRight ||
        bottomLeft != oldDelegate.bottomLeft ||
        bottomRight != oldDelegate.bottomRight ||
        offset != oldDelegate.offset;
  }
}
