/// Model class representing aspect ratio specifications
class AspectSpec {
  /// Width component of the aspect ratio
  final double w;

  /// Height component of the aspect ratio
  final double h;

  /// Display label for the aspect ratio
  final String label;

  const AspectSpec({required this.w, required this.h, required this.label});

  /// Get the aspect ratio as a double value
  double get ratio => w / h;

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AspectSpec) return false;
    const double eps = 1e-6;
    return (w - other.w).abs() < eps && (h - other.h).abs() < eps;
  }

  @override
  int get hashCode {
    // Quantize to avoid floating drift in hash
    final int qw = (w * 1000000).round();
    final int qh = (h * 1000000).round();
    return qw ^ (qh << 16);
  }
}
