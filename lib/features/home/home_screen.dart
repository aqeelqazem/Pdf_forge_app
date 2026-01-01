
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:pdf_forge/core/providers/image_provider.dart';
import 'package:pdf_forge/core/providers/theme_provider.dart';
import 'package:pdf_forge/core/utils/pdf_generator.dart';
import 'package:pdf_forge/screens/pro_editor_screen.dart';
import 'package:pdf_forge/features/about/about_screen.dart';
import 'package:pdf_forge/features/history/history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showPdfOptionsDialog(BuildContext context, AppImageProvider imageProvider) {
    PdfPageFormat pageFormat = PdfPageFormat.a4;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('PDF Options'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<PdfPageFormat>(
                    value: pageFormat,
                    items: [
                      const DropdownMenuItem(
                        value: PdfPageFormat.a4,
                        child: Text('Portrait (A4)'),
                      ),
                      DropdownMenuItem(
                        value: PdfPageFormat.a4.landscape,
                        child: const Text('Landscape (A4)'),
                      ),
                    ],
                    onChanged: (PdfPageFormat? newValue) {
                      if (newValue != null) {
                        setState(() {
                          pageFormat = newValue;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                generateAndSavePdf(
                  context,
                  imageProvider.images.map((e) => e.imageBytes).toList(),
                  pageFormat,
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<AppImageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Forge'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note), // Changed Icon
            tooltip: 'Edit Images', // Added tooltip
            onPressed: imageProvider.images.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProEditorScreen(initialIndex: 0),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
            ListTile(
              title: const Text('My Files'),
              leading: const Icon(Icons.folder),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('About'),
              leading: const Icon(Icons.info),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<AppImageProvider>(
        builder: (context, imageProvider, child) {
          if (imageProvider.images.isEmpty) {
            return Center(
              child: Text(
                'No images selected.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }
          return ReorderableGridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: imageProvider.images.length,
            itemBuilder: (context, index) {
              final image = imageProvider.images[index];
              return GestureDetector(
                key: ValueKey(image.id),
                onTap: () {
                  // Navigate to the editor screen, starting with the tapped image.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProEditorScreen(initialIndex: index),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    image.imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            onReorder: imageProvider.reorderImages,
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete all images',
              onPressed: imageProvider.images.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete all images?'),
                          content: const Text(
                              'Are you sure you want to delete all images?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                imageProvider.clearAllImages();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
            ),
            const SizedBox(), // Placeholder for the notch
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Convert to PDF',
              onPressed: imageProvider.images.isEmpty
                  ? null
                  : () => _showPdfOptionsDialog(context, imageProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take a picture'),
                      onTap: () {
                        imageProvider.pickImages(ImageSource.camera);
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Select from gallery'),
                      onTap: () {
                        imageProvider.pickImages(ImageSource.gallery);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
