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

  PhotoBox({
    required this.position,
    required this.size,
    this.imageFile,
    this.imagePath,
    this.imageFit = BoxFit.cover,
  });
}
