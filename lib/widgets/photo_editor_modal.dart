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
                              fit: BoxFit.contain,
                              mode: ExtendedImageMode.editor,
                              enableLoadState: true,
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
        // In PhotoBoxWidget, 1.0 means "just cover" the box. The editor uses
        // contain + zoom, so derive the extra scale over cover:
        final scaleW = screenDestRect.width / screenCropRect.width;
        final scaleH = screenDestRect.height / screenCropRect.height;
        double computedPhotoScale = math.min(scaleW, scaleH);
        if (computedPhotoScale < 1.0)
          computedPhotoScale = 1.0; // never below cover

        widget.photoBox.alignment = Alignment(alignmentX, alignmentY);
        widget.photoBox.photoScale = computedPhotoScale;

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
}
