import 'package:chats/pages/view_pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PickFile extends StatefulWidget {
  final String receiverID;
  final String receiverEmail;
  final String chatRoomID;

  const PickFile({
    super.key,
    required this.receiverID,
    required this.receiverEmail,
    required this.chatRoomID,
  });

  @override
  State<PickFile> createState() => _PickFileState();
}

class _PickFileState extends State<PickFile> {
  File? file;
  String fileName = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(
        widget.chatRoomID);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload File"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                height: 60,
                color: Colors.blueAccent,
                onPressed: getFile,
                child: const Text(
                  "Select File",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              file != null
                  ? Text("Selected File: $fileName")
                  : const Text("No file selected"),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: file != null ? uploadFile : null,
                child: const Text("Upload & Send"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          file = File(result.files.single.path!);
          fileName = result.files.single.name;
        });

        Fluttertoast.showToast(
          msg: "File selected: $fileName",
          textColor: Colors.white,
          backgroundColor: Colors.blue,
        );
      } else {
        Fluttertoast.showToast(
          msg: "No file selected",
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error selecting file: $e",
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> uploadFile() async {
    if (file == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Chat room reference
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms')
          .doc(widget.chatRoomID);

      // Check if the chat room exists
      // Ensure the chat room exists or create it
      final docSnapshot = await chatRoomRef.get();
      if (!docSnapshot.exists) {
        await chatRoomRef.set({
          'createdBy': FirebaseAuth.instance.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      return;
      }

      // File path in Firebase Storage
      String filePath = 'uploads/${widget.receiverID}/$fileName';
      Reference storageRef = FirebaseStorage.instance.ref(filePath);

      // Upload the file to Firebase Storage
      await storageRef.putFile(file!);

      // Get the download URL after successful upload
      String fileUrl = await storageRef.getDownloadURL();

      // Update Firestore with the file URL and other details
      await chatRoomRef.update({
        'preferencesPDFUrl': fileUrl, // Save the file URL
        'uploadedBy': widget.receiverID, // Optional for tracking
        'timestamp': FieldValue.serverTimestamp(), // For ordering
      });

      Fluttertoast.showToast(
        msg: "File uploaded successfully!",
        textColor: Colors.white,
        backgroundColor: Colors.green,
      );

      // Call your function to send the preferences data to Firebase
       // Passing the fileUrl to your function

      // Navigate to PDF Viewer screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            isPdf: fileName.endsWith('.pdf'),
            name: fileName,
            receiverID: widget.receiverID,
            chatRoomID: widget.chatRoomID,
            fileUrl: fileUrl,
          ),
        ),
      );
    } catch (e) {
      print("Upload Error: $e");
      Fluttertoast.showToast(
        msg: "Error uploading file: $e",
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
