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
      // Determine the appropriate permission based on Android version
      final isAndroid13OrHigher = await _isAndroid13OrHigher();
      Permission permission = isAndroid13OrHigher ? Permission.photos : Permission.storage;

      print("Checking permission: ${permission.toString()}");
      PermissionStatus status = await permission.status;
      print("Current permission status: $status");

      if (status.isGranted) {
        print("Permission already granted");
      } else if (status.isPermanentlyDenied) {
        print("Permission permanently denied, directing to settings");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Photo access is permanently denied. Please enable it in settings."),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                print("Opening app settings");
                await openAppSettings();
              },
            ),
          ),
        );
        return null;
      } else {
        print("Requesting permission: ${permission.toString()}");
        status = await permission.request();
        print("Requested permission, new status: $status");

        if (!status.isGranted) {
          print("Permission request denied: $status");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Photo access denied. Please grant permission to select images."),
              action: status.isPermanentlyDenied
                  ? SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  print("Opening app settings due to permanent denial");
                  await openAppSettings();
                },
              )
                  : null,
            ),
          );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unsupported file type: $type")),
    );
    return null;
  } catch (e, stackTrace) {
    print("Error in pickFile ($type): $e");
    print("Stack trace: $stackTrace");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error picking $type: $e")),
    );
    return null;
  }
}

// Helper function to check Android version
Future<bool> _isAndroid13OrHigher() async {
  if (!Platform.isAndroid) {
    print("Not an Android device");
    return false;
  }
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  print("Android SDK version: ${androidInfo.version.sdkInt}");
  return androidInfo.version.sdkInt >= 33; // API 33 is Android 13
}