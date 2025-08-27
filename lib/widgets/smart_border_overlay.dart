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
        box: box,
      ),
    );
  }
}

/// Custom painter for smart border rendering
class SmartBorderPainter extends CustomPainter {
  final double borderWidth;
  final Color borderColor;
  final List<PhotoBox> otherBoxes;
  final PhotoBox box; // Add box parameter

  SmartBorderPainter({
    required this.borderWidth,
    required this.borderColor,
    required this.otherBoxes,
    required this.box, // Add box parameter
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
    // Always draw left border if it's the leftmost edge of the collage
    if (box.position.dx <= 1) return true;

    for (final otherBox in otherBoxes) {
      // Check if there's a box to the left that touches this one
      // Left edge of current box should have border if there's a box touching it
      // But we need to ensure only one border is drawn between two boxes
      if ((otherBox.position.dx + otherBox.size.width - box.position.dx)
                  .abs() <=
              1 &&
          _boxesOverlapVertically(otherBox, size)) {
        // Only draw left border if this box is "leftmost" of the two touching boxes
        // This ensures only one border is drawn between two adjacent boxes
        if (box.position.dx < otherBox.position.dx) {
          return true; // Draw left border
        } else {
          return false; // Don't draw left border
        }
      }
    }
    return true; // Draw left border
  }

  /// Check if right edge should have border
  bool _shouldDrawRightBorder(Size size) {
    // Always draw right border if it's the rightmost edge of the collage
    // Note: We need to check against template size, but for now assume it's not the rightmost

    for (final otherBox in otherBoxes) {
      // Check if there's a box to the right that touches this one
      // Right edge of current box should have border if there's a box touching it
      // But we need to ensure only one border is drawn between two boxes
      if ((otherBox.position.dx - (box.position.dx + size.width)).abs() <= 1 &&
          _boxesOverlapVertically(otherBox, size)) {
        // Only draw right border if this box is "leftmost" of the two touching boxes
        // This ensures only one border is drawn between two adjacent boxes
        if (box.position.dx < otherBox.position.dx) {
          return true; // Draw right border
        } else {
          return false; // Don't draw right border
        }
      }
    }
    return true; // Draw right border
  }

  /// Check if top edge should have border
  bool _shouldDrawTopBorder(Size size) {
    // Always draw top border if it's the topmost edge of the collage
    if (box.position.dy <= 1) return true;

    for (final otherBox in otherBoxes) {
      // Check if there's a box above that touches this one
      // Top edge of current box should have border if there's a box touching it
      // But we need to ensure only one border is drawn between two boxes
      if ((otherBox.position.dy + otherBox.size.height - box.position.dy)
                  .abs() <=
              1 &&
          _boxesOverlapHorizontally(otherBox, size)) {
        // Only draw top border if this box is "topmost" of the two touching boxes
        // This ensures only one border is drawn between two adjacent boxes
        if (box.position.dy < otherBox.position.dy) {
          return true; // Draw top border
        } else {
          return false; // Don't draw top border
        }
      }
    }
    return true; // Draw top border
  }

  /// Check if bottom edge should have border
  bool _shouldDrawBottomBorder(Size size) {
    // Always draw bottom border if it's the bottommost edge of the collage
    // Note: We need to check against template size, but for now assume it's not the bottommost

    for (final otherBox in otherBoxes) {
      // Check if there's a box below that touches this one
      // Bottom edge of current box should have border if there's a box touching it
      // But we need to ensure only one border is drawn between two boxes
      if ((otherBox.position.dy - (box.position.dy + size.height)).abs() <= 1 &&
          _boxesOverlapHorizontally(otherBox, size)) {
        // Only draw bottom border if this box is "topmost" of the two touching boxes
        // This ensures only one border is drawn between two adjacent boxes
        if (box.position.dy < otherBox.position.dy) {
          return true; // Draw bottom border
        } else {
          return false; // Don't draw bottom border
        }
      }
    }
    return true; // Draw bottom border
  }

  /// Check if two boxes overlap vertically
  bool _boxesOverlapVertically(PhotoBox otherBox, Size size) {
    final thisTop = box.position.dy;
    final thisBottom = box.position.dy + size.height;
    final otherTop = otherBox.position.dy;
    final otherBottom = otherBox.position.dy + otherBox.size.height;

    return !(thisBottom <= otherTop || thisTop >= otherBottom);
  }

  /// Check if two boxes overlap horizontally
  bool _boxesOverlapHorizontally(PhotoBox otherBox, Size size) {
    final thisLeft = box.position.dx;
    final thisRight = box.position.dx + size.width;
    final otherLeft = otherBox.position.dx;
    final otherRight = otherBox.position.dx + otherBox.size.width;

    return !(thisRight <= otherLeft || thisLeft >= otherRight);
  }
}
