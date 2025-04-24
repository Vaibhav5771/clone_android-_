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
      print("Checking photos permission");
      PermissionStatus status = await Permission.photos.status;
      print("Current photos permission status: $status");
      if (!status.isGranted) {
        print("Requesting photos permission");
        status = await Permission.photos.request();
        print("Requested photos permission, new status: $status");
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            print("Photos permission permanently denied");
            await openAppSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please enable photos permission in settings.")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Photos permission denied.")),
            );
          }
          return null;
        }
      }
      print("Launching image picker");
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        print("Image selected: ${image.path}");
        return File(image.path);
      } else {
        print("No image selected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected.")),
        );
        return null;
      }
    } else if (type == 'pdf') {
      print("Launching file picker for PDF without permission check");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        print("PDF selected: $filePath");
        return File(filePath);
      } else {
        print("No PDF selected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No PDF selected.")),
        );
        return null;
      }
    }
    print("Unsupported type: $type");
    return null;
  } catch (e) {
    print("Error in pickFile ($type): $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error picking $type: $e")),
    );
    return null;
  }
}
// Helper function
Future<bool> _isAndroid11OrHigher() async {
  if (!Platform.isAndroid) return false;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.version.sdkInt >= 30; // API 30 is Android 11
}