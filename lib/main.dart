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

class AspectSpec {
  final int w;
  final int h;
  final String label;
  const AspectSpec(this.w, this.h, this.label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AspectSpec && w == other.w && h == other.h);
  @override
  int get hashCode => Object.hash(w, h);
}

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});
  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final double baseWidth = 300;
  final double minHeight = 200; // Minimum yükseklik
  final List<AspectSpec> presets = const [
    AspectSpec(5, 4, '5:4'),
    AspectSpec(4, 5, '4:5'),
    AspectSpec(4, 3, '4:3'),
    AspectSpec(3, 4, '3:4'),
    AspectSpec(9, 16, '9:16'),
    AspectSpec(16, 9, '16:9'),
    AspectSpec(1, 1, '1:1'),
  ];

  late AspectSpec selectedAspect = presets.firstWhere((a) => a.label == '9:16');
  late Size templateSize = _sizeForAspect(selectedAspect);

  List<PhotoBox> photoBoxes = [];
  PhotoBox? selectedBox;

  Size _sizeForAspect(AspectSpec a) {
    // Önce normal boyutu hesapla
    double width = baseWidth;
    double height = baseWidth * a.h / a.w;

    // Eğer yükseklik minimum'dan küçükse, boyutu ayarla
    if (height < minHeight) {
      height = minHeight;
      width = minHeight * a.w / a.h;
    }

    return Size(width, height);
  }

  void _applyAspect(AspectSpec newAspect) {
    final oldSize = templateSize;
    final newSize = _sizeForAspect(newAspect);
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    setState(() {
      selectedAspect = newAspect;
      templateSize = newSize;
      for (final box in photoBoxes) {
        box.position = Offset(box.position.dx * sx, box.position.dy * sy);
        box.size = Size(box.size.width * sx, box.size.height * sy);
        final clampedX = box.position.dx.clamp(
          0.0,
          templateSize.width - box.size.width,
        );
        final clampedY = box.position.dy.clamp(
          0.0,
          templateSize.height - box.size.height,
        );
        box.position = Offset(clampedX, clampedY);
      }
    });
  }

  Future<void> _openCustomAspectDialog() async {
    final wCtrl = TextEditingController(text: selectedAspect.w.toString());
    final hCtrl = TextEditingController(text: selectedAspect.h.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Özel Oran (Genişlik:Yükseklik)'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: wCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Genişlik'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: hCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Yükseklik'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Uygula'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final w = int.tryParse(wCtrl.text);
    final h = int.tryParse(hCtrl.text);
    if (w == null || h == null || w <= 0 || h <= 0) return;
    final custom = AspectSpec(w, h, '$w:$h');
    _applyAspect(custom);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ...presets.map((a) => DropdownMenuItem(value: a, child: Text(a.label))),
      if (!presets.contains(selectedAspect))
        DropdownMenuItem(
          value: selectedAspect,
          child: Text(selectedAspect.label),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Collage"),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<AspectSpec>(
              value: selectedAspect,
              icon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.aspect_ratio),
              ),
              items: items,
              onChanged: (v) {
                if (v != null) _applyAspect(v);
              },
            ),
          ),
          IconButton(
            tooltip: 'Özel oran',
            onPressed: _openCustomAspectDialog,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: (templateSize.width + 40) > constraints.maxWidth
                    ? templateSize.width + 40
                    : constraints.maxWidth,
                height: (templateSize.height + 40) > constraints.maxHeight
                    ? templateSize.height + 40
                    : constraints.maxHeight,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    width: templateSize.width,
                    height: templateSize.height,
                    color: Colors.grey[200],
                    child: Stack(
                      children: [
                        for (var box in photoBoxes) _buildPhotoBox(box),
                        if (selectedBox != null) _buildOverlay(selectedBox!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
