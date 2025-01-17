import 'package:chats/pages/preference_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/chat_services.dart';


class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String receiverID;
  final String chatRoomID;
  final String name;
  final bool isPdf;


   PDFViewerScreen({
    Key? key,
    required this.fileUrl,
    required this.name,
    required this.isPdf, required this.receiverID, required this.chatRoomID,

  }) : super(key: key);

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int startPage = 0; // Example value for startPage
  int endPage = 0;
  bool isLoading = false;
  String localFilePath = '';

  // New variables for start and end page
  TextEditingController startPageController = TextEditingController();
  TextEditingController endPageController = TextEditingController();


  @override
  void initState() {
    super.initState();
    downloadPDF();
  }

  Future<void> downloadPDF() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the reference to the file in Firebase Storage
      Reference ref = FirebaseStorage.instance.refFromURL(widget.fileUrl);

      // Get the directory for saving files
      final directory = await getApplicationDocumentsDirectory();
      String localPath = '${directory.path}/${widget.fileUrl.split('/').last}';

      // Download the file to the device's local storage
      await ref.writeToFile(File(localPath));

      setState(() {
        localFilePath = localPath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error downloading file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
      ),
      body: Stack(
        children: [
          // Check if the file exists before showing PDF view
          if (localFilePath.isNotEmpty && File(localFilePath).existsSync())
            PDFView(
              filePath: localFilePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onError: (error) {
                print("PDF Viewer Error: $error");
              },
              onPageError: (page, error) {
                print("Error on page $page: $error");
              },
            )
          else
            const Center(child: Text('File not found')),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: MediaQuery
            .of(context)
            .viewInsets + const EdgeInsets.all(10.0),
        // Adjust for keyboard visibility
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Distribute space evenly
          children: [
            // Start Page TextField (right-aligned)
            Expanded(
              child: TextField(
                controller: startPageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Start Page',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // End Page TextField
            Expanded(
              child: TextField(
                controller: endPageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'End Page',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Upload Button
            ElevatedButton(
              onPressed: () {
                // Navigate to the PreferencesPanel page and replace the current screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreferencesPanel(
                      startPage: startPageController.text.isNotEmpty
                          ? int.tryParse(startPageController.text) ?? 1
                          : 1, // Default to 1 if input is empty or invalid
                      endPage: endPageController.text.isNotEmpty
                          ? int.tryParse(endPageController.text) ?? 10
                          : 10, // Default to 10 if input is empty or invalid
                      receiverID: widget.receiverID,
                      chatRoomID: widget.chatRoomID, preferencePDFUrl: widget.fileUrl,
                    ),
                  ),
                );
              },
              child: const Text('Next'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),

          ],
        ),
      ),
    );
  }
}