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
  final double baseWidth = 350; // Biraz küçülttük
  final double minHeight = 220; // Biraz küçülttük
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

  final TransformationController _transformationController =
      TransformationController();

  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    // Varsayılan boyutlar
    double maxWidth = baseWidth;
    double maxHeight = baseWidth;

    if (screenSize != null) {
      // FloatingActionButton ve diğer UI elementleri için yer bırak
      double availableWidth = screenSize.width - 100; // Padding ve FAB için
      double availableHeight =
          screenSize.height - 150; // AppBar, padding ve FAB için

      // Ekran alanının büyük kısmını kullan ama sınırlar koy
      maxWidth = availableWidth.clamp(250, 500.0);
      maxHeight = availableHeight.clamp(200, 700.0);
    }

    // Oranın tipine göre boyutlama stratejisi
    double aspectRatio = a.w / a.h;
    double width, height;

    if (aspectRatio > 2) {
      // Çok geniş oranlar (19:9, 16:1 vs.)
      height = minHeight.clamp(220, maxHeight * 0.4);
      width = (height * aspectRatio).clamp(maxWidth * 0.8, maxWidth);
      if (width > maxWidth) {
        width = maxWidth;
        height = width / aspectRatio;
      }
    } else if (aspectRatio < 0.5) {
      // Çok uzun oranlar (9:16, 1:6 vs.)
      width = maxWidth * 0.6;
      height = width / aspectRatio;
      if (height > maxHeight) {
        height = maxHeight;
        width = height * aspectRatio;
      }
    } else {
      // Normal oranlar (1:1, 3:4, 4:3 vs.) - ekranı daha iyi kullan
      if (aspectRatio >= 1) {
        // Yatay veya kare
        width = maxWidth * 0.85;
        height = width / aspectRatio;
        if (height > maxHeight * 0.8) {
          height = maxHeight * 0.8;
          width = height * aspectRatio;
        }
      } else {
        // Dikey
        height = maxHeight * 0.8;
        width = height * aspectRatio;
        if (width > maxWidth * 0.85) {
          width = maxWidth * 0.85;
          height = width / aspectRatio;
        }
      }
    }

    // Minimum boyut kontrolü
    if (width < 200) width = 200;
    if (height < 150) height = 150;

    return Size(width, height);
  }

  void _applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    final oldSize = templateSize;
    final newSize = _sizeForAspect(newAspect, screenSize: screenSize);
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
    final screenSize = MediaQuery.of(context).size;
    _applyAspect(custom, screenSize: screenSize);
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
                if (v != null) {
                  final screenSize = MediaQuery.of(context).size;
                  _applyAspect(v, screenSize: screenSize);
                }
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
          // İlk kez ekran boyutuna göre template boyutunu ayarla
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final screenSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final newSize = _sizeForAspect(
              selectedAspect,
              screenSize: screenSize,
            );
            if (templateSize != newSize) {
              setState(() {
                templateSize = newSize;
              });
            }
          });

          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.3,
            maxScale: 5.0,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(100),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: (templateSize.width + 100) > constraints.maxWidth
                      ? templateSize.width + 100
                      : constraints.maxWidth,
                  height: (templateSize.height + 120) > constraints.maxHeight
                      ? templateSize.height + 120
                      : constraints.maxHeight,
                  padding: const EdgeInsets.all(50), // Padding'i artırdık
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        // Boş alana tıklayınca seçimi iptal et
                        setState(() {
                          selectedBox = null;
                        });
                      },
                      child: Container(
                        width: templateSize.width,
                        height: templateSize.height,
                        color: Colors.grey[200],
                        child: Stack(
                          children: [
                            for (var box in photoBoxes) _buildPhotoBox(box),
                            if (selectedBox != null)
                              _buildOverlay(selectedBox!),
                          ],
                        ),
                      ),
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

  double _getCurrentScale() {
    return _transformationController.value.getMaxScaleOnAxis();
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
          final scale = _getCurrentScale();
          setState(() {
            double newX = (box.position.dx + details.delta.dx / scale).clamp(
              0.0,
              templateSize.width - box.size.width,
            );
            double newY = (box.position.dy + details.delta.dy / scale).clamp(
              0.0,
              templateSize.height - box.size.height,
            );
            box.position = Offset(newX, newY);
          });
        },
        child: Container(
          width: box.size.width,
          height: box.size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: selectedBox == box
                ? Border.all(color: Colors.white, width: 3)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: (box.size.width / 4).clamp(20, 40),
                ),
                const SizedBox(height: 4),
                Text(
                  "Fotoğraf",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: (box.size.width / 10).clamp(10, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(PhotoBox box) {
    double handleSize = 16.0;
    return Stack(
      children: [
        Positioned(
          top: box.position.dy + 8,
          left: box.position.dx + box.size.width - 32,
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
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.delete_outline,
                size: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
        _buildHandle(box, Alignment.topLeft, handleSize, (dx, dy) {
          final scale = _getCurrentScale();
          dx /= scale;
          dy /= scale;
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
          final scale = _getCurrentScale();
          dx /= scale;
          dy /= scale;
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
          final scale = _getCurrentScale();
          dx /= scale;
          dy /= scale;
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
          final scale = _getCurrentScale();
          dx /= scale;
          dy /= scale;
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade300, Colors.blue.shade500],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.open_in_full,
            size: size * 0.6,
            color: Colors.white,
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
