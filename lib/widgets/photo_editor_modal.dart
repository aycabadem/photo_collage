import 'package:flutter/material.dart';
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
  late Offset _initialFocalPoint;
  late Alignment _initialAlignment;
  late double _lastScale;
  Size? _imageSize;

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
        print('🔍 DEBUG - Image loaded with alignment: ${widget.photoBox.alignment}');
        print('🔍 DEBUG - Image loaded with scale: ${widget.photoBox.photoScale}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print current state during build
    print('🔍 DEBUG - Modal BUILD:');
    print('Current PhotoBox Alignment: ${widget.photoBox.alignment}');
    print('Current PhotoBox Scale: ${widget.photoBox.photoScale}');
    
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
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _lastScale = widget.photoBox.photoScale;
                          _initialAlignment = widget.photoBox.alignment;
                          _initialFocalPoint = details.localFocalPoint;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            // Handle scaling - update PhotoBox scale directly
                            widget.photoBox.photoScale = (_lastScale * details.scale).clamp(0.5, 3.0);

                            // Handle panning - convert to alignment changes
                            if (_imageSize != null) {
                              final delta =
                                  details.localFocalPoint - _initialFocalPoint;

                              // Calculate how much the alignment should change based on pan
                              final containerWidth = widget.photoBox.size.width;
                              final containerHeight =
                                  widget.photoBox.size.height;

                              // Convert pan delta to alignment change (inverted because alignment works opposite to pan)
                              final alignmentDeltaX =
                                  -delta.dx / (containerWidth * 0.5);
                              final alignmentDeltaY =
                                  -delta.dy / (containerHeight * 0.5);

                              // Update alignment
                              final newAlignmentX =
                                  (_initialAlignment.x + alignmentDeltaX).clamp(
                                    -1.0,
                                    1.0,
                                  );
                              final newAlignmentY =
                                  (_initialAlignment.y + alignmentDeltaY).clamp(
                                    -1.0,
                                    1.0,
                                  );

                              widget.photoBox.alignment = Alignment(
                                newAlignmentX,
                                newAlignmentY,
                              );
                            }
                          });
                        },
                        child: widget.photoBox.imageFile != null
                            ? ClipRect(
                                child: Transform.scale(
                                  scale: widget.photoBox.photoScale, // Use PhotoBox scale directly
                                  child: Image.file(
                                    widget.photoBox.imageFile!,
                                    fit: BoxFit.cover,
                                    width: widget.photoBox.size.width,
                                    height: widget.photoBox.size.height,
                                    alignment: widget.photoBox.alignment,
                                  ),
                                ),
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

  void _saveChanges() {
    // Values are already updated in real-time during gestures
    // Just trigger the callback and close

    print('🔍 DEBUG - Saving Changes:');
    print('Final Scale: ${widget.photoBox.photoScale}');
    print('Final Alignment: ${widget.photoBox.alignment}');

    if (widget.onPhotoChanged != null) {
      widget.onPhotoChanged!();
    }

    Navigator.of(context).pop();
  }
}
