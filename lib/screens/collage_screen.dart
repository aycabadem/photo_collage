import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/background.dart';
import '../models/photo_box.dart';
import '../services/collage_manager.dart';
import '../widgets/collage_canvas.dart';

import '../widgets/ios_color_picker_modal.dart';
import '../widgets/border_panel.dart';
import '../widgets/layout_picker_modal.dart';
import 'photo_editor_page.dart';
import 'profile_screen.dart';

/// Main screen for the photo collage application
class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  static const MethodChannel _galleryChannel = MethodChannel('collage/gallery');
  final TransformationController _transformationController =
      TransformationController();

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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  onPressed: () => _saveCollage(context, collageManager),
                  icon: SvgPicture.asset(
                    'assets/icons/save_arrow.svg',
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Account',
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => _openProfile(collageManager),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
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
                                animateSize: true,
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

    if (!manager.isPremium && !manager.isTrialActive) {
      final int limit = manager.weeklySaveLimit;
      if (limit > 0 && manager.weeklySavesUsed >= limit) {
        await _showSaveLimitDialog(context, manager);
        return;
      }
    }

    manager.setSelectedExportWidth(selectedWidth);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bool saved = await manager.saveCollage(exportWidth: selectedWidth);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (saved) {
        await _showSaveSuccessDialog(context);
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

  Future<void> _showSaveLimitDialog(
    BuildContext context,
    CollageManager manager,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Free saves used up'),
        content: const Text(
          'You have used your 3 free saves for this week. Start your free 3-day trial or upgrade to keep exporting collages without limits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openProfile(manager);
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveSuccessDialog(BuildContext context) async {
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
                  await _openPhotosApp(context);
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

  void _openProfile(CollageManager manager) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: manager,
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  Future<void> _openPhotosApp(BuildContext context) async {
    bool handled = false;
    try {
      await _galleryChannel.invokeMethod<void>('openGallery');
      handled = true;
    } catch (_) {
      handled = false;
    }

    if (handled) return;

    Uri? fallbackUri;
    if (Platform.isIOS) {
      fallbackUri = Uri.parse('photos-redirect://');
    } else if (Platform.isAndroid) {
      fallbackUri = Uri.parse('content://media/external/images/media');
    }

    if (fallbackUri == null || !await canLaunchUrl(fallbackUri)) {
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

    final opened =
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 22,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
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
                            color: scheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Save image',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the export size before saving your collage.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.7),
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
                      const SizedBox(height: 12),
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
                              onPressed: () => Navigator.of(sheetContext)
                                  .pop(selectedWidth),
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
    final hostContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => LayoutPickerModal(
        onLayoutSelected: (layout) {
          collageManager.applyLayoutTemplate(layout);
        },
        isPremium: collageManager.isPremium || collageManager.isTrialActive,
        onUpgradeRequested: () {
          Navigator.of(context).pop();
          _openProfile(collageManager);
        },
        hostContext: hostContext,
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
