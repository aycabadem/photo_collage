import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/photo_box.dart';

class PhotoEditorPage extends StatefulWidget {
  final PhotoBox photoBox;
  final VoidCallback? onPhotoChanged;

  const PhotoEditorPage({
    super.key,
    required this.photoBox,
    this.onPhotoChanged,
  });

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final GlobalKey<ExtendedImageEditorState> _editorKey =
      GlobalKey<ExtendedImageEditorState>();
  final ImageEditorController _editorController = ImageEditorController();
  bool _syncedInitialView = false;
  int _alignmentRetry = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Photo'),
        actions: [
          TextButton(onPressed: _resetToOriginal, child: const Text('Reset')),
          TextButton(onPressed: _saveChanges, child: const Text('Save')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Available drawing area (padding 16 on each side)
          final availWidth = constraints.maxWidth - 32;
          final availHeight = constraints.maxHeight - 32;
          return Center(child: _buildEditor(context, availWidth, availHeight));
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context, double maxWidth, double maxHeight) {
    final canvasAspect =
        widget.photoBox.size.width / widget.photoBox.size.height;

    // Fill as large as possible: start with full width, adjust to height if needed
    double targetWidth = maxWidth;
    double targetHeight = targetWidth / canvasAspect;
    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = targetHeight * canvasAspect;
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(color: scheme.surface),
      padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 32),
      child: SizedBox(
        width: targetWidth,
        height: targetHeight,
        child: ClipRect(
          child: _buildEditorContent(context, scheme),
        ),
      ),
    );
  }

  Widget _buildEditorContent(BuildContext context, ColorScheme scheme) {
    if (kIsWeb) {
      return Center(
        child: Text(
          'Photo editing is unavailable on web preview.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final imageFile = widget.photoBox.imageFile;
    if (imageFile != null) {
      return ExtendedImage.file(
        imageFile as dynamic,
        key: _editorKey,
        fit: BoxFit.contain,
        alignment: widget.photoBox.alignment,
        mode: ExtendedImageMode.editor,
        enableLoadState: true,
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncInitialViewUsingController(state);
            });
          }
          return null;
        },
        initGestureConfigHandler: (state) {
          double initialScale = widget.photoBox.photoScale;
          final ui.Image? raw = state.extendedImageInfo?.image;
          if (raw != null) {
            final boxW = widget.photoBox.size.width;
            final boxH = widget.photoBox.size.height;
            final wr = boxW / raw.width;
            final hr = boxH / raw.height;
            final containBase = math.min(wr, hr);
            final coverBase = math.max(wr, hr);
            final coverToContain = coverBase / containBase;
            initialScale = widget.photoBox.photoScale * coverToContain;
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
                widget.photoBox.size.width / widget.photoBox.size.height,
            controller: _editorController,
          );
        },
      );
    }

    return Container(
      color: scheme.surface,
      alignment: Alignment.center,
      child: Icon(Icons.image, size: 64, color: scheme.primary),
    );
  }

  void _resetToOriginal() {
    setState(() {
      widget.photoBox.photoScale = 1.0;
      widget.photoBox.alignment = Alignment.center;
    });
  }

  Future<void> _saveChanges() async {
    final editorDetails = _editorController.editActionDetails;

    if (editorDetails != null) {
      final screenDestRect = editorDetails.screenDestinationRect;
      final screenCropRect = editorDetails.screenCropRect;

      if (screenDestRect != null && screenCropRect != null) {
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

        if (alignmentX.abs() < 1e-6) alignmentX = 0.0;
        if (alignmentY.abs() < 1e-6) alignmentY = 0.0;

        final scaleW = screenDestRect.width / screenCropRect.width;
        final scaleH = screenDestRect.height / screenCropRect.height;
        final containScale = math.min(scaleW, scaleH);

        double photoScale = containScale;
        final ui.Image? raw = _editorKey.currentState?.image;
        if (raw != null) {
          final boxW = widget.photoBox.size.width;
          final boxH = widget.photoBox.size.height;
          final wr = boxW / raw.width;
          final hr = boxH / raw.height;
          final containBase = math.min(wr, hr);
          final coverBase = math.max(wr, hr);
          final coverToContain = coverBase / containBase;
          photoScale = containScale / coverToContain;
        }
        if (photoScale < 1.0) photoScale = 1.0;

        widget.photoBox.alignment = Alignment(alignmentX, alignmentY);
        widget.photoBox.photoScale = photoScale;
      }
    }

    widget.onPhotoChanged?.call();
    if (mounted) Navigator.of(context).pop();
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

    final double boxW = widget.photoBox.size.width;
    final double boxH = widget.photoBox.size.height;
    final double wr = boxW / rawImg.width;
    final double hr = boxH / rawImg.height;
    final double containBase = math.min(wr, hr);
    final double coverBase = math.max(wr, hr);
    final double coverToContain = coverBase / containBase;
    final double targetScale = (widget.photoBox.photoScale * coverToContain)
        .clamp(1.0, 8.0);

    final double scaledW = baseRaw.width * targetScale;
    final double scaledH = baseRaw.height * targetScale;
    final double overflowW = scaledW - crop.width;
    final double overflowH = scaledH - crop.height;
    final Alignment a = widget.photoBox.alignment;
    final Offset targetCenter = Offset(
      crop.center.dx - (overflowW > 0 ? a.x * (overflowW / 2) : 0.0),
      crop.center.dy - (overflowH > 0 ? a.y * (overflowH / 2) : 0.0),
    );

    details.screenFocalPoint = targetCenter;
    details.preTotalScale = details.totalScale;
    details.totalScale = targetScale;
    details.getFinalDestinationRect();

    final Rect newDest = details.screenDestinationRect!;
    final Offset deltaCenter = targetCenter - newDest.center;
    if (deltaCenter.distance > 0.5) {
      details.delta = deltaCenter;
      details.getFinalDestinationRect();
    }

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

    final double targetX = widget.photoBox.alignment.x;
    final double targetY = widget.photoBox.alignment.y;
    final double dxRatio = targetX - curAlignX;
    final double dyRatio = targetY - curAlignY;

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
    _alignmentRetry += 1;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _verifyAndCorrectAlignment(state, details),
    );
  }

  void _syncInitialViewUsingController(ExtendedImageState state) {
    if (_syncedInitialView) return;
    final details = _editorController.editActionDetails;
    if (details == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncInitialViewUsingController(state),
      );
      return;
    }
    if (details.layoutTopLeft == null ||
        details.screenDestinationRect == null ||
        state.extendedImageInfo?.image == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncInitialViewUsingController(state),
      );
      return;
    }
    _alignmentRetry = 0;
    _applyInitialViewFromPhotoBox(state, details);
  }
}
