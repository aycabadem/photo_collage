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
              colors: [Colors.blue[300]!, Colors.blue[500]!],
            ),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.open_in_full, color: Colors.white, size: 10),
        ),
      ),
    );
  }
}
