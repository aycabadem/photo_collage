import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collage_manager.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/collage_canvas.dart';
import '../widgets/custom_aspect_ratio_dialog.dart';
import '../widgets/color_picker_button.dart';
import '../widgets/ios_color_picker_modal.dart';

/// Main screen for the photo collage application
class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CollageManager(),
      child: Consumer<CollageManager>(
        builder: (context, collageManager, child) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Photo Collage',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              actions: [
                AspectRatioSelector(
                  selectedAspect: collageManager.selectedAspect,
                  presets: collageManager.presets,
                  onAspectChanged: (aspect) {
                    final screenSize = MediaQuery.of(context).size;
                    collageManager.applyAspect(aspect, screenSize: screenSize);
                  },
                  onCustomRatioPressed: () =>
                      _openCustomAspectDialog(context, collageManager),
                ),
                const SizedBox(width: 16),
                // Save Collage button
                IconButton(
                  onPressed: () => _saveCollage(context, collageManager),
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Collage',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Initialize template size based on screen size on first frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final screenSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  collageManager.initializeTemplateSize(screenSize);
                });

                return GestureDetector(
                  onTap: () {
                    // Deselect when tapping outside the InteractiveViewer
                    collageManager.selectBox(null);
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.3,
                    maxScale: 3.0,
                    panEnabled: true, // Always allow panning
                    scaleEnabled: true, // Zoom active
                    boundaryMargin: EdgeInsets.zero,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Center(
                        child: CollageCanvas(
                          templateSize: collageManager.templateSize,
                          photoBoxes: collageManager.photoBoxes,
                          selectedBox: collageManager.selectedBox,
                          onBoxSelected: (box) => collageManager.selectBox(box),
                          onBoxDragged: (box, details) {
                            // Handle box dragging with scale
                            final scale = _getCurrentScale();
                            collageManager.moveBox(
                              box,
                              Offset(
                                details.delta.dx / scale,
                                details.delta.dy / scale,
                              ),
                            );
                          },
                          onBoxDeleted: (box) => collageManager.deleteBox(box),
                          onResizeHandleDragged: (box, dx, dy, alignment) {
                            // Handle resize with scale
                            final scale = _getCurrentScale();
                            collageManager.resizeBoxFromHandle(
                              box,
                              alignment,
                              dx / scale,
                              dy / scale,
                            );
                          },
                          onBackgroundTap: () => collageManager.selectBox(null),
                          guidelines: collageManager.selectedBox != null
                              ? collageManager.getAlignmentGuidelines(
                                  collageManager.selectedBox!,
                                )
                              : [],
                          collageManager: collageManager,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: Consumer<CollageManager>(
              builder: (context, collageManager, child) {
                return Container(
                  height: 90, // Orta seviye alan
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Future button 1
                      _buildBottomBarButton(
                        icon: Icons.settings,
                        onPressed: () {},
                        isActive: false,
                      ),
                      // Future button 2
                      _buildBottomBarButton(
                        icon: Icons.info_outline,
                        onPressed: () {},
                        isActive: false,
                      ),
                      // Future button 3
                      _buildBottomBarButton(
                        icon: Icons.help_outline,
                        onPressed: () {},
                        isActive: false,
                      ),
                      // Color picker button
                      _buildBottomBarButton(
                        icon: Icons.format_paint, // Boya kovası icon'u
                        onPressed: () =>
                            _showColorPicker(context, collageManager),
                        isActive: false,
                      ),
                      // Photo add button
                      _buildBottomBarButton(
                        icon: Icons.camera_alt, // Sadece kamera icon'u
                        onPressed: () => collageManager.addPhotoBox(),
                        isActive: false, // Diğerleri ile aynı renk
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Get current scale from transformation controller
  double _getCurrentScale() {
    final matrix = _transformationController.value;
    return matrix.getMaxScaleOnAxis();
  }

  /// Open custom aspect ratio dialog
  Future<void> _openCustomAspectDialog(
    BuildContext context,
    CollageManager manager,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => CustomAspectRatioDialog(
        currentAspect: manager.selectedAspect,
        onRatioApplied: (customAspect) {
          final screenSize = MediaQuery.of(context).size;
          manager.applyAspect(customAspect, screenSize: screenSize);
        },
      ),
    );
  }

  /// Save the current collage
  Future<void> _saveCollage(
    BuildContext context,
    CollageManager manager,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await manager.saveCollage();

      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collage saved successfully to gallery!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save collage. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show color picker modal
  void _showColorPicker(BuildContext context, CollageManager collageManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => iOSColorPickerModal(
        currentColor: collageManager.backgroundColor,
        currentOpacity: collageManager.backgroundOpacity,
        onColorChanged: (color, opacity) {
          collageManager.changeBackgroundColor(color);
          collageManager.changeBackgroundOpacity(opacity);
        },
      ),
    );
  }

  // Build bottom bar button
  Widget _buildBottomBarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    Widget? child,
  }) {
    if (child != null) {
      return child;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        icon,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
        size: 28, // Sadece icon, hiç arka plan yok
      ),
    );
  }
}
