import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  final ImagePicker _imagePicker = ImagePicker(); // Fotoğraf seçici

  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    // Varsayılan boyutlar
    double maxWidth = baseWidth;
    double maxHeight = baseWidth;

    if (screenSize != null) {
      // FloatingActionButton ve diğer UI elementleri için yer bırak
      double availableWidth = screenSize.width - 100; // Padding ve FAB için
      double availableHeight =
          screenSize.height - 150; // AppBar, padding ve FAB için

      // Daha sıkı sınırlar - overflow'u önle
      maxWidth = availableWidth.clamp(300, 450.0); // 350 → 450 (daha büyük)
      maxHeight = availableHeight.clamp(250, 500.0); // 400 → 500 (daha büyük)
    }

    // Oranın tipine göre boyutlama stratejisi
    double aspectRatio = a.w / a.h;
    double width, height;

    if (aspectRatio > 2) {
      // Çok geniş oranlar (19:9, 16:1 vs.)
      height = minHeight.clamp(220, maxHeight * 0.4); // 0.3 → 0.4 (daha büyük)
      width = (height * aspectRatio).clamp(
        maxWidth * 0.8, // 0.7 → 0.8
        maxWidth * 0.95, // 0.9 → 0.95
      );
      if (width > maxWidth * 0.95) {
        width = maxWidth * 0.95;
        height = width / aspectRatio;
      }
    } else if (aspectRatio < 0.5) {
      // Çok uzun oranlar (9:16, 1:6 vs.)
      width = maxWidth * 0.7; // 0.5 → 0.7 (daha büyük)
      height = width / aspectRatio;
      if (height > maxHeight * 0.95) {
        // 0.9 → 0.95
        height = maxHeight * 0.95;
        width = height * aspectRatio;
      }
    } else {
      // Normal oranlar (1:1, 3:4, 4:3 vs.) - ekranı daha iyi kullan
      if (aspectRatio >= 1) {
        // Yatay veya kare
        width = maxWidth * 0.9; // 0.8 → 0.9 (daha büyük)
        height = width / aspectRatio;
        if (height > maxHeight * 0.8) {
          // 0.7 → 0.8
          height = maxHeight * 0.8;
          width = height * aspectRatio;
        }
      } else {
        // Dikey
        height = maxHeight * 0.8; // 0.7 → 0.8 (daha büyük)
        width = height * aspectRatio;
        if (width > maxWidth * 0.9) {
          // 0.8 → 0.9
          width = maxWidth * 0.9;
          height = width / aspectRatio;
        }
      }
    }

    // Minimum boyut kontrolü
    if (width < 200) width = 200;
    if (height < 150) height = 150;

    // Maksimum boyut kontrolü - overflow'u önle
    if (width > maxWidth * 0.95) width = maxWidth * 0.95;
    if (height > maxHeight * 0.95) height = maxHeight * 0.95;

    return Size(width, height);
  }

  void _applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    final oldSize = templateSize;
    final newSize = _sizeForAspect(newAspect, screenSize: screenSize);

    setState(() {
      selectedAspect = newAspect;
      templateSize = newSize;

      // Kutuları yeni template boyutuna göre yeniden boyutlandır ve konumlandır
      for (final box in photoBoxes) {
        // Kutuyu yeni template boyutuna sığdır
        double newWidth = box.size.width;
        double newHeight = box.size.height;

        // Eğer kutu template'den büyükse küçült
        if (newWidth > newSize.width - 40) {
          newWidth = newSize.width - 40;
        }
        if (newHeight > newSize.height - 40) {
          newHeight = newSize.height - 40;
        }

        // Minimum boyut kontrolü
        if (newWidth < 50) newWidth = 50;
        if (newHeight < 50) newHeight = 50;

        // Boyutu güncelle
        box.size = Size(newWidth, newHeight);

        // Pozisyonu yeni template boyutuna göre ayarla
        double newX = box.position.dx;
        double newY = box.position.dy;

        // Eğer kutu template dışındaysa içeri al
        if (newX < 0) newX = 0;
        if (newY < 0) newY = 0;
        if (newX + newWidth > newSize.width) {
          newX = newSize.width - newWidth;
        }
        if (newY + newHeight > newSize.height) {
          newY = newSize.height - newHeight;
        }

        // Pozisyonu güncelle
        box.position = Offset(newX, newY);
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
            maxScale: 3.0,
            panEnabled: false, // Pan tamamen kapalı - background sabit
            scaleEnabled: true, // Sadece zoom aktif
            boundaryMargin: EdgeInsets.zero,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                      clipBehavior:
                          Clip.hardEdge, // Overflow'u kesin olarak önle
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
        onPressed: () async {
          // Fotoğraf seç
          final XFile? pickedFile = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );
          
          if (pickedFile != null) {
            // Yeni fotoğraf kutusu oluştur
            Size boxSize = const Size(150, 150);
            Offset pos = findNonOverlappingPosition(
              photoBoxes,
              templateSize,
              boxSize,
            );
            
            setState(() {
              var newBox = PhotoBox(
                position: pos, 
                size: boxSize,
                imageFile: File(pickedFile.path),
                imagePath: pickedFile.path,
              );
              photoBoxes.add(newBox);
              selectedBox = newBox;
            });
          }
        },
        child: const Icon(Icons.photo_library),
      ),
    );
  }

  double _getCurrentScale() {
    return _transformationController.value.getMaxScaleOnAxis();
  }

  // Güvenli clamp fonksiyonu - min > max durumunu önler
  double _safeClamp(double value, double min, double max) {
    if (min > max) return min; // Invalid case - return min
    return value.clamp(min, max);
  }

  Widget _buildPhotoBox(PhotoBox box) {
    // Basit kontrol: kutu template içinde mi?
    if (box.position.dx < 0 ||
        box.position.dy < 0 ||
        box.position.dx + box.size.width > templateSize.width ||
        box.position.dy + box.size.height > templateSize.height) {
      return const SizedBox.shrink(); // Template dışındaki kutuları gizle
    }

    // Template içindeki kutuları göster
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
            double newX = _safeClamp(
              box.position.dx + details.delta.dx / scale,
              0.0,
              templateSize.width - box.size.width,
            );
            double newY = _safeClamp(
              box.position.dy + details.delta.dy / scale,
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
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: selectedBox == box
                ? Border.all(color: Colors.yellow, width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Fotoğraf veya placeholder
                box.imageFile != null
                    ? Image.file(
                        box.imageFile!,
                        fit: BoxFit.cover,
                        width: box.size.width,
                        height: box.size.height,
                      )
                    : Container(
                        color: Colors.blue[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                
                // Delete butonu (seçili kutularda)
                if (selectedBox == box)
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
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
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
        _buildHandle(box, Alignment.topLeft, handleSize, (dx, dy) {
          final scale = _getCurrentScale();
          dx /= scale;
          dy /= scale;
          double newX = _safeClamp(
            box.position.dx + dx,
            0.0,
            box.position.dx + box.size.width - 50,
          );
          double newY = _safeClamp(
            box.position.dy + dy,
            0.0,
            box.position.dy + box.size.height - 50,
          );
          double newWidth = _safeClamp(
            box.size.width - dx,
            50.0,
            box.size.width,
          );
          double newHeight = _safeClamp(
            box.size.height - dy,
            50.0,
            box.size.height,
          );
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
          double newWidth = _safeClamp(
            box.size.width + dx,
            50.0,
            templateSize.width - box.position.dx,
          );
          double newY = _safeClamp(
            box.position.dy + dy,
            0.0,
            box.position.dy + box.size.height - 50,
          );
          double newHeight = _safeClamp(
            box.size.height - dy,
            50.0,
            box.size.height,
          );
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
          double newX = _safeClamp(
            box.position.dx + dx,
            0.0,
            box.position.dx + box.size.width - 50,
          );
          double newWidth = _safeClamp(
            box.size.width - dx,
            50.0,
            box.size.width,
          );
          double newHeight = _safeClamp(
            box.size.height + dy,
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
          double newWidth = _safeClamp(
            box.size.width + dx,
            50.0,
            templateSize.width - box.position.dx,
          );
          double newHeight = _safeClamp(
            box.size.height + dy,
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
              colors: [Colors.blue[300]!, Colors.blue[500]!],
            ),

            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.open_in_full, color: Colors.white, size: 10),
        ),
      ),
    );
  }

  Offset findNonOverlappingPosition(
    List<PhotoBox> existing,
    Size templateSize,
    Size newSize,
  ) {
    // Template sınırları kontrolü
    if (newSize.width > templateSize.width ||
        newSize.height > templateSize.height) {
      // Eğer kutu template'den büyükse, template'in ortasına yerleştir
      return Offset(
        (templateSize.width - newSize.width) / 2,
        (templateSize.height - newSize.height) / 2,
      );
    }

    // Eğer hiç kutu yoksa, sol üst köşeye yerleştir
    if (existing.isEmpty) {
      return const Offset(20, 20);
    }

    double margin = 20; // Kenar boşluğu
    double spacing = 30; // Kutular arası boşluk

    // Grid tabanlı arama - daha küçük adımlarla
    for (
      double y = margin;
      y <= templateSize.height - newSize.height - margin;
      y += spacing
    ) {
      for (
        double x = margin;
        x <= templateSize.width - newSize.width - margin;
        x += spacing
      ) {
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

    // Grid'de yer bulunamazsa, mevcut kutuların yanına yerleştir
    for (final box in existing) {
      // Sağ tarafa yerleştir
      double x = box.position.dx + box.size.width + spacing;
      double y = box.position.dy;

      if (x + newSize.width <= templateSize.width - margin) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (otherBox) => newRect.overlaps(
            Rect.fromLTWH(
              otherBox.position.dx,
              otherBox.position.dy,
              otherBox.size.width,
              otherBox.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }

      // Alt tarafa yerleştir
      x = box.position.dx;
      y = box.position.dy + box.size.height + spacing;

      if (y + newSize.height <= templateSize.height - margin) {
        Rect newRect = Rect.fromLTWH(x, y, newSize.width, newSize.height);
        bool overlaps = existing.any(
          (otherBox) => newRect.overlaps(
            Rect.fromLTWH(
              otherBox.position.dx,
              otherBox.position.dy,
              otherBox.size.width,
              otherBox.size.height,
            ),
          ),
        );
        if (!overlaps) return Offset(x, y);
      }
    }

    // Hala yer bulunamazsa, template'in ortasına yerleştir
    return Offset(
      (templateSize.width - newSize.width) / 2,
      (templateSize.height - newSize.height) / 2,
    );
  }
}

class PhotoBox {
  Offset position;
  Size size;
  File? imageFile; // Fotoğraf dosyası
  String? imagePath; // Fotoğraf yolu
  
  PhotoBox({
    required this.position, 
    required this.size,
    this.imageFile,
    this.imagePath,
  });
}
