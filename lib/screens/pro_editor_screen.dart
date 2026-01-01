
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_lib;
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:pdf_forge/core/providers/image_provider.dart';

// A simple class to represent a filter
class Filter {
  final String name;
  final img_lib.Image Function(img_lib.Image image) apply;

  Filter({required this.name, required this.apply});
}

class ProEditorScreen extends StatefulWidget {
  final int initialIndex;

  const ProEditorScreen({super.key, required this.initialIndex});

  @override
  State<ProEditorScreen> createState() => _ProEditorScreenState();
}

class _ProEditorScreenState extends State<ProEditorScreen> {
  late PageController _pageController;
  final Map<int, Uint8List> _editedImages = {};
  int _currentIndex = 0;

  // State for different editing modes
  bool _showRotationControls = false;
  double _currentRotationDegrees = 0;

  bool _showFilterControls = false;
  List<Uint8List>? _filterThumbnails;
  bool _isGeneratingThumbnails = false;

  bool _showAdjustControls = false;
  double _brightnessValue = 0.0; // Range: -100 to 100
  double _contrastValue = 1.0; // Range: 0.1 to 4.0

  final List<Filter> _filters = [
    Filter(name: 'Original', apply: (image) => image),
    Filter(name: 'Grayscale', apply: (image) => img_lib.grayscale(image)),
    Filter(name: 'Sepia', apply: (image) => img_lib.sepia(image, amount: 1)),
    Filter(name: 'Invert', apply: (image) => img_lib.invert(image)),
    Filter(name: 'Vignette', apply: (image) => img_lib.vignette(image, end: 0.8, amount: 0.7)),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final imageProvider = Provider.of<AppImageProvider>(context, listen: false);
    _editedImages.forEach((index, imageBytes) {
      imageProvider.updateImage(index, imageBytes);
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _resetControls() {
    setState(() {
      _showRotationControls = false;
      _showFilterControls = false;
      _showAdjustControls = false;
      _currentRotationDegrees = 0;
      _brightnessValue = 0.0;
      _contrastValue = 1.0;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _resetControls();
      _filterThumbnails = null;
    });
  }

  Uint8List? _getCurrentBytes() {
    final imageProvider = Provider.of<AppImageProvider>(context, listen: false);
    if (_currentIndex >= imageProvider.images.length) return null;
    return _editedImages[_currentIndex] ?? imageProvider.images[_currentIndex].imageBytes;
  }

  Future<String> _bytesToTempFile(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp();
    final file = await File('${tempDir.path}/image_to_process.jpg').create();
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _invalidateEdits() {
    // This will force thumbnails to be regenerated on next filter open
    _filterThumbnails = null;
  }

  Future<void> _cropImage() async {
    _resetControls();
    final bytes = _getCurrentBytes();
    if (bytes == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: await _bytesToTempFile(bytes),
      uiSettings: [ /* ... UI settings ... */ ],
    );

    if (croppedFile != null) {
      final croppedBytes = await croppedFile.readAsBytes();
      setState(() {
        _editedImages[_currentIndex] = croppedBytes;
        _invalidateEdits();
      });
    }
  }

  void _onRotateButtonPressed() {
    _resetControls();
    setState(() => _showRotationControls = true);
  }

  void _applyRotation() {
    final bytes = _getCurrentBytes();
    if (bytes == null) return;

    final imageToRotate = img_lib.decodeImage(bytes);
    if (imageToRotate == null) return;

    final rotatedImage = img_lib.copyRotate(imageToRotate, angle: _currentRotationDegrees);

    setState(() {
      _editedImages[_currentIndex] = Uint8List.fromList(img_lib.encodeJpg(rotatedImage));
      _invalidateEdits();
      _resetControls();
    });
  }

  Future<void> _onFilterButtonPressed() async {
    _resetControls();
    setState(() => _showFilterControls = true);
    if (_filterThumbnails == null) {
      await _generateFilterThumbnails();
    }
  }

  Future<void> _generateFilterThumbnails() async {
    setState(() => _isGeneratingThumbnails = true);
    final bytes = _getCurrentBytes();
    if (bytes == null) {
      setState(() => _isGeneratingThumbnails = false);
      return;
    }

    final originalImage = img_lib.decodeImage(bytes);
    if (originalImage == null) {
      setState(() => _isGeneratingThumbnails = false);
      return;
    }

    final thumbnailImage = img_lib.copyResize(originalImage, width: 100);
    final List<Uint8List> thumbnails = [];

    for (var filter in _filters) {
      final imageToFilter = img_lib.Image.from(thumbnailImage);
      final filteredThumb = filter.apply(imageToFilter);
      thumbnails.add(Uint8List.fromList(img_lib.encodeJpg(filteredThumb)));
    }

    setState(() {
      _filterThumbnails = thumbnails;
      _isGeneratingThumbnails = false;
    });
  }

  void _applyFilter(Filter filter) {
    final bytes = _getCurrentBytes();
    if (bytes == null) return;

    final imageToFilter = img_lib.decodeImage(bytes);
    if (imageToFilter == null) return;

    final filteredImage = filter.apply(imageToFilter);
    setState(() {
      _editedImages[_currentIndex] = Uint8List.fromList(img_lib.encodeJpg(filteredImage));
    });
  }

  void _onAdjustButtonPressed() {
    _resetControls();
    setState(() => _showAdjustControls = true);
  }

  void _applyAdjustments() {
    final bytes = _getCurrentBytes();
    if (bytes == null) return;

    final imageToAdjust = img_lib.decodeImage(bytes);
    if (imageToAdjust == null) return;

    img_lib.adjustColor(imageToAdjust, brightness: _brightnessValue + 1, contrast: _contrastValue);

    setState(() {
      _editedImages[_currentIndex] = Uint8List.fromList(img_lib.encodeJpg(imageToAdjust));
      _invalidateEdits();
      _resetControls();
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<AppImageProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Editor'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          )
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imageProvider.images.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final key = ValueKey('${index}_${_editedImages[index]?.hashCode}');
              final bytes = _editedImages[index] ?? imageProvider.images[index].imageBytes;
              
              Widget imageWidget = Image.memory(bytes, key: key, fit: BoxFit.contain);

              if (_showAdjustControls && index == _currentIndex) {
                final double brightness = _brightnessValue / 255.0;
                final double contrast = _contrastValue;
                
                imageWidget = ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    contrast, 0, 0, 0, brightness * 255,
                    0, contrast, 0, 0, brightness * 255,
                    0, 0, contrast, 0, brightness * 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: imageWidget,
                );
              }

              return Center(
                child: InteractiveViewer(
                  child: Transform.rotate(
                    angle: _showRotationControls && index == _currentIndex
                        ? _currentRotationDegrees * (math.pi / 180)
                        : 0,
                    child: imageWidget,
                  ),
                ),
              );
            },
          ),
          if (_showRotationControls) _buildRotationControls(),
          if (_showFilterControls) _buildFilterControls(),
          if (_showAdjustControls) _buildAdjustControls(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToolbarButton(Icons.crop, 'Crop', _cropImage),
            _buildToolbarButton(Icons.rotate_90_degrees_ccw, 'Rotate', _onRotateButtonPressed),
            _buildToolbarButton(Icons.filter, 'Filters', _onFilterButtonPressed),
            _buildToolbarButton(Icons.tune, 'Adjust', _onAdjustButtonPressed),
          ],
        ),
      ),
    );
  }

