import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/aspect_spec.dart';
import '../models/background.dart';
import '../models/photo_box.dart';
import '../services/collage_manager.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/collage_canvas.dart';

import '../widgets/ios_color_picker_modal.dart';
import '../widgets/border_panel.dart';
import '../widgets/layout_picker_modal.dart';
import 'photo_editor_page.dart';

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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
              ),
              backgroundColor: const Color(0xFFFCFAEE),
              elevation: 0,
              shadowColor: Colors.transparent,
              actions: [
                IconButton(
                  tooltip: 'Add Photo Box',
                  onPressed: () => collageManager.addPhotoBox(),
                  icon: const Icon(Icons.add_a_photo),
                  iconSize: 28,
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Save Collage',
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveCollage(context, collageManager),
                  iconSize: 28,
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Stack(
              children: [
                // Gradient outer background (behind white canvas)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFFFCFAEE)),
                  ),
                ),
                // Main canvas and interactions
                Padding(
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
                          panEnabled: true,
                          scaleEnabled: true,
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
                                onBoxBroughtToFront: (box) =>
                                    collageManager.bringBoxToFront(box),
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
                                onEditBox: (box) => _openPhotoEditor(
                                  context,
                                  collageManager,
                                  box,
                                ),
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
                        onPressed: () =>
                            _showLayoutPicker(context, collageManager),
                        isActive: false,
                      ),
                      // Margins / Border panel
                      _buildBottomBarButton(
                        icon: Icons.border_all,
                        label: 'Style',
                        onPressed: () =>
                            _showBorderPanel(context, collageManager),
                        isActive: false,
                      ),
                      // Background color
                      _buildBottomBarButton(
                        icon: Icons.format_paint,
                        label: 'Background',
                        onPressed: () => _toggleTool(
                          context,
                          'background',
                          () => _showColorPicker(context, collageManager),
                        ),
                        isActive: false,
                      ),
                      // Aspect panel
                      _buildBottomBarButton(
                        icon: Icons.aspect_ratio,
                        label: 'Aspect',
                        onPressed: () => _toggleTool(
                          context,
                          'aspect',
                          () => _showAspectPanel(context, collageManager),
                        ),
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

  Future<void> _openPhotoEditor(
    BuildContext context,
    CollageManager manager,
    PhotoBox box,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(
          photoBox: box,
          onPhotoChanged: manager.refresh,
        ),
      ),
    );
  }

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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom,
            ),
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
                            _aspectScalar = manager.selectedAspect.ratio.clamp(
                              0.5,
                              2.0,
                            );
                          });
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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

    String formatRatio(double r) =>
        r >= 1.0 ? '${fmt2(r)}:1' : '1:${fmt2(1.0 / r)}';

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
                    ? AspectSpec(
                        w: _aspectScalar,
                        h: 1,
                        label: formatRatio(_aspectScalar),
                      )
                    : AspectSpec(
                        w: 1,
                        h: 1 / _aspectScalar,
                        label: formatRatio(_aspectScalar),
                      );
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
    final selectedWidth = await _showResolutionPicker(context, manager);

    if (!context.mounted || selectedWidth == null) {
      return;
    }

    manager.setSelectedExportWidth(selectedWidth);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final savedPath = await manager.saveCollage(exportWidth: selectedWidth);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (savedPath != null) {
        await _showSaveSuccessDialog(context, savedPath);
      } else {
        await _showSaveErrorDialog(context);
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop();
        if (context.mounted) {
          await _showSaveErrorDialog(context);
        }
      }
    }
  }

  Future<void> _showSaveSuccessDialog(
    BuildContext context,
    String savedPath,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.burst_mode_outlined,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Photo Saved!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your collage is in the gallery.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _openPhotosApp(context, savedPath);
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Open Photos'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaveErrorDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 18),
              Text(
                'Save Failed',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                "We couldn't save your collage. Please try again.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPhotosApp(BuildContext context, String maybePath) async {
    Uri? uri;

    if (maybePath.isNotEmpty) {
      try {
        final parsed = Uri.parse(maybePath);
        uri = parsed.scheme.isEmpty ? Uri.file(maybePath) : parsed;
      } catch (_) {
        uri = Uri.file(maybePath);
      }
    }

    uri ??= () {
      if (Platform.isIOS) {
        return Uri.parse('photos-redirect://');
      }
      if (Platform.isAndroid) {
        return Uri.parse('content://media/internal/images/media');
      }
      return null;
    }();

    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open gallery.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open gallery.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<int?> _showResolutionPicker(
    BuildContext context,
    CollageManager manager,
  ) {
    final options = manager.resolutionOptions;
    if (options.isEmpty) {
      return Future.value(manager.selectedExportWidth);
    }

    int selectedWidth = manager.selectedExportWidth;
    final double aspectRatio = manager.selectedAspect.ratio;

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Save resolution',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the export size before saving your collage.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<int>(
                      groupValue: selectedWidth,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedWidth = value);
                      },
                      child: Column(
                        children: [
                          for (final option in options)
                            RadioListTile<int>(
                              value: option.width,
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text('${option.label} (${option.width}px)'),
                              subtitle: Text(
                                '${option.width} x '
                                '${(option.width / aspectRatio).round()}px',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(selectedWidth),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    ).whenComplete(() {
      _activeTool = null;
    });
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
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
