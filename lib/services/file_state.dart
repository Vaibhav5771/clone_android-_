import 'dart:io';
import 'package:flutter/material.dart';

class FileAttachmentProvider extends ChangeNotifier {
  File? selectedFile;
  String fileType = ''; // 'image' or 'pdf'
  Map<String, dynamic> preferences = {
    'copies': 1,
    'colorScheme': 'Color',
    'orientation': 'Portrait',
  };

  void setFile(File file, String type) {
    selectedFile = file;
    fileType = type;
    notifyListeners();
  }

  void setPreferences(Map<String, dynamic> prefs) {
    preferences = prefs;
    notifyListeners();
  }

  void reset() {
    selectedFile = null;
    fileType = '';
    preferences = {
      'copies': 1,
      'colorScheme': 'Color',
      'orientation': 'Portrait',
    };
    notifyListeners();
  }
}