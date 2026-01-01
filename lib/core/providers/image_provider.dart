
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf_forge/core/models/editable_image.dart';
import 'package:pdf_forge/core/services/session_service.dart';

class AppImageProvider with ChangeNotifier {
  final List<EditableImage> _images = [];
  final ImagePicker _picker = ImagePicker();
  final SessionService _sessionService = SessionService();

  List<EditableImage> get images => _images;

  AppImageProvider() {
    // Load the session when the provider is initialized.
    loadSession();
  }

  Future<void> loadSession() async {
    final loadedImages = await _sessionService.loadSession();
    _images.clear();
    _images.addAll(loadedImages);
    notifyListeners();
  }

  Future<void> pickImages(ImageSource source) async {
    final List<XFile> pickedFiles = source == ImageSource.gallery
        ? await _picker.pickMultiImage()
        : [await _picker.pickImage(source: source)].whereType<XFile>().toList();

    for (var file in pickedFiles) {
      final bytes = await file.readAsBytes();
      final image = EditableImage(imageBytes: bytes);
       _images.add(image);
    }
    await _sessionService.saveSession(_images);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _images.removeAt(oldIndex);
    _images.insert(newIndex, item);
    _sessionService.saveSession(_images);
    notifyListeners();
  }

  void updateImage(int index, Uint8List newImageBytes) {
    if (index >= 0 && index < _images.length) {
      _images[index].imageBytes = newImageBytes;
      _sessionService.saveSession(_images);
      notifyListeners();
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _sessionService.saveSession(_images);
      notifyListeners();
    }
  }

  void addImage(Uint8List imageBytes) {
    final image = EditableImage(imageBytes: imageBytes);
    _images.add(image);
    _sessionService.saveSession(_images);
    notifyListeners();
  }

  Future<void> clearAllImages() async {
    _images.clear();
    await _sessionService.clearSession();
    notifyListeners();
  }
}
