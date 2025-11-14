part of '../collage_manager.dart';

mixin _CollagePhotoBoxControls on _CollageManagerBase {
  void selectBox(PhotoBox? box) {
    suppressNextHistoryEntry();
    _selectedBox = box;
    notifyListeners();
  }

  void bringBoxToFront(PhotoBox box) {
    final int index = _photoBoxes.indexOf(box);
    if (index < 0) return;
    if (index == _photoBoxes.length - 1) {
      _selectedBox = box;
      notifyListeners();
      return;
    }

    _photoBoxes
      ..removeAt(index)
      ..add(box);
    _selectedBox = box;
    notifyListeners();
  }

  PhotoBox? _nextLayoutSlotForInsertion() {
    if (_photoBoxes.isEmpty || _templateSize.width == 0 || _templateSize.height == 0) {
      return null;
    }

    final List<PhotoBox> ordered = List<PhotoBox>.from(_photoBoxes);
    const double rowTolerance = 0.02;
    const double columnTolerance = 0.01;

    ordered.sort((a, b) {
      final double ay = a.position.dy / _templateSize.height;
      final double by = b.position.dy / _templateSize.height;
      final double yDiff = ay - by;

      if (yDiff.abs() > rowTolerance) {
        return yDiff < 0 ? -1 : 1;
      }

      final double ax = a.position.dx / _templateSize.width;
      final double bx = b.position.dx / _templateSize.width;
      final double xDiff = ax - bx;

      if (xDiff.abs() > columnTolerance) {
        return xDiff < 0 ? -1 : 1;
      }
      return 0;
    });

    for (final box in ordered) {
      final bool hasPhoto =
          box.imageFile != null && (box.imagePath != null && box.imagePath!.isNotEmpty);
      if (!hasPhoto) {
        return box;
      }
    }

    return ordered.isNotEmpty ? ordered.last : null;
  }

  Future<void> addPhotoBox() async {
    PhotoBox? pendingSlot;
    final bool fillingTemplateSlot = _currentLayout != null && !_isCustomMode;
    if (fillingTemplateSlot) {
      pendingSlot = _nextLayoutSlotForInsertion();
      if (pendingSlot == null) {
        return;
      }
      pendingSlot.isLoading = true;
      notifyListeners();
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (pickedFile == null) return;

      if (fillingTemplateSlot && pendingSlot != null) {
        pendingSlot
          ..imageFile = File(pickedFile.path)
          ..imagePath = pickedFile.path
          ..imageFit = BoxFit.cover
          ..photoOffset = Offset.zero
          ..photoScale = 1.0
          ..cropRect = const Rect.fromLTWH(0, 0, 1, 1)
          ..alignment = Alignment.center
          ..rotationRadians = 0.0
          ..rotationBaseRadians = 0.0
          ..isLoading = false;

        notifyListeners();
        return;
      }

      const Size defaultSize = Size(220, 220);
      final Offset pos = CollageUtils.findNonOverlappingPosition(
        _photoBoxes,
        _templateSize,
        defaultSize,
      );

      final newBox = PhotoBox(
        position: pos,
        size: defaultSize,
        imageFile: File(pickedFile.path),
        imagePath: pickedFile.path,
      );

      _photoBoxes.add(newBox);
      notifyListeners();
    } finally {
      if (pendingSlot != null && pendingSlot.isLoading) {
        pendingSlot.isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addPhotoToBox(PhotoBox targetBox) async {
    if (targetBox.isLoading) return;
    targetBox.isLoading = true;
    notifyListeners();
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (pickedFile == null) return;

      targetBox.imageFile = File(pickedFile.path);
      targetBox.imagePath = pickedFile.path;
      targetBox.isLoading = false;
      notifyListeners();
    } finally {
      if (targetBox.isLoading) {
        targetBox.isLoading = false;
        notifyListeners();
      }
    }
  }

  void deleteBox(PhotoBox box) {
    if (_currentLayout != null && !_isCustomMode) {
      box.imageFile = null;
      box.imagePath = '';
      box.photoScale = 1.0;
      box.alignment = Alignment.center;
      if (_selectedBox == box) {
        _selectedBox = box;
      }
      notifyListeners();
      return;
    }

    _photoBoxes.remove(box);
    if (_selectedBox == box) {
      _selectedBox = null;
    }
    notifyListeners();
  }
}
