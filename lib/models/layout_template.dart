import 'package:flutter/material.dart';

/// Represents a preset collage layout template
class LayoutTemplate {
  final String id;
  final String name;
  final String description;
  final int photoCount;
  final List<PhotoLayout> photoLayouts;

  const LayoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.photoCount,
    required this.photoLayouts,
  });

  /// Get scaled layouts for a specific aspect ratio
  List<PhotoLayout> getScaledLayouts(double aspectRatio) {
    // Layout'lar zaten 0.0-1.0 aralığında tanımlı, direkt kullan
    // Aspect ratio fark etmez, CollageManager template size'ı ayarlıyor
    return photoLayouts.map((layout) {
      return PhotoLayout(position: layout.position, size: layout.size);
    }).toList();
  }
}

/// Represents the position and size of a photo in a layout
class PhotoLayout {
  final Offset position;
  final Size size;

  const PhotoLayout({required this.position, required this.size});
}

/// Perfect layout templates - Every aspect ratio compatible, no gaps, no overlaps
class LayoutTemplates {
  static const List<LayoutTemplate> templates = [
    // 2 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '2_horizontal',
      name: 'Split Horizontal',
      description: 'Two photos side by side',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 1.0)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '2_vertical',
      name: 'Split Vertical',
      description: 'Two photos stacked',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(1.0, 0.5)),
      ],
    ),
    LayoutTemplate(
      id: '2_large_small',
      name: 'Large + Small',
      description: 'One large, one small photo',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.7, 1.0)),
        PhotoLayout(position: Offset(0.7, 0.0), size: Size(0.3, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '2_tall_wide',
      name: 'Tall + Wide',
      description: 'Tall left, wide right',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.4, 1.0)),
        PhotoLayout(position: Offset(0.4, 0.0), size: Size(0.6, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '2_wide_tall',
      name: 'Wide + Tall',
      description: 'Wide left, tall right',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.6, 1.0)),
        PhotoLayout(position: Offset(0.6, 0.0), size: Size(0.4, 1.0)),
      ],
    ),

    // 3 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '3_horizontal',
      name: '3 Equal Columns',
      description: 'Three equal vertical columns',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.33, 1.0)),
        PhotoLayout(position: Offset(0.33, 0.0), size: Size(0.34, 1.0)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '3_vertical',
      name: '3 Equal Rows',
      description: 'Three equal horizontal rows',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.33), size: Size(1.0, 0.34)),
        PhotoLayout(position: Offset(0.0, 0.67), size: Size(1.0, 0.33)),
      ],
    ),
    LayoutTemplate(
      id: '3_large_small',
      name: '1 Large + 2 Small',
      description: 'One large photo with two small',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.67, 1.0)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 0.5)),
        PhotoLayout(position: Offset(0.67, 0.5), size: Size(0.33, 0.5)),
      ],
    ),
    LayoutTemplate(
      id: '3_stripe_horizontal',
      name: 'Horizontal Stripes',
      description: 'Three horizontal strips',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.33), size: Size(1.0, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.66), size: Size(1.0, 0.34)),
      ],
    ),
    LayoutTemplate(
      id: '3_stripe_vertical',
      name: 'Vertical Stripes',
      description: 'Three vertical strips',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.33, 1.0)),
        PhotoLayout(position: Offset(0.33, 0.0), size: Size(0.33, 1.0)),
        PhotoLayout(position: Offset(0.66, 0.0), size: Size(0.34, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '3_l_left',
      name: 'L-Left',
      description: 'L-shape on left',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 1.0)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.5, 0.5), size: Size(0.5, 0.5)),
      ],
    ),
    LayoutTemplate(
      id: '3_l_right',
      name: 'L-Right',
      description: 'L-shape on right',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 1.0)),
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(0.5, 0.5)),
      ],
    ),

    // 4 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '4_grid',
      name: '2x2 Grid',
      description: 'Four equal squares',
      photoCount: 4,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.5, 0.5), size: Size(0.5, 0.5)),
      ],
    ),
    LayoutTemplate(
      id: '4_vertical',
      name: '4 Vertical Strips',
      description: 'Four vertical strips',
      photoCount: 4,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.25, 1.0)),
        PhotoLayout(position: Offset(0.25, 0.0), size: Size(0.25, 1.0)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.25, 1.0)),
        PhotoLayout(position: Offset(0.75, 0.0), size: Size(0.25, 1.0)),
      ],
    ),
    LayoutTemplate(
      id: '4_horizontal',
      name: '4 Horizontal Strips',
      description: 'Four horizontal strips',
      photoCount: 4,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.25), size: Size(1.0, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(1.0, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.75), size: Size(1.0, 0.25)),
      ],
    ),
    LayoutTemplate(
      id: '4_wide_top',
      name: 'Wide Top',
      description: 'Wide top, two bottom',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.6)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.5, 0.4)),
        PhotoLayout(position: Offset(0.5, 0.6), size: Size(0.5, 0.4)),
      ],
    ),
    LayoutTemplate(
      id: '4_wide_bottom',
      name: 'Wide Bottom',
      description: 'Two top, wide bottom',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.4)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.4)),
        PhotoLayout(position: Offset(0.0, 0.4), size: Size(1.0, 0.6)),
      ],
    ),

    // 5 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '5_plus',
      name: 'Plus Sign',
      description: 'Plus pattern layout',
      photoCount: 6,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.4, 0.4)),
        PhotoLayout(position: Offset(0.4, 0.0), size: Size(0.6, 0.4)),
        PhotoLayout(position: Offset(0.0, 0.4), size: Size(0.4, 0.6)),
        PhotoLayout(position: Offset(0.4, 0.4), size: Size(0.3, 0.3)),
        PhotoLayout(position: Offset(0.7, 0.4), size: Size(0.3, 0.3)),
        PhotoLayout(position: Offset(0.4, 0.7), size: Size(0.6, 0.3)),
      ],
    ),
    LayoutTemplate(
      id: '5_frame',
      name: 'Frame',
      description: 'Frame with center photo',
      photoCount: 5,
      photoLayouts: [
        PhotoLayout(position: Offset(0.25, 0.25), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.75), size: Size(1.0, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.25), size: Size(0.25, 0.5)),
        PhotoLayout(position: Offset(0.75, 0.25), size: Size(0.25, 0.5)),
      ],
    ),

    LayoutTemplate(
      id: '5_magazine',
      name: 'Magazine Style',
      description: 'Magazine-like layout',
      photoCount: 6,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.6)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.3)),
        PhotoLayout(position: Offset(0.5, 0.3), size: Size(0.5, 0.3)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.25, 0.4)),
        PhotoLayout(position: Offset(0.25, 0.6), size: Size(0.25, 0.4)),
        PhotoLayout(position: Offset(0.5, 0.6), size: Size(0.5, 0.4)),
      ],
    ),

    // 6 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '6_grid_2x3',
      name: '2x3 Grid',
      description: 'Six equal rectangles vertical',
      photoCount: 6,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.33)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.33), size: Size(0.5, 0.34)),
        PhotoLayout(position: Offset(0.5, 0.33), size: Size(0.5, 0.34)),
        PhotoLayout(position: Offset(0.0, 0.67), size: Size(0.5, 0.33)),
        PhotoLayout(position: Offset(0.5, 0.67), size: Size(0.5, 0.33)),
      ],
    ),

    // 7 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '7_grid_irregular',
      name: 'Irregular Grid',
      description: 'Mixed grid layout',
      photoCount: 6,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(0.25, 0.5)),
        PhotoLayout(position: Offset(0.25, 0.5), size: Size(0.25, 0.5)),
        PhotoLayout(position: Offset(0.5, 0.5), size: Size(0.25, 0.5)),
        PhotoLayout(position: Offset(0.75, 0.5), size: Size(0.25, 0.5)),
      ],
    ),

    // 8 PHOTO LAYOUTS - Perfect fit
    LayoutTemplate(
      id: '8_grid_24',
      name: '2x4 Grid',
      description: 'Simple 2x4 grid',
      photoCount: 8,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.25), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.5, 0.25), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.5, 0.5), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.0, 0.75), size: Size(0.5, 0.25)),
        PhotoLayout(position: Offset(0.5, 0.75), size: Size(0.5, 0.25)),
      ],
    ),

    // 9 PHOTO LAYOUT - Perfect fit
    LayoutTemplate(
      id: '9_grid',
      name: '3x3 Grid',
      description: 'Perfect 3x3 grid',
      photoCount: 9,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.33, 0.0), size: Size(0.34, 0.33)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.33), size: Size(0.33, 0.34)),
        PhotoLayout(position: Offset(0.33, 0.33), size: Size(0.34, 0.34)),
        PhotoLayout(position: Offset(0.67, 0.33), size: Size(0.33, 0.34)),
        PhotoLayout(position: Offset(0.0, 0.67), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.33, 0.67), size: Size(0.34, 0.33)),
        PhotoLayout(position: Offset(0.67, 0.67), size: Size(0.33, 0.33)),
      ],
    ),
  ];

  /// Get layout by ID
  static LayoutTemplate? getById(String id) {
    try {
      return templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get layouts by photo count
  static List<LayoutTemplate> getByPhotoCount(int count) {
    return templates.where((template) => template.photoCount == count).toList();
  }
}
