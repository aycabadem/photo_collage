import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aspect_spec.dart';
import '../models/background.dart';
import '../services/collage_manager.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/collage_canvas.dart';
import '../widgets/custom_aspect_ratio_dialog.dart';

import '../widgets/ios_color_picker_modal.dart';
import '../widgets/border_panel.dart';
import '../widgets/layout_picker_modal.dart';

/// Main screen for the photo collage application
class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final TransformationController _transformationController =
      TransformationController();

  bool _showAspectSlider = false;
  double _aspectScalar = 1.0; // width/height ratio in [0.5, 2.0]
  bool _isAspectDragging = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CollageManager(),
      child: Consumer<CollageManager>(
        builder: (context, collageManager, child) {
          // Keep scalar in sync with current aspect when opening UI
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Photo Collage',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              toolbarHeight: 64,
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_showAspectSlider ? 64 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: _showAspectSlider ? 64 : 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _showAspectSlider
                      ? _buildAspectInlineSlider(context, collageManager)
                      : const SizedBox.shrink(),
                ),
              ),
              actions: [
                AspectRatioSelector(
                  selectedAspect: collageManager.selectedAspect,
                  presets: collageManager.presets,
                  onAspectChanged: (aspect) {
                    collageManager.applyAspect(aspect);
                  },
                  onCustomRatioPressed: () {
                    setState(() {
                      // Initialize slider with current aspect ratio
                      _aspectScalar = collageManager.selectedAspect.ratio
                          .clamp(0.5, 2.0);
                      _showAspectSlider = !_showAspectSlider;
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Save Collage button
                IconButton(
                  onPressed: () => _saveCollage(context, collageManager),
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Collage',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Initialize template size based on screen size on first frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final area = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  collageManager.updateAvailableArea(area);
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
                          animateSize: !_isAspectDragging,
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
                          onAddPhotoToBox: (box) async =>
                              await collageManager.addPhotoToBox(box),
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
                      // Layout picker button
                      _buildBottomBarButton(
                        icon: Icons.grid_view,
                        onPressed: () =>
                            _showLayoutPicker(context, collageManager),
                        isActive: false,
                      ),
                      // Future button 2
                      _buildBottomBarButton(
                        icon: Icons.info_outline,
                        onPressed: () {},
                        isActive: false,
                      ),
                      // Border button
                      _buildBottomBarButton(
                        icon: Icons.border_all,
                        onPressed: () =>
                            _showBorderPanel(context, collageManager),
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

  /// Inline aspect slider UI shown under AppBar
  Widget _buildAspectInlineSlider(
      BuildContext context, CollageManager manager) {
    String _fmt2(double v) {
      final s = v.toStringAsFixed(2);
      return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
    }

    String formatRatio(double r) {
      if (r >= 1.0) {
        return '${_fmt2(r)}:1';
      } else {
        final inv = (1.0 / r);
        return '1:${_fmt2(inv)}';
      }
    }

    return Row(
      children: [
        // Current value label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            formatRatio(_aspectScalar),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Live-updating slider
        Expanded(
          child: Slider(
            value: _aspectScalar,
            min: 0.5,
            max: 2.0,
            onChanged: (v) {
              _isAspectDragging = true;
              setState(() => _aspectScalar = v);
              // Convert scalar to AspectSpec and apply immediately
              final AspectSpec spec = v >= 1
                  ? AspectSpec(w: v, h: 1, label: formatRatio(v))
                  : AspectSpec(w: 1, h: 1 / v, label: formatRatio(v));

              final screenSize = MediaQuery.of(context).size;
              manager.applyAspect(spec, screenSize: screenSize);
            },
            onChangeEnd: (_) {
              setState(() => _isAspectDragging = false);
            },
          ),
        ),
        const SizedBox(width: 8),
        // Close toggle
        IconButton(
          onPressed: () => setState(() => _showAspectSlider = false),
          icon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
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
      barrierColor: Colors.transparent,
      builder: (context) => IOSColorPickerModal(
        currentColor: collageManager.backgroundColor,
        currentOpacity: collageManager.backgroundOpacity,
        initialMode: collageManager.backgroundMode,
        initialGradient: collageManager.backgroundGradient,
        onColorChanged: (color, opacity) {
          collageManager.setBackgroundMode(BackgroundMode.solid);
          collageManager.changeBackgroundColor(color);
          collageManager.changeBackgroundOpacity(opacity);
        },
        onGradientChanged: (spec, opacity) {
          collageManager.setBackgroundGradient(spec);
          collageManager.changeBackgroundOpacity(opacity);
        },
      ),
    );
  }

  // Show border panel modal
  void _showBorderPanel(BuildContext context, CollageManager collageManager) {
    // Reserve space for the bottom panel so canvas shrinks
    // collageManager.setBottomUiInset(130);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BorderPanel(
        collageManager: collageManager,
        onClose: () {
          // collageManager.setBottomUiInset(0);
          Navigator.of(context).pop();
        },
      ),
    ).whenComplete(() {
      // Ensure inset is reset if user dismisses with swipe/back
      // collageManager.setBottomUiInset(0);
    });
  }

  // Show layout picker modal
  void _showLayoutPicker(BuildContext context, CollageManager collageManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutPickerModal(
        onLayoutSelected: (layout) {
          collageManager.applyLayoutTemplate(layout);
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
