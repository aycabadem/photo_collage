part of '../collage_manager.dart';

mixin _CollageBackgroundControls on _CollageManagerBase {
  void setPhotoMargin(double margin) {
    final double clamped = margin.clamp(0.0, 15.0);
    if (_photoMargin == clamped) return;
    _photoMargin = clamped;
    notifyListeners();
  }

  void setSelectedExportWidth(int width) {
    final int clamped = width.clamp(800, 8000);
    if (_selectedExportWidth != clamped) {
      _selectedExportWidth = clamped;
      notifyListeners();
    }
  }

  void changeBackgroundColor(Color color) {
    if (_backgroundColor.toARGB32() == color.toARGB32()) return;
    _backgroundColor = color;
    notifyListeners();
  }

  void changeBackgroundOpacity(double opacity) {
    final double clamped = opacity.clamp(0.0, 1.0);
    if ((_backgroundOpacity - clamped).abs() < 1e-6) return;
    _backgroundOpacity = clamped;
    notifyListeners();
  }

  void setBackgroundMode(BackgroundMode mode) {
    if (_backgroundMode == mode) return;
    _backgroundMode = mode;
    notifyListeners();
  }

  void setBackgroundGradient(GradientSpec spec) {
    _backgroundGradient = _cloneGradientSpec(spec);
    _backgroundMode = BackgroundMode.gradient;
    notifyListeners();
  }

  List<Color> get gradientColorsWithOpacity {
    return _backgroundGradient.stops
        .map((s) => s.color.withValues(alpha: s.color.a * _backgroundOpacity))
        .toList();
  }

  List<double> get gradientStops =>
      _backgroundGradient.stops.map((s) => s.offset).toList();

  void changeGlobalBorderWidth(double width) {
    final double clamped = width.clamp(0.0, 50.0);
    if ((_globalBorderWidth - clamped).abs() < 1e-6) return;
    _globalBorderWidth = clamped;
    _hasGlobalBorder = _globalBorderWidth > 0.0;
    notifyListeners();
  }

  void changeGlobalBorderColor(Color color) {
    if (_globalBorderColor.toARGB32() == color.toARGB32()) return;
    _globalBorderColor = color;
    notifyListeners();
  }

  void setShadowIntensity(double intensity) {
    final double clamped = intensity.clamp(0.0, 14.0);
    if ((_shadowIntensity - clamped).abs() < 1e-6) return;
    _shadowIntensity = clamped;
    notifyListeners();
  }

  void setInnerMargin(double margin) {
    final double clamped = margin.clamp(0.0, 40.0);
    if ((_innerMargin - clamped).abs() < 1e-6) return;
    _innerMargin = clamped;
    notifyListeners();
  }

  void setOuterMargin(double margin) {
    final double clamped = margin.clamp(0.0, 60.0);
    if ((_outerMargin - clamped).abs() < 1e-6) return;
    _outerMargin = clamped;
    notifyListeners();
  }

  void setCornerRadius(double radius) {
    final double clamped = radius.clamp(0.0, 160.0);
    if ((_cornerRadius - clamped).abs() < 1e-6) return;
    _cornerRadius = clamped;
    notifyListeners();
  }
}
