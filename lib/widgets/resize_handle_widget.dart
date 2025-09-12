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
    // Place the handle centered on the corner (half inside, half outside)
    // Push the visible square mostly outside (about 70%)
    const double outsideFactor = 0.7; // 0.5 = half outside; >0.5 looks more pronounced
    final double offset = size * outsideFactor;
    double ox = 0, oy = 0;
    if (alignment == Alignment.topLeft) {
      ox = -offset;
      oy = -offset;
    } else if (alignment == Alignment.topRight) {
      ox = offset;
      oy = -offset;
    } else if (alignment == Alignment.bottomLeft) {
      ox = -offset;
      oy = offset;
    } else if (alignment == Alignment.bottomRight) {
      ox = offset;
      oy = offset;
    }

    // Keep a generous hit area while preserving the half-outside look
    const double hitPad = 16.0;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: size + hitPad,
          height: size + hitPad,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(ox, oy),
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
            ],
          ),
        ),
      ),
    );
  }
}
