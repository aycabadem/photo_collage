import 'package:flutter/material.dart';

enum BackgroundMode { solid, gradient }

class GradientStop {
  double offset; // 0..1
  Color color;
  GradientStop({required this.offset, required this.color});
}

class GradientSpec {
  final List<GradientStop> stops;
  final double angleDeg; // 0..360

  const GradientSpec({required this.stops, required this.angleDeg});

  GradientSpec copyWith({List<GradientStop>? stops, double? angleDeg}) =>
      GradientSpec(stops: stops ?? this.stops, angleDeg: angleDeg ?? this.angleDeg);

  static GradientSpec presetPinkPurple() => GradientSpec(stops: [
        GradientStop(offset: 0.0, color: const Color(0xFFE91E63)),
        GradientStop(offset: 1.0, color: const Color(0xFF7C4DFF)),
      ], angleDeg: 45);

  static GradientSpec presetTealBlue() => GradientSpec(stops: [
        GradientStop(offset: 0.0, color: const Color(0xFF26A69A)),
        GradientStop(offset: 1.0, color: const Color(0xFF1E88E5)),
      ], angleDeg: 30);

  static GradientSpec presetSunset() => GradientSpec(stops: [
        GradientStop(offset: 0.0, color: const Color(0xFFFF7043)),
        GradientStop(offset: 1.0, color: const Color(0xFFFFC107)),
      ], angleDeg: 20);

  static GradientSpec presetLime() => GradientSpec(stops: [
        GradientStop(offset: 0.0, color: const Color(0xFF8BC34A)),
        GradientStop(offset: 1.0, color: const Color(0xFFFFEB3B)),
      ], angleDeg: 0);
}

