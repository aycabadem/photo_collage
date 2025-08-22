import 'package:flutter/material.dart';
import '../models/photo_box.dart';

/// Widget that draws smart borders only on outer edges
class SmartBorderOverlay extends StatelessWidget {
  final PhotoBox box;
  final double borderWidth;
  final Color borderColor;
  final List<PhotoBox> otherBoxes;

  const SmartBorderOverlay({
    super.key,
    required this.box,
    required this.borderWidth,
    required this.borderColor,
    required this.otherBoxes,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(box.size.width, box.size.height),
      painter: SmartBorderPainter(
        borderWidth: borderWidth,
        borderColor: borderColor,
        otherBoxes: otherBoxes,
      ),
    );
  }
}

/// Custom painter for smart border rendering
class SmartBorderPainter extends CustomPainter {
  final double borderWidth;
  final Color borderColor;
  final List<PhotoBox> otherBoxes;

  SmartBorderPainter({
    required this.borderWidth,
    required this.borderColor,
    required this.otherBoxes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Check which edges should have borders
    final hasLeftBorder = _shouldDrawLeftBorder(size);
    final hasRightBorder = _shouldDrawRightBorder(size);
    final hasTopBorder = _shouldDrawTopBorder(size);
    final hasBottomBorder = _shouldDrawBottomBorder(size);

    // Draw borders only where needed
    if (hasLeftBorder) {
      canvas.drawLine(
        Offset(borderWidth / 2, 0),
        Offset(borderWidth / 2, size.height),
        paint,
      );
    }

    if (hasRightBorder) {
      canvas.drawLine(
        Offset(size.width - borderWidth / 2, 0),
        Offset(size.width - borderWidth / 2, size.height),
        paint,
      );
    }

    if (hasTopBorder) {
      canvas.drawLine(
        Offset(0, borderWidth / 2),
        Offset(size.width, borderWidth / 2),
        paint,
      );
    }

    if (hasBottomBorder) {
      canvas.drawLine(
        Offset(0, size.height - borderWidth / 2),
        Offset(size.width, size.height - borderWidth / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// Check if left edge should have border
  bool _shouldDrawLeftBorder(Size size) {
    for (final otherBox in otherBoxes) {
      // Check if there's a box to the left that touches this one
      if ((otherBox.position.dx + otherBox.size.width - 0).abs() <=
              borderWidth &&
          _boxesOverlapVertically(otherBox, size)) {
        return false; // Don't draw left border
      }
    }
    return true; // Draw left border
  }

  /// Check if right edge should have border
  bool _shouldDrawRightBorder(Size size) {
    for (final otherBox in otherBoxes) {
      // Check if there's a box to the right that touches this one
      if ((otherBox.position.dx - size.width).abs() <= borderWidth &&
          _boxesOverlapVertically(otherBox, size)) {
        return false; // Don't draw right border
      }
    }
    return true; // Draw right border
  }

  /// Check if top edge should have border
  bool _shouldDrawTopBorder(Size size) {
    for (final otherBox in otherBoxes) {
      // Check if there's a box above that touches this one
      if ((otherBox.position.dy + otherBox.size.height - 0).abs() <=
              borderWidth &&
          _boxesOverlapHorizontally(otherBox, size)) {
        return false; // Don't draw top border
      }
    }
    return true; // Draw top border
  }

  /// Check if bottom edge should have border
  bool _shouldDrawBottomBorder(Size size) {
    for (final otherBox in otherBoxes) {
      // Check if there's a box below that touches this one
      if ((otherBox.position.dy - size.height).abs() <= borderWidth &&
          _boxesOverlapHorizontally(otherBox, size)) {
        return false; // Don't draw bottom border
      }
    }
    return true; // Draw bottom border
  }

  /// Check if two boxes overlap vertically
  bool _boxesOverlapVertically(PhotoBox otherBox, Size size) {
    final thisTop = 0.0;
    final thisBottom = size.height;
    final otherTop = otherBox.position.dy;
    final otherBottom = otherBox.position.dy + otherBox.size.height;

    return !(thisBottom <= otherTop || thisTop >= otherBottom);
  }

  /// Check if two boxes overlap horizontally
  bool _boxesOverlapHorizontally(PhotoBox otherBox, Size size) {
    final thisLeft = 0.0;
    final thisRight = size.width;
    final otherLeft = otherBox.position.dx;
    final otherRight = otherBox.position.dx + otherBox.size.width;

    return !(thisRight <= otherLeft || thisLeft >= otherRight);
  }
}
