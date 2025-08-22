import 'package:flutter/material.dart';

class ColorPickerButton extends StatelessWidget {
  final Color currentColor;
  final VoidCallback onPressed;
  final double size;

  const ColorPickerButton({
    super.key,
    required this.currentColor,
    required this.onPressed,
    this.size = 48.0, // Daha küçük ve şık
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(painter: ColorPickerButtonPainter(currentColor)),
      ),
    );
  }
}

class ColorPickerButtonPainter extends CustomPainter {
  final Color currentColor;

  ColorPickerButtonPainter(this.currentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;

    // Outer rainbow ring
    final rainbowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4
      ..shader = SweepGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.red,
        ],
        stops: const [0.0, 0.14, 0.28, 0.42, 0.57, 0.71, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rainbowPaint);

    // Inner circle with current color
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = currentColor;

    canvas.drawCircle(center, innerRadius, innerPaint);

    // Inner circle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          1.5 // Daha ince border
      ..color = Colors.white.withValues(alpha: 0.9); // Hafif şeffaf

    canvas.drawCircle(center, innerRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
