import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collage_manager.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/collage_canvas.dart';
import '../widgets/custom_aspect_ratio_dialog.dart';
import '../models/aspect_spec.dart';

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
              title: const Text('Photo Collage'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

                return InteractiveViewer(
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
                        onResizeHandleDragged: (box, dx, dy) {
                          // Handle resize with scale
                          final scale = _getCurrentScale();
                          collageManager.resizeBox(box, dx / scale, dy / scale);
                        },
                        onBackgroundTap: () => collageManager.selectBox(null),
                      ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => collageManager.addPhotoBox(),
              child: const Icon(Icons.photo_library),
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
}
