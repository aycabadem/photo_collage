import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/photo_box.dart';

class PhotoEditorModal extends StatefulWidget {
  final PhotoBox photoBox;
  final VoidCallback? onPhotoChanged;

  const PhotoEditorModal({
    super.key,
    required this.photoBox,
    this.onPhotoChanged,
  });

  @override
  State<PhotoEditorModal> createState() => _PhotoEditorModalState();
}

class _PhotoEditorModalState extends State<PhotoEditorModal> {
  GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();
  // Removed unused state fields
  final ImageEditorController _editorController = ImageEditorController();
  bool _syncedInitialView = false;
  int _alignmentRetry = 0;

  @override
  void initState() {
    super.initState();
    // No-op initialization
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Crop Photo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _resetToOriginal,
                        child: const Text('Reset'),
                      ),
                      TextButton(
                        onPressed: _saveChanges,
                        child: const Text('Save'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Photo Editor Area - Custom Crop Canvas
            Flexible(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    color: Colors.grey[800],
                  ),
                  child: SizedBox(
                    width: widget.photoBox.size.width,
                    height: widget.photoBox.size.height,
                    child: ClipRect(
                      child: widget.photoBox.imageFile != null
                          ? ExtendedImage.file(
                              widget.photoBox.imageFile!,
                              key: editorKey,
                              fit: BoxFit
                                  .contain, // required by ExtendedImage editor
                              alignment: widget.photoBox.alignment,
                              mode: ExtendedImageMode.editor,
                              enableLoadState: true,
                              loadStateChanged: (ExtendedImageState state) {
                                if (state.extendedImageLoadState ==
                                    LoadState.completed) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    // ignore: avoid_print
                                    print(
                                      '[PhotoEditorModal] load completed; opening with alignment='
                                      '${widget.photoBox.alignment} scale=${widget.photoBox.photoScale}',
                                    );
                                    _syncInitialViewUsingController(state);
                                  });
                                }
                                return null; // use default completed widget
                              },
                              initGestureConfigHandler: (state) {
                                // Map PhotoBox's cover-based scale to editor's contain-based scale
                                double initialScale =
                                    widget.photoBox.photoScale;
                                final ui.Image? raw =
                                    state.extendedImageInfo?.image;
                                if (raw != null) {
                                  final boxW = widget.photoBox.size.width;
                                  final boxH = widget.photoBox.size.height;
                                  final wr = boxW / raw.width;
                                  final hr = boxH / raw.height;
                                  final containBase = math.min(wr, hr);
                                  final coverBase = math.max(wr, hr);
                                  final coverToContain =
                                      coverBase / containBase; // >= 1
                                  initialScale =
                                      widget.photoBox.photoScale *
                                      coverToContain;
                                }
                                return GestureConfig(
                                  inPageView: false,
                                  minScale: 1.0,
                                  maxScale: 8.0,
                                  animationMaxScale: 8.0,
                                  initialScale: initialScale,
                                );
                              },
                              initEditorConfigHandler: (state) {
                                return EditorConfig(
                                  maxScale: 8.0,
                                  cropRectPadding: const EdgeInsets.all(0),
                                  hitTestSize: 20.0,
                                  initCropRectType: InitCropRectType.layoutRect,
                                  cropAspectRatio:
                                      widget.photoBox.size.width /
                                      widget.photoBox.size.height,
                                  controller: _editorController,
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 64),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '📱 Gesture Instructions:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('👆 Drag: Move photo'),
                  const Text('🤏 Pinch: Zoom in/out'),
                  const Text('🔄 Reset: Return to original'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetToOriginal() {
    setState(() {
      widget.photoBox.photoScale = 1.0;
      widget.photoBox.alignment = Alignment.center;
    });
  }

  Future<void> _saveChanges() async {
    // Use the ImageEditorController to get transformation data
    final editorDetails = _editorController.editActionDetails;

    if (editorDetails != null) {
      final screenDestRect = editorDetails.screenDestinationRect;
      final screenCropRect = editorDetails.screenCropRect;

      if (screenDestRect != null && screenCropRect != null) {
        // Compute overflow of the image (after zoom) relative to the crop area.
        // Alignment should be normalized against the available overflow, not the crop size.
        final overflowW = screenDestRect.width - screenCropRect.width;
        final overflowH = screenDestRect.height - screenCropRect.height;

        double alignmentX = 0.0;
        double alignmentY = 0.0;

        if (overflowW > 0) {
          alignmentX =
              ((screenCropRect.center.dx - screenDestRect.center.dx) /
                      (overflowW / 2))
                  .clamp(-1.0, 1.0);
        }
        if (overflowH > 0) {
          alignmentY =
              ((screenCropRect.center.dy - screenDestRect.center.dy) /
                      (overflowH / 2))
                  .clamp(-1.0, 1.0);
        }

        // Snap tiny numerical noise to zero for cleaner values
        if (alignmentX.abs() < 1e-6) alignmentX = 0.0;
        if (alignmentY.abs() < 1e-6) alignmentY = 0.0;

        // Compute photo scale relative to how Image.file is shown (BoxFit.cover)
        // Editor gives contain-based total scale; convert back to cover-based.
        final scaleW = screenDestRect.width / screenCropRect.width;
        final scaleH = screenDestRect.height / screenCropRect.height;
        final containScale = math.min(scaleW, scaleH);

        double photoScale = containScale;
        final ui.Image? raw = editorKey.currentState?.image;
        if (raw != null) {
          final boxW = widget.photoBox.size.width;
          final boxH = widget.photoBox.size.height;
          final wr = boxW / raw.width;
          final hr = boxH / raw.height;
          final containBase = math.min(wr, hr);
          final coverBase = math.max(wr, hr);
          final coverToContain = coverBase / containBase; // >= 1
          photoScale = containScale / coverToContain;
        }
        if (photoScale < 1.0) photoScale = 1.0;

        widget.photoBox.alignment = Alignment(alignmentX, alignmentY);
        widget.photoBox.photoScale = photoScale;

        // Debug: alignment result
        // ignore: avoid_print
        print(
          "alignment: $alignmentX, $alignmentY  scale: ${widget.photoBox.photoScale}",
        );
      } else {}
    } else {}

    // Notify parent that photo box has changed
    if (widget.onPhotoChanged != null) {
      widget.onPhotoChanged!();
    }

    Navigator.of(context).pop();
  }

  // Map continuous Alignment to nearest InitialAlignment for gesture init.
  InitialAlignment _initialAlignmentFrom(Alignment a) {
    final double x = a.x;
    final double y = a.y;
    final int col = x < -0.33 ? 0 : (x > 0.33 ? 2 : 1);
    final int row = y < -0.33 ? 0 : (y > 0.33 ? 2 : 1);
    if (row == 0 && col == 0) return InitialAlignment.topLeft;
    if (row == 0 && col == 1) return InitialAlignment.topCenter;
    if (row == 0 && col == 2) return InitialAlignment.topRight;
    if (row == 1 && col == 0) return InitialAlignment.centerLeft;
    if (row == 1 && col == 1) return InitialAlignment.center;
    if (row == 1 && col == 2) return InitialAlignment.centerRight;
    if (row == 2 && col == 0) return InitialAlignment.bottomLeft;
    if (row == 2 && col == 1) return InitialAlignment.bottomCenter;
    return InitialAlignment.bottomRight;
  }

  void _applyInitialViewFromPhotoBox(
    ExtendedImageState? state,
    EditActionDetails? details,
  ) {
    if (_syncedInitialView || details == null || state == null) return;
    if (details.layoutTopLeft == null) return;
    final Rect? crop = details.screenCropRect;
    final Rect? baseRaw = details.rawDestinationRect;
    final ui.Image? rawImg = state.extendedImageInfo?.image;
    if (crop == null || baseRaw == null || rawImg == null) return;

    // Map cover -> contain scale
    final double boxW = widget.photoBox.size.width;
    final double boxH = widget.photoBox.size.height;
    final double wr = boxW / rawImg.width;
    final double hr = boxH / rawImg.height;
    final double containBase = math.min(wr, hr);
    final double coverBase = math.max(wr, hr);
    final double coverToContain = coverBase / containBase;
    final double targetScale = (widget.photoBox.photoScale * coverToContain)
        .clamp(1.0, 8.0);

    // Compute desired image center after scaling based on alignment
    final double scaledW = baseRaw.width * targetScale;
    final double scaledH = baseRaw.height * targetScale;
    final double overflowW = scaledW - crop.width;
    final double overflowH = scaledH - crop.height;
    // Use saved alignment from the PhotoBox
    final Alignment a = widget.photoBox.alignment;
    final Offset targetCenter = Offset(
      crop.center.dx - (overflowW > 0 ? a.x * (overflowW / 2) : 0.0),
      crop.center.dy - (overflowH > 0 ? a.y * (overflowH / 2) : 0.0),
    );

    // Apply scale around the target pivot so alignment is preserved
    details.screenFocalPoint = targetCenter;
    details.preTotalScale = details.totalScale;
    details.totalScale = targetScale;
    details.getFinalDestinationRect();

    // Final tiny correction to match target center exactly
    final Rect newDest = details.screenDestinationRect!;
    final Offset deltaCenter = targetCenter - newDest.center;
    if (deltaCenter.distance > 0.5) {
      details.delta = deltaCenter;
      details.getFinalDestinationRect();
    }

    // ignore: avoid_print
    print(
      '[PhotoEditorModal] INIT crop=$crop raw=$baseRaw targetScale='
      '${targetScale.toStringAsFixed(3)} overflow=(${overflowW.toStringAsFixed(2)},${overflowH.toStringAsFixed(2)}) '
      'targetCenter=$targetCenter newDest=${details.screenDestinationRect}',
    );

    _editorController.saveCurrentState();
    _verifyAndCorrectAlignment(state, details);
  }

  void _verifyAndCorrectAlignment(
    ExtendedImageState state,
    EditActionDetails details,
  ) {
    if (_alignmentRetry > 6) {
      _syncedInitialView = true;
      if (mounted) setState(() {});
      return;
    }
    final Rect? crop = details.screenCropRect;
    final Rect? dest = details.screenDestinationRect;
    if (crop == null || dest == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _verifyAndCorrectAlignment(state, details),
      );
      return;
    }
    final double overflowW = dest.width - crop.width;
    final double overflowH = dest.height - crop.height;

    double curAlignX = 0.0;
    double curAlignY = 0.0;
    if (overflowW > 0) {
      curAlignX = ((crop.center.dx - dest.center.dx) / (overflowW / 2)).clamp(
        -1.0,
        1.0,
      );
    }
    if (overflowH > 0) {
      curAlignY = ((crop.center.dy - dest.center.dy) / (overflowH / 2)).clamp(
        -1.0,
        1.0,
      );
    }

    // Target from saved alignment
    final double targetX = widget.photoBox.alignment.x;
    final double targetY = widget.photoBox.alignment.y;
    final double dxRatio = targetX - curAlignX;
    final double dyRatio = targetY - curAlignY;

    // ignore: avoid_print
    print(
      '[PhotoEditorModal] VERIFY try=$_alignmentRetry cur=($curAlignX,$curAlignY) '
      'target=($targetX,$targetY) overflow=(${overflowW.toStringAsFixed(2)},${overflowH.toStringAsFixed(2)})',
    );

    if (dxRatio.abs() < 0.01 && dyRatio.abs() < 0.01) {
      _syncedInitialView = true;
      if (mounted) setState(() {});
      return;
    }

    double dx = 0.0;
    double dy = 0.0;
    if (overflowW > 0) dx = -dxRatio * (overflowW / 2);
    if (overflowH > 0) dy = -dyRatio * (overflowH / 2);

    details.delta = Offset(dx, dy);
    details.getFinalDestinationRect();
    _editorController.saveCurrentState();
    // ignore: avoid_print
    print(
      '[PhotoEditorModal] VERIFY apply delta=(${dx.toStringAsFixed(2)},${dy.toStringAsFixed(2)}) dest='
      '${details.screenDestinationRect}',
    );
    _alignmentRetry += 1;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _verifyAndCorrectAlignment(state, details),
    );
  }

  void _syncInitialViewUsingController(ExtendedImageState state) {
    if (_syncedInitialView) return;
    final details = _editorController.editActionDetails;
    if (details == null) {
      // Try again next frame
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncInitialViewUsingController(state),
      );
      return;
    }
    // Ensure rects and image are ready (avoid touching screenCropRect until layoutTopLeft is set)
    if (details.layoutTopLeft == null ||
        details.screenDestinationRect == null ||
        state.extendedImageInfo?.image == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncInitialViewUsingController(state),
      );
      return;
    }
    // ignore: avoid_print
    print(
      '[PhotoEditorModal] SYNC ready; applying initial alignment=${widget.photoBox.alignment} '
      'scale=${widget.photoBox.photoScale}',
    );
    _alignmentRetry = 0;
    _applyInitialViewFromPhotoBox(state, details);
  }
}
