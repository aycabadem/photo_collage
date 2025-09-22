part of '../collage_manager.dart';

mixin _CollagePhotoBoxControls on _CollageManagerBase {
  void selectBox(PhotoBox? box) {
    _selectedBox = box;
    notifyListeners();
  }

  Future<void> addPhotoBox() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (pickedFile == null) return;

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
    _selectedBox = newBox;
    notifyListeners();
  }

  Future<void> addPhotoToBox(PhotoBox targetBox) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (pickedFile == null) return;

    targetBox.imageFile = File(pickedFile.path);
    targetBox.imagePath = pickedFile.path;

    _selectedBox = targetBox;
    notifyListeners();
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
