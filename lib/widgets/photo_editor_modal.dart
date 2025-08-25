import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
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
  late Offset _initialFocalPoint;
  late Alignment _initialAlignment;
  late double _lastScale;
  Size? _imageSize;
  final ImageEditorController _editorController = ImageEditorController();

  @override
  void initState() {
    super.initState();
    _initialFocalPoint = Offset.zero;
    _initialAlignment = widget.photoBox.alignment;
    _lastScale = widget.photoBox.photoScale;
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    if (widget.photoBox.imageFile != null) {
      final image = await decodeImageFromList(
        await widget.photoBox.imageFile!.readAsBytes(),
      );
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        // Debug: Print current alignment when image loads
        print(
          '🔍 DEBUG - Image loaded with alignment: ${widget.photoBox.alignment}',
        );
        print(
          '🔍 DEBUG - Image loaded with scale: ${widget.photoBox.photoScale}',
        );
      });
    }
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
      _initialFocalPoint = Offset.zero;
      _initialAlignment = Alignment.center;
      _lastScale = 1.0;
    });
  }

  Future<void> _saveChanges() async {
    // Use the ImageEditorController to get transformation data
    final editorDetails = _editorController.editActionDetails;

    print('🔍 DEBUG - ExtendedImage Save:');
    print('editorDetails: $editorDetails');

    if (editorDetails != null) {
      final screenDestRect = editorDetails.screenDestinationRect;
      final screenCropRect = editorDetails.screenCropRect;

      print('screenDestRect: $screenDestRect');
      print('screenCropRect: $screenCropRect');

      if (screenDestRect != null && screenCropRect != null) {
        // Simple approach: convert the relative position to alignment
        final cropWidth = screenCropRect.width;
        final cropHeight = screenCropRect.height;

        // Calculate where the image center is relative to crop center
        final imageCenterX = screenDestRect.center.dx;
        final imageCenterY = screenDestRect.center.dy;
        final cropCenterX = screenCropRect.center.dx;
        final cropCenterY = screenCropRect.center.dy;

        print('Image center: ($imageCenterX, $imageCenterY)');
        print('Crop center: ($cropCenterX, $cropCenterY)');

        // Convert to alignment (-1 to 1 range) - inverted
        final alignmentX = -((imageCenterX - cropCenterX) / (cropWidth / 2))
            .clamp(-1.0, 1.0);
        final alignmentY = -((imageCenterY - cropCenterY) / (cropHeight / 2))
            .clamp(-1.0, 1.0);

        print('Simple alignment: ($alignmentX, $alignmentY)');

        widget.photoBox.alignment = Alignment(alignmentX, alignmentY);

        print('Final PhotoBox Alignment: ${widget.photoBox.alignment}');
      } else {
        print('🔍 DEBUG - Screen rects are null, keeping current values');
      }
    } else {
      print('🔍 DEBUG - Editor details null, keeping current values');
    }

    // Notify parent that photo box has changed
    if (widget.onPhotoChanged != null) {
      widget.onPhotoChanged!();
    }

    Navigator.of(context).pop();
  }
}
