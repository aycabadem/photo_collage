import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Collage App',
      home: const CollageScreen(),
    );
  }
}

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  Size templateSize = const Size(300, 533); // 9:16
  List<PhotoBox> photoBoxes = [];
  PhotoBox? selectedBox;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Collage")),
      body: Center(
        child: Container(
          width: templateSize.width,
          height: templateSize.height,
          color: Colors.grey[200],
          child: Stack(
            children: [
              // Tüm kutular
              for (var box in photoBoxes) _buildPhotoBox(box),
              // Overlay: delete + resize handle
              if (selectedBox != null) _buildOverlay(selectedBox!),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Size boxSize = const Size(100, 100);
          Offset pos = findNonOverlappingPosition(
            photoBoxes,
            templateSize,
            boxSize,
          );
          setState(() {
            var newBox = PhotoBox(position: pos, size: boxSize);
            photoBoxes.add(newBox);
            selectedBox = newBox;
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPhotoBox(PhotoBox box) {
    return Positioned(
      left: box.position.dx,
      top: box.position.dy,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBox = box;
          });
        },
        onPanUpdate: (details) {
          if (selectedBox != box) return;
          setState(() {
            double newX = (box.position.dx + details.delta.dx).clamp(
              0.0,
              templateSize.width - box.size.width,
            );
            double newY = (box.position.dy + details.delta.dy).clamp(
              0.0,
              templateSize.height - box.size.height,
            );
            box.position = Offset(newX, newY);
          });
        },
        child: Container(
          width: box.size.width,
          height: box.size.height,
          color: Colors.blueAccent,
          child: const Center(child: Text("Photo")),
        ),
      ),
    );
  }

  Widget _buildOverlay(PhotoBox box) {
    double handleSize = 12.0;

    return Stack(
      children: [
        // Delete button
        Positioned(
          top: box.position.dy - 16,
          left: box.position.dx + box.size.width - 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                photoBoxes.remove(box);
                selectedBox = null;
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),

        // Resize handles
        _buildHandle(box, Alignment.topLeft, handleSize, (dx, dy) {
          double newX = (box.position.dx + dx).clamp(
            0.0,
            box.position.dx + box.size.width - 50,
          );
          double newY = (box.position.dy + dy).clamp(
            0.0,
            box.position.dy + box.size.height - 50,
          );
          double newWidth = box.size.width - dx;
          double newHeight = box.size.height - dy;
          if (newWidth >= 50 && newHeight >= 50) {
            setState(() {
              box.position = Offset(newX, newY);
              box.size = Size(newWidth, newHeight);
            });
          }
        }),
        _buildHandle(box, Alignment.topRight, handleSize, (dx, dy) {
          double newWidth = (box.size.width + dx).clamp(
            50.0,
            templateSize.width - box.position.dx,
          );
          double newY = (box.position.dy + dy).clamp(
            0.0,
            box.position.dy + box.size.height - 50,
          );
          double newHeight = box.size.height - dy;
          if (newHeight >= 50) {
            setState(() {
              box.size = Size(newWidth, newHeight);
              box.position = Offset(box.position.dx, newY);
            });
          }
        }),
        _buildHandle(box, Alignment.bottomLeft, handleSize, (dx, dy) {
          double newX = (box.position.dx + dx).clamp(
            0.0,
            box.position.dx + box.size.width - 50,
          );
          double newWidth = box.size.width - dx;
          double newHeight = (box.size.height + dy).clamp(
            50.0,
            templateSize.height - box.position.dy,
          );
          setState(() {
            box.position = Offset(newX, box.position.dy);
            box.size = Size(newWidth, newHeight);
          });
        }),
        _buildHandle(box, Alignment.bottomRight, handleSize, (dx, dy) {
          double newWidth = (box.size.width + dx).clamp(
            50.0,
            templateSize.width - box.position.dx,
          );
          double newHeight = (box.size.height + dy).clamp(
            50.0,
            templateSize.height - box.position.dy,
          );
          setState(() {
            box.size = Size(newWidth, newHeight);
          });
        }),
      ],
    );
  }

  Widget _buildHandle(
    PhotoBox box,
    Alignment alignment,
    double size,
    void Function(double dx, double dy) onDrag,
  ) {
    double left = box.position.dx;
    double top = box.position.dy;

    if (alignment == Alignment.topRight) left += box.size.width - size;
    if (alignment == Alignment.bottomLeft) top += box.size.height - size;
    if (alignment == Alignment.bottomRight) {
      left += box.size.width - size;
      top += box.size.height - size;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Offset findNonOverlappingPosition(
    List<PhotoBox> existing,
    Size templateSize,
    Size newSize,
  ) {
    double step = 10;
    for (double y = 0; y <= templateSize.height - newSize.height; y += step) {
      for (double x = 0; x <= templateSize.width - newSize.width; x += step) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (box) => newRect.overlaps(
            Rect.fromLTWH(
              box.position.dx,
              box.position.dy,
              box.size.width,
              box.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }
    }
    return const Offset(0, 0);
  }
}

class PhotoBox {
  Offset position;
  Size size;

  PhotoBox({required this.position, required this.size});
}
