import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/file_state.dart';
import '../auth_state.dart';
import 'package:path/path.dart' as path;
 // Import ConversationPage

class PreferencesFormScreen extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;
  final String receiverAvatarUrl;

  const PreferencesFormScreen({
    Key? key,
    required this.receiverId,
    required this.receiverUsername,
    required this.receiverAvatarUrl,
  }) : super(key: key);

  @override
  _PreferencesFormScreenState createState() => _PreferencesFormScreenState();
}

class _PreferencesFormScreenState extends State<PreferencesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _copiesGroupValue = 1;
  TextEditingController _customCopiesController = TextEditingController();
  bool _isColor = false;
  int _selectedPaperSize = 1;
  int _selectedSides = 1;

  @override
  void dispose() {
    _customCopiesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
      final preferences = {
        'copies': _copiesGroupValue == 1 && _customCopiesController.text.isNotEmpty
            ? int.tryParse(_customCopiesController.text) ?? 1
            : _copiesGroupValue,
        'isColor': _isColor,
        'paperSize': _selectedPaperSize == 1
            ? 'A4'
            : _selectedPaperSize == 2
            ? 'A3'
            : _selectedPaperSize == 3
            ? 'Legal'
            : 'Letter',
        'sides': _selectedSides == 1
            ? 'Front'
            : _selectedSides == 2
            ? 'Both'
            : _selectedSides == 3
            ? 'Even'
            : 'Odd',
        if (provider.fileType == 'pdf') ...{
          'startPage': provider.startPage,
          'endPage': provider.endPage,
        },
      };
      provider.setPreferences(preferences);
      await _uploadFile(context);
    }
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
      final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
      if (provider.selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }
      File file = provider.selectedFile!;
      final prefs = provider.preferences;
      final fileType = provider.fileType;
      final authState = Provider.of<AuthState>(context, listen: false);
      final senderID = authState.uid!;
      final fileName = path.basename(file.path);

      List<String> ids = [senderID, widget.receiverId];
      ids.sort();
      String chatRoomID = ids.join('_');

      String storageFileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('chat_files/$storageFileName');
      UploadTask uploadTask = storageRef.putFile(file);

      // Show professional loading dialog
      double? progress;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uploading File',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress != null ? progress! / 100 : null,
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        backgroundColor: Colors.grey[700],
                      ),
                    ),
                    if (progress != null)
                      Text(
                        '${progress!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder<TaskSnapshot>(
                  stream: uploadTask.snapshotEvents,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final snap = snapshot.data!;
                      progress = (snap.bytesTransferred / snap.totalBytes) * 100;
                      return Text(
                        progress != null
                            ? 'Progress: ${progress!.toStringAsFixed(1)}%'
                            : 'Preparing upload...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    }
                    return Text(
                      'Preparing upload...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Please wait while your file is being uploaded.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .add({
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'preferences': prefs,
        'senderID': senderID,
        'receiverID': widget.receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': fileType,
        'senderEmail': authState.email ?? '',
      });

      await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomID).set({
        'participants': [senderID, widget.receiverId],
        'lastMessage': 'File sent',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.of(context).pop(); // Close the loading dialog

      provider.reset();

      // Navigate back to ConversationPage
      Navigator.pop(context); // Pop PreferencesFormScreen
      Navigator.pop(context); // Pop FilePreviewScreen
    } catch (e, stackTrace) {
      Navigator.of(context).pop(); // Close the loading dialog on error
      print('Upload error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
    final isPdf = provider.fileType == 'pdf';
    final startPage = isPdf ? provider.startPage : null;
    final endPage = isPdf ? provider.endPage : null;
    final fileName = isPdf && provider.selectedFile != null
        ? path.basename(provider.selectedFile!.path)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
          'Set Preferences',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPdf) ...[
                  if (fileName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Selected Pages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Page',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'e.g., 1',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  enabled: false,
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                controller: TextEditingController(text: startPage.toString()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Page',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'e.g., 10',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  enabled: false,
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                controller: TextEditingController(text: endPage.toString()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                buildCopiesField(),
                const SizedBox(height: 16),
                buildColorSchemeField(),
                const SizedBox(height: 16),
                buildPaperSizeField(),
                const SizedBox(height: 16),
                buildSidesField(),
                const SizedBox(height: 20),
                buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCopiesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "No. of Copies",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Radio<int>(
                  value: 1,
                  groupValue: _copiesGroupValue,
                  onChanged: (value) {
                    setState(() {
                      _copiesGroupValue = value!;
                      _customCopiesController.clear();
                    });
                  },
                  activeColor: Colors.blue,
                  fillColor: MaterialStateProperty.all(Colors.white),
                ),
                Text("1", style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<int>(
                  value: 2,
                  groupValue: _copiesGroupValue,
                  onChanged: (value) {
                    setState(() {
                      _copiesGroupValue = value!;
                      _customCopiesController.clear();
                    });
                  },
                  activeColor: Colors.blue,
                  fillColor: MaterialStateProperty.all(Colors.white),
                ),
                Text("2", style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            Container(
              width: 100,
              child: TextFormField(
                controller: _customCopiesController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Custom',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (value) {
                  setState(() {
                    _copiesGroupValue = int.tryParse(value) ?? _copiesGroupValue;
                  });
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue <= 0) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildColorSchemeField() {
    return Column(
      children: [
        Center(
          child: Text(
            "Color Scheme",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "B & W",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Switch(
              value: _isColor,
              onChanged: (value) {
                setState(() {
                  _isColor = value;
                });
              },
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[700],
            ),
            Text(
              "Color",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPaperSizeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Paper Size",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildRadioOption("A4", 1),
              const SizedBox(width: 16),
              buildRadioOption("A3", 2),
              const SizedBox(width: 16),
              buildRadioOption("Legal", 3),
              const SizedBox(width: 16),
              buildRadioOption("Letter", 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRadioOption(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<int>(
          value: value,
          groupValue: _selectedPaperSize,
          onChanged: (newValue) {
            setState(() {
              _selectedPaperSize = newValue!;
            });
          },
          activeColor: Colors.blue,
          fillColor: MaterialStateProperty.all(Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }

  Widget buildSidesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Sides",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildRadioOptionSides("Front", 1),
              const SizedBox(width: 16),
              buildRadioOptionSides("Both", 2),
              const SizedBox(width: 16),
              buildRadioOptionSides("Even", 3),
              const SizedBox(width: 16),
              buildRadioOptionSides("Odd", 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRadioOptionSides(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<int>(
          value: value,
          groupValue: _selectedSides,
          onChanged: (newValue) {
            setState(() {
              _selectedSides = newValue!;
            });
          },
          activeColor: Colors.blue,
          fillColor: MaterialStateProperty.all(Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }

  Widget buildActionButtons() {
    return Center(
      child: MaterialButton(
        onPressed: () => _submitForm(context),
        color: Colors.blue,
        textColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "Send",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}