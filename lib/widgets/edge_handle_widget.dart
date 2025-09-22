import 'package:flutter/material.dart';

/// Edge line handle for resizing photo boxes (Adobe/Figma style)
class EdgeHandleWidget extends StatefulWidget {
  /// Whether this is a horizontal edge (top/bottom) or vertical edge (left/right)
  final bool isHorizontal;
  final VoidCallback? onTapDown;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onPanEnd;

  const EdgeHandleWidget({
    super.key,
    required this.isHorizontal,
    this.onTapDown,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  State<EdgeHandleWidget> createState() => _EdgeHandleWidgetState();
}

class _EdgeHandleWidgetState extends State<EdgeHandleWidget> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final double lineLength = _isHovered || _isDragging ? 24.0 : 20.0;
    final double lineThickness = _isHovered || _isDragging ? 3.0 : 2.0;
    final double hitArea = 16.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isDragging = true);
          widget.onTapDown?.call();
        },
        onPanUpdate: (details) {
          widget.onPanUpdate?.call(details);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onPanEnd?.call();
        },
        child: Container(
          width: widget.isHorizontal ? lineLength : hitArea,
          height: widget.isHorizontal ? hitArea : lineLength,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.isHorizontal ? lineLength : lineThickness,
            height: widget.isHorizontal ? lineThickness : lineLength,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(lineThickness / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}