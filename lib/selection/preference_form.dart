import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/file_state.dart';
import '../auth_state.dart';

class PreferencesFormScreen extends StatefulWidget {
  final String receiverId;

  const PreferencesFormScreen({required this.receiverId});

  @override
  _PreferencesFormScreenState createState() => _PreferencesFormScreenState();
}

class _PreferencesFormScreenState extends State<PreferencesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int copies = 1;
  String colorScheme = 'Color';
  String orientation = 'Portrait';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Preferences')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Number of Copies'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) => value!.isEmpty ? 'Enter a number' : null,
                onSaved: (value) => copies = int.parse(value!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Color Scheme'),
                value: colorScheme,
                items: ['Color', 'Black & White']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => colorScheme = value!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Orientation'),
                value: orientation,
                items: ['Portrait', 'Landscape']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => orientation = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitForm(context),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
      provider.setPreferences({
        'copies': copies,
        'colorScheme': colorScheme,
        'orientation': orientation,
      });
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

      // Generate chatRoomID consistent with ChatState
      List<String> ids = [senderID, widget.receiverId];
      ids.sort(); // Sort alphabetically
      String chatRoomID = ids.join('_');

      // Upload file to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('chat_files/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save to the same chat room structure as text messages
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .add({
        'fileUrl': downloadUrl,
        'preferences': prefs,
        'senderID': senderID, // Match ChatState
        'receiverID': widget.receiverId, // Match ChatState
        'timestamp': FieldValue.serverTimestamp(),
        'type': fileType,
        'senderEmail': authState.email ?? '', // Add for consistency
      });

      // Update chat room metadata (like sendMessage)
      await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomID).set({
        'participants': [senderID, widget.receiverId],
        'lastMessage': 'File sent', // Placeholder for file messages
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      provider.reset();
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
}