import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/file_state.dart';
import 'preference_form.dart'; // Path to PreferencesFormScreen

class FilePreviewScreen extends StatefulWidget {
  final File file;
  final String fileType;
  final String receiverId;
  final String receiverUsername;
  final String receiverAvatarUrl;

  const FilePreviewScreen({
    Key? key,
    required this.file,
    required this.fileType,
    required this.receiverId,
    required this.receiverUsername,
    required this.receiverAvatarUrl,
  }) : super(key: key);

  @override
  _FilePreviewScreenState createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _startPageController = TextEditingController();
  final TextEditingController _endPageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int currentPage = 0; // Zero-based index from PDFView
  int totalPages = 1; // Default to 1 page until updated

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
    provider.setFile(widget.file, widget.fileType);
    print("Provider state - File: ${provider.selectedFile?.path}, Type: ${provider.fileType}");

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _savePageSelection(BuildContext context) {
    final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
    final startPage = int.tryParse(_startPageController.text) ?? 1;
    final endPage = int.tryParse(_endPageController.text) ?? 1;
    provider.setPageRange(startPage, endPage);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreferencesFormScreen(
          receiverId: widget.receiverId,
          receiverUsername: widget.receiverUsername,
          receiverAvatarUrl: widget.receiverAvatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("FilePreviewScreen - File path: ${widget.file.path}, Type: ${widget.fileType}");
    if (widget.file == null || !widget.file.existsSync()) {
      print("Error: File is null or does not exist at ${widget.file.path}");
      return Scaffold(
        body: Center(
          child: Text(
            'No file selected or file not found',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        backgroundColor: Colors.black,
      );
    }
    print("File exists, attempting to display: ${widget.file.path}");

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF62C3F4), Color(0xFF0469C4)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'File Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => _savePageSelection(context),
            tooltip: 'Next',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.black,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: widget.fileType == 'pdf'
                            ? PDFView(
                          filePath: widget.file.path,
                          onPageChanged: (page, total) {
                            setState(() {
                              currentPage = page ?? 0;
                              totalPages = total ?? 1;
                            });
                            print("Page changed: ${currentPage + 1}/$totalPages");
                          },
                          onRender: (pages) {
                            setState(() {
                              totalPages = pages ?? 1;
                            });
                            print("PDF rendered, total pages: $totalPages");
                          },
                        )
                            : Image.file(
                          widget.file,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.fileType == 'pdf' ? '${currentPage + 1}/$totalPages' : '1/1',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.fileType == 'pdf')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startPageController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Start Page',
                          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[700],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endPageController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'End Page',
                          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[700],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _savePageSelection(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF62C3F4), Color(0xFF0469C4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}