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
    // Center the handle exactly on the corner: half inside, half outside
    final double half = size / 2;
    double ox = 0, oy = 0;
    if (alignment == Alignment.topLeft) {
      ox = -half;
      oy = -half;
    } else if (alignment == Alignment.topRight) {
      ox = half;
      oy = -half;
    } else if (alignment == Alignment.bottomLeft) {
      ox = -half;
      oy = half;
    } else if (alignment == Alignment.bottomRight) {
      ox = half;
      oy = half;
    }

    // Direction vector pointing inward from the corner
    Offset dir;
    if (alignment == Alignment.topLeft) dir = const Offset(1, 1);
    else if (alignment == Alignment.topRight) dir = const Offset(-1, 1);
    else if (alignment == Alignment.bottomLeft) dir = const Offset(1, -1);
    else dir = const Offset(-1, -1);

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(ox, oy),
        child: GestureDetector(
          onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
