/// Model class representing aspect ratio specifications
class AspectSpec {
  /// Width component of the aspect ratio
  final int w;

  /// Height component of the aspect ratio
  final int h;

  /// Display label for the aspect ratio
  final String label;

  const AspectSpec({required this.w, required this.h, required this.label});

  /// Get the aspect ratio as a double value
  double get ratio => w / h;

  @override
  String toString() => label;
}
