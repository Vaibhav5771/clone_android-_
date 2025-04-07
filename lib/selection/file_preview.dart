import 'dart:io';
import 'package:clone_android/selection/preference_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/file_state.dart';

class FilePreviewScreen extends StatelessWidget {
  final File file; // Add file parameter
  final String fileType; // Add fileType parameter
  final String receiverId; // Add receiverId parameter

  const FilePreviewScreen({
    required this.file,
    required this.fileType,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FileAttachmentProvider>(context);
    provider.setFile(file, fileType); // Set file in provider

    if (file == null) {
      return Scaffold(body: Center(child: Text('No file selected')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreferencesFormScreen(receiverId: receiverId),
                ),
              );
            },
          ),
        ],
      ),
      body: fileType == 'pdf' ? PDFView(filePath: file.path) : Image.file(file),
    );
  }
}