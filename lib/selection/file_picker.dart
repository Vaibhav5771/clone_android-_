import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

Future<File?> pickFile(String type, BuildContext context) async {
  print("Starting pickFile for type: $type");
  try {
    if (type == 'image') {
      print("Preparing to launch image picker");
      final ImagePicker picker = ImagePicker();

      // Check and request photos permission
      PermissionStatus status = await Permission.photos.status;
      if (!status.isGranted) {
        print("Photos permission not granted, requesting...");
        status = await Permission.photos.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            print("Photos permission permanently denied, opening settings");
            await openAppSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please grant photos permission in settings to pick images."),
                duration: Duration(seconds: 3),
              ),
            );
            return null;
          }
          print("Photos permission denied: $status");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photos permission required to pick images."),
              duration: Duration(seconds: 3),
            ),
          );
          return null;
        }
      }

      print("Photos permission granted, launching image picker");
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, // Opens the gallery
        imageQuality: 80, // Reduces file size
      );

      if (image != null) {
        print("Selected image path: ${image.path}");
        return File(image.path);
      } else {
        print("No image selected or picker canceled");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected.")),
        );
        return null;
      }
    } else if (type == 'pdf') {
      print("Checking storage permission for PDF");
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted && await _isAndroid11OrHigher()) {
            status = await Permission.manageExternalStorage.request();
          }
        }
      } else {
        status = await Permission.storage.request();
      }
      print("Permission status after request: $status");
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          print("Storage permission permanently denied, opening settings");
          await openAppSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please grant storage permission in settings to pick PDFs."),
            ),
          );
          return null;
        }
        print("Storage permission denied: $status");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission required to pick PDFs.")),
        );
        return null;
      }
      print("Storage permission granted, launching file picker");

      print("Attempting to launch FilePicker with type: FileType.custom");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        dialogTitle: "Select a PDF",
      );
      print("File picker completed, result: $result");

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        print("Selected file path: $filePath");
        if (!filePath.toLowerCase().endsWith('.pdf')) {
          print("Selected file is not a PDF: $filePath");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a PDF file.")),
          );
          return null;
        }
        return File(filePath);
      } else {
        print("File picker returned null or empty result");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No PDF selected.")),
        );
        return null;
      }
    }
    print("Type not handled: $type");
    return null;
  } catch (e) {
    print("Error picking file ($type): $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error picking $type: $e")),
    );
    return null; // Return null instead of rethrowing to avoid unhandled exceptions
  }
}

// Helper function
Future<bool> _isAndroid11OrHigher() async {
  if (!Platform.isAndroid) return false;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.version.sdkInt >= 30; // API 30 is Android 11
}