  Widget _buildRotationControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.8),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_currentRotationDegrees.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Slider(value: _currentRotationDegrees, min: -45.0, max: 45.0, divisions: 90, activeColor: Colors.deepPurple, inactiveColor: Colors.grey, onChanged: (value) => setState(() => _currentRotationDegrees = value)),
            ElevatedButton(onPressed: _applyRotation, child: const Text('Apply Rotation'))
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 140,
        color: const Color.fromRGBO(0, 0, 0, 0.8),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: _isGeneratingThumbnails
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final thumbnailBytes = _filterThumbnails?[index];
                  if (thumbnailBytes == null) return const CircleAvatar(radius: 40, backgroundColor: Colors.grey);
                  return GestureDetector(
                    onTap: () => _applyFilter(filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(radius: 40, backgroundImage: MemoryImage(thumbnailBytes)),
                          const SizedBox(height: 8),
                          Text(filter.name, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAdjustControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSliderRow(label: 'Brightness', value: _brightnessValue, min: -100, max: 100, onChanged: (val) => setState(() => _brightnessValue = val)),
            _buildSliderRow(label: 'Contrast', value: _contrastValue, min: 0.1, max: 4.0, onChanged: (val) => setState(() => _contrastValue = val)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _applyAdjustments, child: const Text('Apply Adjustments')),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white))),
        Expanded(
          child: Slider(value: value, min: min, max: max, divisions: (max - min).toInt() * (label == 'Contrast' ? 10 : 1), activeColor: Colors.deepPurple, inactiveColor: Colors.grey, onChanged: onChanged),
        ),
        SizedBox(width: 40, child: Text(label == 'Contrast' ? value.toStringAsFixed(1) : value.toStringAsFixed(0), style: const TextStyle(color: Colors.white), textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      tooltip: label,
    );
  }
}
