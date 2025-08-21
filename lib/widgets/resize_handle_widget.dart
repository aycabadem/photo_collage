import 'package:flutter/material.dart';
import '../models/photo_box.dart';

/// Widget for displaying resize handles on photo boxes
class ResizeHandleWidget extends StatelessWidget {
  /// The photo box this handle belongs to
  final PhotoBox box;

  /// The alignment position of this handle
  final Alignment alignment;

  /// Size of the handle
  final double size;

  /// Callback when the handle is dragged
  final void Function(double dx, double dy) onDrag;

  const ResizeHandleWidget({
    super.key,
    required this.box,
    required this.alignment,
    required this.size,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    double left = box.position.dx;
    double top = box.position.dy;

    // Calculate position based on alignment
    if (alignment == Alignment.topRight) left += box.size.width - size;
    if (alignment == Alignment.bottomLeft) top += box.size.height - size;
    if (alignment == Alignment.bottomRight) {
      left += box.size.width - size;
      top += box.size.height - size;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[400]!, Colors.blue[600]!],
            ),
            borderRadius: BorderRadius.circular(size / 2), // Perfect circle
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.open_in_full,
            color: Colors.white,
            size: size * 0.6, // Proportional icon size
          ),
        ),
      ),
    );
  }
}
