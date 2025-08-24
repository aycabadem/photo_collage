import 'package:flutter/material.dart';
import 'dart:io';
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
  late Offset _photoOffset;
  late double _photoScale;
  late Rect _cropRect;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _photoOffset = widget.photoBox.photoOffset;
    _photoScale = widget.photoBox.photoScale;
    _cropRect = widget.photoBox.cropRect;

    // Initialize transformation controller
    _transformationController = TransformationController();

    // Set initial transformation based on current offset and scale
    // Önce translate, sonra scale (getTranslation() için)
    final matrix = Matrix4.identity()
      ..translate(_photoOffset.dx, _photoOffset.dy)
      ..scale(_photoScale);
    _transformationController.value = matrix;
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
                    'Edit Photo',
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

            // Photo Editor Area - Kutu boyutunda viewport
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[800], // Dark background like React example
                ),
                child: SizedBox(
                  width: widget.photoBox.size.width,
                  height: widget.photoBox.size.height,
                  child: ClipRect(
                    // overflow: hidden equivalent
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false, // <-- zorlamayı kaldırdık
                      boundaryMargin: const EdgeInsets.all(
                        double.infinity,
                      ), // <-- pan serbest
                      transformationController: _transformationController,
                      child: widget.photoBox.imageFile != null
                          ? Image.file(
                              widget.photoBox.imageFile!,
                              fit: BoxFit.cover, // Viewport'a uygun
                              alignment: Alignment(0.0, 0.0),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 64),
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
                  const Text('👆 Single finger: Pan (move photo)'),
                  const Text('👆👆 Two fingers: Zoom in/out'),
                  const Text('🔄 Double tap: Reset zoom'),
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
      _photoOffset = const Offset(0, 0);
      _photoScale = 1.0;
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _transformationController.value =
          Matrix4.identity(); // Reset InteractiveViewer
    });
  }

  Future<void> _saveChanges() async {
    // Get transformation matrix and extract offset/scale
    final matrix = _transformationController.value;

    // Extract translation (pan) - convert to alignment
    final translation = matrix.getTranslation();
    final newOffset = Offset(translation.x, translation.y);

    print('newOffset: $newOffset');
    print('boxSize: ${widget.photoBox.size}');

    // Calculate alignment from offset coordinates
    // Convert offset to alignment range (-1.0 to 1.0)
    // Offset (0,0) should be alignment (-1,-1)
    // Offset at limits should be alignment (1,1)
    final boxSize = widget.photoBox.size;
    final alignmentX = (newOffset.dx / boxSize.width * 2).clamp(-1.0, 1.0);
    final alignmentY = (newOffset.dy / boxSize.height * 2).clamp(-1.0, 1.0);
    // final newAlignment = Alignment(alignmentX, alignmentY);

    final photoSizeX = widget.photoBox.size.width;
    final photoSizeY = widget.photoBox.size.height;

    print('photoSizeX: $photoSizeX');
    print('photoSizeY: $photoSizeY');

    final absNewOffsetX = newOffset.dx.abs();
    final absNewOffsetY = newOffset.dy.abs();
    // Get image dimensions
    final image = await decodeImageFromList(
      await widget.photoBox.imageFile!.readAsBytes(),
    );
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final newAlignment = Alignment(
      -1 + (absNewOffsetX + boxSize.width) / imageWidth,
      -1 + (absNewOffsetY + boxSize.height) / imageHeight,
    );

    double overflowX = imageWidth - boxSize.width;
    double overflowY = imageHeight - boxSize.height;

    double alignmentXX = overflowX != 0
        ? (-2 * newOffset.dx / overflowX - 1).clamp(-1.0, 1.0)
        : 0;
    double alignmentYY = overflowY != 0
        ? (-2 * newOffset.dy / overflowY - 1).clamp(-1.0, 1.0)
        : 0;

    Alignment result = Alignment(alignmentXX, alignmentYY);
    print(result); // Alignment(-0.5, 0.0)

    print('newAlignment: $newAlignment');
    print('result: $result');

    print('--------------------------------');

    // Extract scale (zoom) - save this
    final newScale = matrix.getMaxScaleOnAxis();

    // Update the photo box with new values
    // widget.photoBox.photoOffset = newOffset; // Don't save offset
    widget.photoBox.photoScale = newScale;
    widget.photoBox.cropRect = _cropRect;
    widget.photoBox.alignment = result; // Save new alignment

    // Notify parent that photo box has changed
    if (widget.onPhotoChanged != null) {
      widget.onPhotoChanged!();
    }

    Navigator.of(context).pop();
  }
}
