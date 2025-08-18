import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import '../models/photo_box.dart';
import '../models/aspect_spec.dart';
import '../widgets/photo_box_widget.dart';
import '../widgets/resize_handle_widget.dart';
import '../utils/collage_utils.dart';

/// Main screen for the photo collage application
class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  // Aspect ratio presets
  static const List<AspectSpec> presets = [
    AspectSpec(w: 1, h: 1, label: '1:1'),
    AspectSpec(w: 3, h: 4, label: '3:4'),
    AspectSpec(w: 4, h: 3, label: '4:3'),
    AspectSpec(w: 4, h: 5, label: '4:5'),
    AspectSpec(w: 5, h: 4, label: '5:4'),
    AspectSpec(w: 9, h: 16, label: '9:16'),
    AspectSpec(w: 16, h: 9, label: '16:9'),
  ];

  // Template size configuration
  static const double baseWidth = 350;
  static const double minHeight = 220;

  // State variables
  late AspectSpec selectedAspect = presets.firstWhere((a) => a.label == '9:16');
  late Size templateSize = _sizeForAspect(selectedAspect);

  List<PhotoBox> photoBoxes = [];
  PhotoBox? selectedBox;

  final TransformationController _transformationController =
      TransformationController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Collage'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Aspect ratio dropdown
          DropdownButton<AspectSpec>(
            value: selectedAspect,
            items: [
              // Preset ratios
              ...presets.map(
                (v) => DropdownMenuItem<AspectSpec>(
                  value: v,
                  child: Text(v.label),
                ),
              ),
              // Custom ratio (only if not in presets and different from current)
              if (!presets.any(
                (p) => p.w == selectedAspect.w && p.h == selectedAspect.h,
              ))
                DropdownMenuItem<AspectSpec>(
                  value: selectedAspect,
                  child: Text('${selectedAspect.label} (Custom)'),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                final screenSize = MediaQuery.of(context).size;
                _applyAspect(v, screenSize: screenSize);
              }
            },
          ),
          IconButton(
            tooltip: 'Custom ratio',
            onPressed: _openCustomAspectDialog,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Deselect when tapping anywhere
          setState(() {
            selectedBox = null;
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Initialize template size based on screen size on first frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final screenSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final newSize = _sizeForAspect(
                selectedAspect,
                screenSize: screenSize,
              );
              if (templateSize != newSize) {
                setState(() {
                  templateSize = newSize;
                });
              }
            });

            return InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.3,
              maxScale: 3.0,
              panEnabled: false, // Pan completely disabled - background fixed
              scaleEnabled: true, // Only zoom active
              boundaryMargin: EdgeInsets.zero,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Center(
                  child: Container(
                    width: templateSize.width,
                    height: templateSize.height,
                    color: Colors.grey[200],
                    child: Stack(
                      clipBehavior: Clip.hardEdge, // Prevent overflow
                      children: [
                        for (var box in photoBoxes) _buildPhotoBox(box),
                        if (selectedBox != null) _buildOverlay(selectedBox!),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pick photo from gallery
          final XFile? pickedFile = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );

          if (pickedFile != null) {
            // Create new photo box
            Size boxSize = const Size(150, 150);
            Offset pos = CollageUtils.findNonOverlappingPosition(
              photoBoxes,
              templateSize,
              boxSize,
            );

            setState(() {
              var newBox = PhotoBox(
                position: pos,
                size: boxSize,
                imageFile: File(pickedFile.path),
                imagePath: pickedFile.path,
              );
              photoBoxes.add(newBox);
              selectedBox = newBox;
            });
          }
        },
        child: const Icon(Icons.photo_library),
      ),
    );
  }

  /// Calculate template size based on aspect ratio and screen size
  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    // Default sizes
    double maxWidth = baseWidth;
    double maxHeight = baseWidth;

    if (screenSize != null) {
      // Leave space for FloatingActionButton and other UI elements
      double availableWidth = screenSize.width - 100; // Padding and FAB
      double availableHeight =
          screenSize.height - 150; // AppBar, padding and FAB

      // Stricter limits to prevent overflow
      maxWidth = availableWidth.clamp(300, 450.0);
      maxHeight = availableHeight.clamp(250, 500.0);
    }

    // Size strategy based on aspect ratio type
    double aspectRatio = a.ratio;
    double width, height;

    if (aspectRatio > 2) {
      // Very wide ratios (10:1, 16:1 etc.)
      // For very wide ratios, prioritize width and adjust height accordingly
      width = maxWidth * 0.95; // Use most of available width
      height = width / aspectRatio;

      // Ensure height is reasonable
      if (height < 100) {
        height = 100; // Minimum height for visibility
        width = height * aspectRatio;
        // If width becomes too large, cap it
        if (width > maxWidth * 0.95) {
          width = maxWidth * 0.95;
          height = width / aspectRatio;
        }
      }
    } else if (aspectRatio < 0.5) {
      // Very tall ratios (9:16, 1:6 etc.)
      width = maxWidth * 0.7;
      height = width / aspectRatio;
      if (height > maxHeight * 0.95) {
        height = maxHeight * 0.95;
        width = height * aspectRatio;
      }
    } else if (aspectRatio >= 0.8 && aspectRatio <= 1.25) {
      // Medium ratios (4:5, 5:4, 1:1, 3:4, 4:3) - optimal screen usage
      if (aspectRatio >= 1) {
        // Horizontal or square (5:4, 1:1, 4:3)
        width = maxWidth * 0.85;
        height = width / aspectRatio;
        if (height > maxHeight * 0.75) {
          height = maxHeight * 0.75;
          width = height * aspectRatio;
        }
      } else {
        // Vertical (4:5, 3:4)
        height = maxHeight * 0.75;
        width = height * aspectRatio;
        if (width > maxWidth * 0.85) {
          width = maxWidth * 0.85;
          height = width / aspectRatio;
        }
      }
    } else {
      // Other ratios - standard handling
      if (aspectRatio >= 1) {
        // Horizontal
        width = maxWidth * 0.9;
        height = width / aspectRatio;
        if (height > maxHeight * 0.8) {
          height = maxHeight * 0.8;
          width = height * aspectRatio;
        }
      } else {
        // Vertical
        height = maxHeight * 0.8;
        width = height * aspectRatio;
        if (width > maxWidth * 0.9) {
          width = maxWidth * 0.9;
          height = width / aspectRatio;
        }
      }
    }

    // Minimum size control
    if (width < 200) width = 200;
    if (height < 150) height = 150;

    // Maximum size control - prevent overflow
    if (width > maxWidth * 0.95) width = maxWidth * 0.95;
    if (height > maxHeight * 0.95) height = maxHeight * 0.95;

    return Size(width, height);
  }

  /// Apply new aspect ratio and resize existing boxes
  void _applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    // Validate the new aspect ratio
    if (newAspect.w <= 0 || newAspect.h <= 0) {
      return; // Invalid aspect ratio, don't apply
    }

    final oldSize = templateSize;
    final newSize = _sizeForAspect(newAspect, screenSize: screenSize);

    setState(() {
      selectedAspect = newAspect;
      templateSize = newSize;

      // Resize and reposition boxes to fit new template size
      for (final box in photoBoxes) {
        // Fit box to new template size
        double newWidth = box.size.width;
        double newHeight = box.size.height;

        // Shrink box if it's larger than template
        if (newWidth > newSize.width - 40) {
          newWidth = newSize.width - 40;
        }
        if (newHeight > newSize.height - 40) {
          newHeight = newSize.height - 40;
        }

        // Minimum size control
        if (newWidth < 50) newWidth = 50;
        if (newHeight < 50) newHeight = 50;

        // Update size
        box.size = Size(newWidth, newHeight);

        // Adjust position to new template size
        double newX = box.position.dx;
        double newY = box.position.dy;

        // Move boxes inside if they're outside
        if (newX < 0) newX = 0;
        if (newY < 0) newY = 0;
        if (newX + newWidth > newSize.width) {
          newX = newSize.width - newWidth;
        }
        if (newY + newHeight > newSize.height) {
          newY = newSize.height - newHeight;
        }

        // Update position
        box.position = Offset(newX, newY);
      }
    });
  }

  /// Open custom aspect ratio dialog
  Future<void> _openCustomAspectDialog() async {
    final wCtrl = TextEditingController(text: selectedAspect.w.toString());
    final hCtrl = TextEditingController(text: selectedAspect.h.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Custom Ratio (Width:Height)'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: wCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Width'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: hCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final w = int.tryParse(wCtrl.text);
      final h = int.tryParse(hCtrl.text);
      if (w != null && h != null && w > 0 && h > 0) {
        // Check if this ratio already exists in presets
        final existingRatio = presets.any((p) => p.w == w && p.h == h);
        if (existingRatio) {
          // If ratio exists in presets, use the existing one
          final existingAspect = presets.firstWhere(
            (p) => p.w == w && p.h == h,
          );
          final screenSize = MediaQuery.of(context).size;
          _applyAspect(existingAspect, screenSize: screenSize);
        } else {
          // Create new custom ratio
          final customAspect = AspectSpec(w: w, h: h, label: '$w:$h');
          final screenSize = MediaQuery.of(context).size;
          _applyAspect(customAspect, screenSize: screenSize);
        }
      }
    }
  }

  /// Build photo box widget
  Widget _buildPhotoBox(PhotoBox box) {
    // Simple check: is box inside template?
    if (box.position.dx < 0 ||
        box.position.dy < 0 ||
        box.position.dx + box.size.width > templateSize.width ||
        box.position.dy + box.size.height > templateSize.height) {
      return const SizedBox.shrink(); // Hide boxes outside template
    }

    // Show boxes inside template
    return PhotoBoxWidget(
      box: box,
      isSelected: selectedBox == box,
      onTap: () {
        setState(() {
          selectedBox = box;
        });
      },
      onPanUpdate: (details) {
        if (selectedBox != box) return;
        final scale = _getCurrentScale();
        setState(() {
          double newX = CollageUtils.safeClamp(
            box.position.dx + details.delta.dx / scale,
            0.0,
            templateSize.width - box.size.width,
          );
          double newY = CollageUtils.safeClamp(
            box.position.dy + details.delta.dy / scale,
            0.0,
            templateSize.height - box.size.height,
          );
          box.position = Offset(newX, newY);
        });
      },
      onDelete: () {
        setState(() {
          photoBoxes.remove(box);
          selectedBox = null;
        });
      },
    );
  }

  /// Build overlay with resize handles for selected box
  Widget _buildOverlay(PhotoBox box) {
    double handleSize = 16.0;
    return Stack(
      children: [
        // Top-left resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.topLeft,
          size: handleSize,
          onDrag: (dx, dy) {
            final scale = _getCurrentScale();
            dx /= scale;
            dy /= scale;
            double newX = CollageUtils.safeClamp(
              box.position.dx + dx,
              0.0,
              box.position.dx + box.size.width - 50,
            );
            double newY = CollageUtils.safeClamp(
              box.position.dy + dy,
              0.0,
              box.position.dy + box.size.height - 50,
            );
            double newWidth = CollageUtils.safeClamp(
              box.size.width - dx,
              50.0,
              box.size.width,
            );
            double newHeight = CollageUtils.safeClamp(
              box.size.height - dy,
              50.0,
              box.size.height,
            );
            if (newWidth >= 50 && newHeight >= 50) {
              setState(() {
                box.position = Offset(newX, newY);
                box.size = Size(newWidth, newHeight);
              });
            }
          },
        ),

        // Top-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.topRight,
          size: handleSize,
          onDrag: (dx, dy) {
            final scale = _getCurrentScale();
            dx /= scale;
            dy /= scale;
            double newWidth = CollageUtils.safeClamp(
              box.size.width + dx,
              50.0,
              templateSize.width - box.position.dx,
            );
            double newY = CollageUtils.safeClamp(
              box.position.dy + dy,
              0.0,
              box.position.dy + box.size.height - 50,
            );
            double newHeight = CollageUtils.safeClamp(
              box.size.height - dy,
              50.0,
              box.size.height,
            );
            if (newHeight >= 50) {
              setState(() {
                box.size = Size(newWidth, newHeight);
                box.position = Offset(box.position.dx, newY);
              });
            }
          },
        ),

        // Bottom-left resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomLeft,
          size: handleSize,
          onDrag: (dx, dy) {
            final scale = _getCurrentScale();
            dx /= scale;
            dy /= scale;
            double newX = CollageUtils.safeClamp(
              box.position.dx + dx,
              0.0,
              box.position.dx + box.size.width - 50,
            );
            double newWidth = CollageUtils.safeClamp(
              box.size.width - dx,
              50.0,
              box.size.width,
            );
            double newHeight = CollageUtils.safeClamp(
              box.size.height + dy,
              50.0,
              templateSize.height - box.position.dy,
            );
            setState(() {
              box.position = Offset(newX, box.position.dy);
              box.size = Size(newWidth, newHeight);
            });
          },
        ),

        // Bottom-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomRight,
          size: handleSize,
          onDrag: (dx, dy) {
            final scale = _getCurrentScale();
            dx /= scale;
            dy /= scale;
            double newWidth = CollageUtils.safeClamp(
              box.size.width + dx,
              50.0,
              templateSize.width - box.position.dx,
            );
            double newHeight = CollageUtils.safeClamp(
              box.size.height + dy,
              50.0,
              templateSize.height - box.position.dy,
            );
            setState(() {
              box.size = Size(newWidth, newHeight);
            });
          },
        ),
      ],
    );
  }

  /// Get current scale from transformation controller
  double _getCurrentScale() {
    return _transformationController.value.getMaxScaleOnAxis();
  }
}
