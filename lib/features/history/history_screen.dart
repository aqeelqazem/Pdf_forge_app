import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/pdf_generator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<String>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = getPdfHistory();
    });
  }

  String _formatFileName(String path) {
    return path.split('/').last;
  }

  String _getCreationDate(String path) {
    final file = File(path);
    try {
      final stat = file.statSync();
      return DateFormat('MMM d, yyyy HH:mm').format(stat.modified);
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showDeleteConfirmation(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this PDF file permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Grab the navigator before the await call
              final navigator = Navigator.of(ctx);
              await removeFromHistory(filePath);
              if (mounted) {
                navigator.pop();
                _loadHistory(); // Refresh the list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Files'),
      ),
      body: FutureBuilder<List<String>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No saved PDFs found.\nCreate a new PDF to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final filePath = history[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  title: Text(
                    _formatFileName(filePath),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_getCreationDate(filePath)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          final xFile = XFile(filePath);
                          Share.shareXFiles([xFile], text: 'My PDF File');
                        },
                        tooltip: 'Share PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmation(filePath),
                        tooltip: 'Delete PDF',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
