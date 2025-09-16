import 'dart:io';
import 'package:flutter/material.dart';

/// Model class representing a photo box in the collage
class PhotoBox {
  /// Position of the photo box on the template
  Offset position;

  /// Size of the photo box
  Size size;

  /// The actual image file
  File? imageFile;

  /// Path to the image file
  String? imagePath;

  /// How the image should fit in the box
  BoxFit imageFit;

  /// Photo offset for panning (relative to box center)
  Offset photoOffset;

  /// Photo scale for zooming (1.0 = normal size)
  double photoScale;

  /// Crop rectangle (relative to photo, 0-1 range)
  Rect cropRect;

  /// How the photo is aligned within the box
  Alignment alignment;

  /// Rotation (radians, CCW) for full‑box rotation in custom mode
  double rotationRadians;
  /// Rotation baseline captured at gesture start (not persisted)
  double rotationBaseRadians;

  PhotoBox({
    required this.position,
    required this.size,
    this.imageFile,
    this.imagePath,
    this.imageFit = BoxFit.cover,
    this.photoOffset = const Offset(0, 0),
    this.photoScale = 1.0,
    this.cropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.alignment = Alignment.center,
    this.rotationRadians = 0.0,
    this.rotationBaseRadians = 0.0,
  });
}
