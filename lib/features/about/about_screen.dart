import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _generateAndShareBlueprintPdf(BuildContext context) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Read the markdown file
      final String blueprintContent = await rootBundle.loadString('blueprint.md');

      // Create a PDF document
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Text(blueprintContent),
            );
          },
        ),
      );

      // Save the PDF to a temporary file
      final outputDir = await getTemporaryDirectory();
      final file = File('${outputDir.path}/project_blueprint.pdf');
      await file.writeAsBytes(await pdf.save());

      // IMPORTANT: Check if the widget is still mounted before using context
      if (!context.mounted) return;

      // Close the loading indicator
      Navigator.of(context).pop();

      // Share the file
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Here is the project blueprint.');

    } catch (e) {
      // IMPORTANT: Check if the widget is still mounted before using context
      if (!context.mounted) return;

      // Close the loading indicator in case of error
      Navigator.of(context).pop();

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About PDF Forge'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/logo/app_logo.svg',
                height: 120,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white : theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PDF Forge',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Effortlessly convert your images into high-quality, professional PDF documents. Built with Flutter.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),

              // Temporary Export Button
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export Blueprint as PDF'),
                onPressed: () => _generateAndShareBlueprintPdf(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 50),
                ),
              ),
              const SizedBox(height: 12),

              // View Source Code Button
              ElevatedButton.icon(
                icon: const Icon(Icons.code),
                label: const Text('View Source Code'),
                onPressed: () => _launchUrl(Uri.parse('https://github.com/baseflow/flutter-permission-handler')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 50),
                ),
              ),
              const SizedBox(height: 12),

              // Disabled License Button
              ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View License'),
                onPressed: null, // This disables the button
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 50),
                ),
              ),

              const SizedBox(height: 60),
              Text(
                'Made with ❤️ using Flutter',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
