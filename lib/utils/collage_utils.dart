import 'package:flutter/material.dart';
import '../models/photo_box.dart';

/// Utility class for collage-related calculations and operations
class CollageUtils {
  /// Safely clamp a value between min and max, preventing invalid arguments
  static double safeClamp(double value, double min, double max) {
    if (min > max) {
      // For extreme aspect ratios, use more intelligent fallback
      if (value < min) return min;
      if (value > max) return max;
      return (min + max) / 2; // Return middle value
    }
    return value.clamp(min, max);
  }

  /// Find a non-overlapping position for a new photo box
  static Offset findNonOverlappingPosition(
    List<PhotoBox> existing,
    Size templateSize,
    Size newSize,
  ) {
    // Check if box is larger than template
    if (newSize.width > templateSize.width ||
        newSize.height > templateSize.height) {
      // If box is larger than template, place it in the center
      return Offset(
        (templateSize.width - newSize.width) / 2,
        (templateSize.height - newSize.height) / 2,
      );
    }

    // If no boxes exist, place in top-left corner
    if (existing.isEmpty) {
      return const Offset(20, 20);
    }

    double margin = 20; // Edge margin
    double spacing = 30; // Spacing between boxes

    // Grid-based search with smaller steps
    for (
      double y = margin;
      y <= templateSize.height - newSize.height - margin;
      y += spacing
    ) {
      for (
        double x = margin;
        x <= templateSize.width - newSize.width - margin;
        x += spacing
      ) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (box) => newRect.overlaps(
            Rect.fromLTWH(
              box.position.dx,
              box.position.dy,
              box.size.width,
              box.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }
    }

    // If no place found in grid, try placing next to existing boxes
    for (final box in existing) {
      // Place to the right
      double x = box.position.dx + box.size.width + spacing;
      double y = box.position.dy;

      if (x + newSize.width <= templateSize.width - margin) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (otherBox) => newRect.overlaps(
            Rect.fromLTWH(
              otherBox.position.dx,
              otherBox.position.dy,
              otherBox.size.width,
              otherBox.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }

      // Place below
      x = box.position.dx;
      y = box.position.dy + box.size.height + spacing;

      if (y + newSize.height <= templateSize.height - margin) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (otherBox) => newRect.overlaps(
            Rect.fromLTWH(
              otherBox.position.dx,
              otherBox.position.dy,
              otherBox.size.width,
              otherBox.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }
    }

    // Last resort: place in template center
    return Offset(
      (templateSize.width - newSize.width) / 2,
      (templateSize.height - newSize.height) / 2,
    );
  }
}
