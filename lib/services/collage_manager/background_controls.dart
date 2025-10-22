part of '../collage_manager.dart';

mixin _CollageBackgroundControls on _CollageManagerBase {
  void setPhotoMargin(double margin) {
    _photoMargin = margin.clamp(0.0, 15.0);
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
    _backgroundColor = color;
    notifyListeners();
  }

  void changeBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBackgroundMode(BackgroundMode mode) {
    _backgroundMode = mode;
    notifyListeners();
  }

  void setBackgroundGradient(GradientSpec spec) {
    _backgroundGradient = spec;
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
    _globalBorderWidth = width.clamp(0.0, 50.0);
    _hasGlobalBorder = _globalBorderWidth > 0.0;
    notifyListeners();
  }

  void changeGlobalBorderColor(Color color) {
    _globalBorderColor = color;
    notifyListeners();
  }

  void setShadowIntensity(double intensity) {
    _shadowIntensity = intensity.clamp(0.0, 14.0);
    notifyListeners();
  }

  void setInnerMargin(double margin) {
    _innerMargin = margin.clamp(0.0, 60.0);
    notifyListeners();
  }

  void setOuterMargin(double margin) {
    _outerMargin = margin.clamp(0.0, 120.0);
    notifyListeners();
  }

  void setCornerRadius(double radius) {
    _cornerRadius = radius.clamp(0.0, 160.0);
    notifyListeners();
  }
}
