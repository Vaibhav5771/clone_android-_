import 'dart:io';
import 'package:flutter/material.dart';

class FileAttachmentProvider with ChangeNotifier {
  File? _selectedFile; // Renamed for consistency
  String _fileType = ''; // 'image' or 'pdf'
  int? _startPage; // From the first version
  int? _endPage; // From the first version
  Map<String, dynamic> _preferences = {
    'copies': 1,
    'colorScheme': 'Color',
    'orientation': 'Portrait',
  };

  // Getters
  File? get selectedFile => _selectedFile;
  String get fileType => _fileType;
  int? get startPage => _startPage;
  int? get endPage => _endPage;
  Map<String, dynamic> get preferences => _preferences;

  // Set file and type
  void setFile(File file, String type) {
    if (file.existsSync()) {
      _selectedFile = file;
      _fileType = type;
      _startPage = null;
      _endPage = null;
      notifyListeners();
      print("File set in provider: ${file.path}, Type: $type");
    } else {
      print("Error: File does not exist at ${file.path}");
    }
  }

  // Set page range for PDFs
  void setPageRange(int start, int end) {
    if (_fileType == 'pdf') { // Only set for PDFs
      _startPage = start;
      _endPage = end;
      notifyListeners();
    }
  }

  // Set preferences
  void setPreferences(Map<String, dynamic> prefs) {
    _preferences = prefs;
    notifyListeners();
  }


  // Reset all state
  void reset() {
    _selectedFile = null;
    _fileType = '';
    _startPage = null;
    _endPage = null;
    _preferences = {
      'copies': 1,
      'colorScheme': 'Color',
      'orientation': 'Portrait',
    };
    notifyListeners();
  }
}