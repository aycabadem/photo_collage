import 'package:flutter/material.dart';
import '../models/alignment_guideline.dart';

/// Simple overlay for drawing alignment guidelines
class GuidelinesOverlay extends StatelessWidget {
  final List<AlignmentGuideline> guidelines;
  final Size templateSize;

  const GuidelinesOverlay({
    super.key,
    required this.guidelines,
    required this.templateSize,
  });

  @override
  Widget build(BuildContext context) {
    if (guidelines.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: templateSize,
        painter: GuidelinesPainter(guidelines: guidelines),
      ),
    );
  }
}

/// Custom painter for drawing guidelines
class GuidelinesPainter extends CustomPainter {
  final List<AlignmentGuideline> guidelines;

  GuidelinesPainter({required this.guidelines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final guideline in guidelines) {
      // Different colors for different types
      Color lineColor;
      double strokeWidth;

      switch (guideline.type) {
        case 'edge':
          lineColor = Colors.blue;
          strokeWidth = 2.0;
          break;
        case 'center':
          lineColor = Colors.green;
          strokeWidth = 2.0;
          break;
        case 'size':
          lineColor = Colors.orange;
          strokeWidth = 2.0;
          break;
        case 'background-center':
          lineColor = Colors.purple;
          strokeWidth = 1.5;
          break;
        default:
          lineColor = Colors.blue;
          strokeWidth = 2.0;
      }

      final paint = Paint()
        ..color = lineColor.withValues(alpha: 0.8)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      if (guideline.isHorizontal) {
        // Horizontal line (top/bottom alignment)
        canvas.drawLine(
          Offset(0, guideline.position),
          Offset(size.width, guideline.position),
          paint,
        );
      } else {
        // Vertical line (left/right alignment)
        canvas.drawLine(
          Offset(guideline.position, 0),
          Offset(guideline.position, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
