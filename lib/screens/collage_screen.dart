import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aspect_spec.dart';
import '../models/background.dart';
import '../services/collage_manager.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/collage_canvas.dart';

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

  double _aspectScalar = 1.0; // width/height ratio in [0.5, 2.0]
  bool _isAspectDragging = false;
  String? _activeTool;

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
                'Custom Collage',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              toolbarHeight: 64,
              backgroundColor: const Color(0xFFFCFAEE),
              elevation: 0,
              shadowColor: Colors.transparent,
              actions: [
                IconButton(
                  tooltip: 'Add Photo Box',
                  onPressed: () => collageManager.addPhotoBox(),
                  icon: const Icon(Icons.add_a_photo),
                ),
                IconButton(
                  tooltip: 'Save Collage',
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveCollage(context, collageManager),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Gradient outer background (behind white canvas)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCFAEE),
                    ),
                  ),
                ),
                // Main canvas and interactions
                Padding(
                  // Reserve only bottom space; AppBar manages top
                  padding: const EdgeInsets.only(bottom: 90),
                  child: LayoutBuilder(
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
                                getCurrentScale: _getCurrentScale,
                                onBoxSelected: (box) =>
                                    collageManager.selectBox(box),
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
                                onBoxDeleted: (box) =>
                                    collageManager.deleteBox(box),
                                onAddPhotoToBox: (box) async =>
                                    await collageManager.addPhotoToBox(box),
                                onResizeHandleDragged:
                                    (box, dx, dy, alignment) {
                                      // Handle resize with scale
                                      final scale = _getCurrentScale();
                                      collageManager.resizeBoxFromHandle(
                                        box,
                                        alignment,
                                        dx / scale,
                                        dy / scale,
                                      );
                                    },
                                onBackgroundTap: () =>
                                    collageManager.selectBox(null),
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
                ),

                // Free-floating bottom controls (no navbar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24, // slightly higher from the bottom
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Layouts
                      _buildBottomBarButton(
                        icon: Icons.grid_view,
                        label: 'Layout',
                        onPressed: () => _showLayoutPicker(context, collageManager),
                        isActive: false,
                      ),
                      // Margins / Border panel
                      _buildBottomBarButton(
                        icon: Icons.border_all,
                        label: 'Spacing',
                        onPressed: () => _showBorderPanel(context, collageManager),
                        isActive: false,
                      ),
                      // Background color
                      _buildBottomBarButton(
                        icon: Icons.format_paint,
                        label: 'Background',
                        onPressed: () => _toggleTool(context, 'background', () => _showColorPicker(context, collageManager)),
                        isActive: false,
                      ),
                      // Aspect panel
                      _buildBottomBarButton(
                        icon: Icons.aspect_ratio,
                        label: 'Aspect',
                        onPressed: () => _toggleTool(context, 'aspect', () => _showAspectPanel(context, collageManager)),
                        isActive: false,
                      ),
                      // Save was moved to AppBar
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Inline aspect slider UI shown under AppBar
  // Removed: old inline aspect slider (Aspect now handled by bottom sheet)

  void _toggleTool(BuildContext context, String key, VoidCallback open) {
    if (_activeTool == key) {
      Navigator.of(context).maybePop();
      _activeTool = null;
      return;
    }
    _activeTool = key;
    open();
  }

  // Aspect as a bottom sheet: presets + slider
  void _showAspectPanel(BuildContext context, CollageManager manager) {
    // Initialize current ratio for potential slider use
    setState(() {
      _aspectScalar = manager.selectedAspect.ratio.clamp(0.5, 2.0);
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool showSlider = false;
        return StatefulBuilder(
          builder: (context, setLocal) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFAEE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AspectRatioSelector(
                        selectedAspect: manager.selectedAspect,
                        presets: manager.presetsWithCustom,
                        onAspectChanged: (aspect) {
                          manager.applyAspect(aspect);
                          // Rebuild header instantly so selection reflects
                          setLocal(() {});
                        },
                        onCustomRatioPressed: () {
                          setLocal(() {
                            showSlider = true;
                            _aspectScalar = manager.selectedAspect.ratio.clamp(0.5, 2.0);
                          });
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: showSlider
                        ? Padding(
                            key: const ValueKey('slider'),
                            padding: const EdgeInsets.only(top: 8, bottom: 10),
                            child: _buildAspectSliderInlineBody(
                              context,
                              manager,
                              setLocal,
                              () => setLocal(() {
                                    showSlider = false;
                                  }),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _activeTool = null;
    });
  }

  // Slider body used in bottom sheet; closes on change end
  Widget _buildAspectSliderInlineBody(
    BuildContext context,
    CollageManager manager,
    void Function(void Function()) setLocal,
    VoidCallback hideSlider,
  ) {
    String fmt2(double v) {
      final s = v.toStringAsFixed(2);
      return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
    }
    String formatRatio(double r) => r >= 1.0 ? '${fmt2(r)}:1' : '1:${fmt2(1.0 / r)}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAEE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x33A5B68D)),
          ),
          child: Text(
            formatRatio(_aspectScalar),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFA5B68D),
              inactiveTrackColor: const Color(0x4DA5B68D),
              thumbColor: const Color(0xFFA5B68D),
            ),
            child: Slider(
              value: _aspectScalar,
              min: 0.5,
              max: 2.0,
              onChanged: (v) {
                _isAspectDragging = true;
                setLocal(() => _aspectScalar = v);
                final AspectSpec spec = v >= 1
                    ? AspectSpec(w: v, h: 1, label: formatRatio(v))
                    : AspectSpec(w: 1, h: 1 / v, label: formatRatio(v));
                final screenSize = MediaQuery.of(context).size;
                manager.applyAspect(spec, screenSize: screenSize);
              },
              onChangeEnd: (_) {
                setLocal(() => _isAspectDragging = false);
                final AspectSpec spec = _aspectScalar >= 1
                    ? AspectSpec(w: _aspectScalar, h: 1, label: formatRatio(_aspectScalar))
                    : AspectSpec(w: 1, h: 1 / _aspectScalar, label: formatRatio(_aspectScalar));
                manager.setCustomAspect(spec);
                // Keep the slider open until the sheet is dismissed
              },
          ),
        ),
        ),
      ],
    );
  }

  /// Get current scale from transformation controller
  double _getCurrentScale() {
    final matrix = _transformationController.value;
    return matrix.getMaxScaleOnAxis();
  }

  // Legacy custom aspect dialog removed (handled via bottom sheet)

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
      barrierColor: Colors.transparent,
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
      barrierColor: Colors.transparent,
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
    String? label,
    required VoidCallback onPressed,
    required bool isActive,
    Widget? child,
  }) {
    if (child != null) {
      return child;
    }

    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
