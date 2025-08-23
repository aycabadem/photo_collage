import 'package:flutter/material.dart';

/// Represents a preset collage layout template
class LayoutTemplate {
  final String id;
  final String name;
  final String description;
  final int photoCount;
  final List<PhotoLayout> photoLayouts;
  final String thumbnailPath; // For future use with actual images

  const LayoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.photoCount,
    required this.photoLayouts,
    this.thumbnailPath = '',
  });

  /// Get scaled layouts for a specific aspect ratio
  List<PhotoLayout> getScaledLayouts(double aspectRatio) {
    // Layout'lar zaten 0.0-1.0 arası relative koordinatlarda
    // Template boyutuna göre scale etmeye gerek yok
    // Sadece pozisyonları ve boyutları template'e uyarla
    return photoLayouts.map((layout) {
      return PhotoLayout(
        position: layout.position, // 0.0-1.0 arası kalacak
        size: layout.size, // 0.0-1.0 arası kalacak
      );
    }).toList();
  }
}

/// Represents the position and size of a photo in a layout
class PhotoLayout {
  final Offset position;
  final Size size;

  const PhotoLayout({required this.position, required this.size});
}

/// Predefined layout templates - Classic photo collage layouts
class LayoutTemplates {
  static const List<LayoutTemplate> templates = [
    // 2 Photo Layouts - Classic Instagram/Canva style
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
      description: 'Two photos stacked vertically',
      photoCount: 2,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(1.0, 0.5)),
      ],
    ),

    // 3 Photo Layouts - Popular designs
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

    // 4 Photo Layouts - Standard grids
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
      id: '4_large_three',
      name: '1 Large + 3 Small',
      description: 'One large with three small',
      photoCount: 4,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.67, 0.67)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.67, 0.33), size: Size(0.33, 0.34)),
        PhotoLayout(position: Offset(0.0, 0.67), size: Size(0.67, 0.33)),
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

    // 5 Photo Layouts - Creative but practical
    LayoutTemplate(
      id: '5_instagram',
      name: 'Instagram Style',
      description: 'Popular Instagram layout',
      photoCount: 5,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.6, 0.6)),
        PhotoLayout(position: Offset(0.6, 0.0), size: Size(0.4, 0.3)),
        PhotoLayout(position: Offset(0.6, 0.3), size: Size(0.4, 0.3)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.3, 0.4)),
        PhotoLayout(position: Offset(0.3, 0.6), size: Size(0.3, 0.4)),
      ],
    ),
    LayoutTemplate(
      id: '5_cross',
      name: 'Cross Layout',
      description: 'One center with four corners',
      photoCount: 5,
      photoLayouts: [
        PhotoLayout(position: Offset(0.33, 0.33), size: Size(0.34, 0.34)),
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.0, 0.67), size: Size(0.33, 0.33)),
        PhotoLayout(position: Offset(0.67, 0.67), size: Size(0.33, 0.33)),
      ],
    ),

    // 6 Photo Layouts - Standard grids
    LayoutTemplate(
      id: '6_grid_3x2',
      name: '3x2 Grid',
      description: 'Six equal rectangles',
      photoCount: 6,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.33, 0.5)),
        PhotoLayout(position: Offset(0.33, 0.0), size: Size(0.34, 0.5)),
        PhotoLayout(position: Offset(0.67, 0.0), size: Size(0.33, 0.5)),
        PhotoLayout(position: Offset(0.0, 0.5), size: Size(0.33, 0.5)),
        PhotoLayout(position: Offset(0.33, 0.5), size: Size(0.34, 0.5)),
        PhotoLayout(position: Offset(0.67, 0.5), size: Size(0.33, 0.5)),
      ],
    ),
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

    // Additional practical layouts
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
      id: '3_t_shape',
      name: 'T-Shape',
      description: 'One wide top, two bottom',
      photoCount: 3,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(1.0, 0.6)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.5, 0.4)),
        PhotoLayout(position: Offset(0.5, 0.6), size: Size(0.5, 0.4)),
      ],
    ),
    LayoutTemplate(
      id: '4_l_shape',
      name: 'L-Shape',
      description: 'L-shaped layout',
      photoCount: 4,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.6, 0.6)),
        PhotoLayout(position: Offset(0.6, 0.0), size: Size(0.4, 0.6)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.3, 0.4)),
        PhotoLayout(position: Offset(0.3, 0.6), size: Size(0.3, 0.4)),
      ],
    ),
    LayoutTemplate(
      id: '5_magazine',
      name: 'Magazine Style',
      description: 'Magazine-like layout',
      photoCount: 5,
      photoLayouts: [
        PhotoLayout(position: Offset(0.0, 0.0), size: Size(0.5, 0.6)),
        PhotoLayout(position: Offset(0.5, 0.0), size: Size(0.5, 0.3)),
        PhotoLayout(position: Offset(0.5, 0.3), size: Size(0.5, 0.3)),
        PhotoLayout(position: Offset(0.0, 0.6), size: Size(0.25, 0.4)),
        PhotoLayout(position: Offset(0.25, 0.6), size: Size(0.25, 0.4)),
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
