import 'package:flutter/material.dart';

/// Corner dot handle for resizing photo boxes (Adobe/Figma style)
class CornerHandleWidget extends StatefulWidget {
  final VoidCallback? onTapDown;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onPanEnd;

  const CornerHandleWidget({
    super.key,
    this.onTapDown,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  State<CornerHandleWidget> createState() => _CornerHandleWidgetState();
}

class _CornerHandleWidgetState extends State<CornerHandleWidget> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final double size = _isHovered || _isDragging ? 8.0 : 6.0;
    final double hitArea = 16.0;
    final scheme = Theme.of(context).colorScheme;

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
          width: hitArea,
          height: hitArea,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: scheme.primary,
              border: Border.all(color: Colors.black.withValues(alpha: 0.85), width: 1.5),
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
