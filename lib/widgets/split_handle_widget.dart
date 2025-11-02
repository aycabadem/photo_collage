import 'package:flutter/material.dart';

/// A thin draggable handle rendered along the shared edge between two boxes.
/// Provides a larger hit area but a subtle visual line centered in it.
class SplitHandleWidget extends StatelessWidget {
  final bool
      isVertical; // true: vertical divider (left/right), false: horizontal (top/bottom)
  final double thickness; // visual line thickness
  final VoidCallback? onTap;
  final void Function(double delta) onDrag; // delta in screen px along axis
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final bool showIcon; // show a small splitter hint icon
  final double iconSize; // visual icon size inside the badge
  final Color? iconColor;
  final Color? badgeColor; // circular background behind icon

  const SplitHandleWidget({
    super.key,
    required this.isVertical,
    required this.onDrag,
    this.thickness = 2.0,
    this.onTap,
    this.onDragStart,
    this.onDragEnd,
    this.showIcon = true,
    this.iconSize = 22.0,
    this.iconColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Big hit area, subtle line in the middle
    final Color lineColor = Colors.white.withValues(alpha: 0.9);
    final Color shadow = Colors.black.withValues(alpha: 0.18);
    final Color badgeBg = (badgeColor ?? Colors.black).withValues(alpha: 0.32);
    final Color chevronColor =
        iconColor ?? Colors.white.withValues(alpha: 0.95);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => onDragStart?.call(),
      onPanUpdate: (details) =>
          onDrag(isVertical ? details.delta.dx : details.delta.dy),
      onPanEnd: (_) => onDragEnd?.call(),
      onPanCancel: () => onDragEnd?.call(),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: _HandlePainter(
              isVertical: isVertical,
              color: lineColor,
              shadow: shadow,
              thickness: thickness,
            ),
            child: const SizedBox.expand(),
          ),
          if (showIcon)
            Container(
              // Keep badge size fixed so it doesn't jump
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: isVertical
                    // Vertical divider → show a single, bold left-right indicator
                    ? RotatedBox(
                        quarterTurns: 1,
                        child: Icon(
                          Icons.unfold_more, // two chevrons combined, thicker
                          size: iconSize,
                          color: chevronColor,
                        ),
                      )
                    // Horizontal divider → up/down indicator
                    : Icon(
                        Icons.unfold_more,
                        size: iconSize,
                        color: chevronColor,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  final bool isVertical;
  final Color color;
  final Color shadow;
  final double thickness;

  _HandlePainter({
    required this.isVertical,
    required this.color,
    required this.shadow,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint ps = Paint()
      ..color = shadow
      ..strokeWidth = thickness + 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isVertical) {
      final double x = size.width / 2;
      final double top = 0;
      final double bot = size.height;
      // subtle shadow then line
      canvas.drawLine(Offset(x, top), Offset(x, bot), ps);
      canvas.drawLine(Offset(x, top), Offset(x, bot), p);
    } else {
      final double y = size.height / 2;
      final double left = 0;
      final double right = size.width;
      canvas.drawLine(Offset(left, y), Offset(right, y), ps);
      canvas.drawLine(Offset(left, y), Offset(right, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
