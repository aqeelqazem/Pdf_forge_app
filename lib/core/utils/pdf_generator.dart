
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:pdf_forge/core/providers/image_provider.dart';

const String historyKey = 'pdf_history';

Future<void> generateAndSavePdf(
  BuildContext context,
  List<Uint8List> imageBytesList, 
  PdfPageFormat pageFormat
) async {
  // Get the provider before any async operations.
  final imageProvider = Provider.of<AppImageProvider>(context, listen: false);

  final pdf = pw.Document();

  for (var imageBytes in imageBytesList) {
    final image = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );
  }

  final outputDir = await getTemporaryDirectory();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File('${outputDir.path}/images_to_pdf_$timestamp.pdf');

  await file.writeAsBytes(await pdf.save());

  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList(historyKey) ?? [];
  history.add(file.path);
  await prefs.setStringList(historyKey, history);

  final xFile = XFile(file.path);
  await Share.shareXFiles([xFile], text: 'Here is your PDF document.');

  // Now it's safe to use the provider to clear images.
  await imageProvider.clearAllImages();
}

Future<List<String>> getPdfHistory() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(historyKey) ?? [];
}

Future<void> removeFromHistory(String filePath) async {
  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList(historyKey) ?? [];

  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }

  history.remove(filePath);
  await prefs.setStringList(historyKey, history);
}
