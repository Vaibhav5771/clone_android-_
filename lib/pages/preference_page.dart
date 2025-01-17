import 'package:chats/pages/view_pdf.dart';
import 'package:chats/pages/view_pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class PreferencesPanel extends StatefulWidget {
  final int startPage;
  final int endPage;
  final String receiverID;
  final String chatRoomID;
  final String  preferencePDFUrl;

  PreferencesPanel({
    Key? key,
    required this.startPage,
    required this.endPage, required this.receiverID, required this.chatRoomID, required this.preferencePDFUrl,
  }) : super(key: key);

  final AuthService _authService = AuthService();


  @override
  _PreferencesPanelState createState() => _PreferencesPanelState();
}


class _PreferencesPanelState extends State<PreferencesPanel> {

  int _copiesGroupValue = 1; // Default value (1 copy)
  TextEditingController _customCopiesController = TextEditingController();
  bool _isColor = false; // Default value for color scheme (B & W)
  int _selectedPaperSize = 1;
  int _selectedSides = 1;


  // Assuming preferencesPDFUrl is passed as a parameter or obtained elsewhere
  Future<void> _sendDataToFirebase(String preferencesPDFUrl) async {
    // Debugging: Check if the PDF URL is null or empty
    print("PDF URL: $preferencesPDFUrl");

    if (preferencesPDFUrl.isEmpty) {
      // Handle the case when the URL is not set.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF URL is empty!"),
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> preferencesData = {
        'startPage': widget.startPage,
        'endPage': widget.endPage,
        'copies': _copiesGroupValue == 1
            ? (_customCopiesController.text.isEmpty
            ? 1
            : int.tryParse(_customCopiesController.text) ?? 1)
            : _copiesGroupValue,
        'isColor': _isColor,
        'paperSize': _selectedPaperSize,
        'sides': _selectedSides,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final chatRoomRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomID);

      await chatRoomRef.collection('messages').add({
        'senderID': FirebaseAuth.instance.currentUser!.uid,
        'receiverID': widget.receiverID,
        'messageType': 'preferences',
        'message': '',
        'fileUrl': widget.preferencePDFUrl, // Ensure this is not empty
        'fileName': '',
        'preferences': preferencesData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Preferences sent successfully!")),
      );

      Navigator.pop(context, preferencesData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send preferences: $e")),
      );
    }
  }





  @override
  void dispose() {
    _customCopiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preferences Panel"),
      ),
      body: SingleChildScrollView(  // Moved here inside a constrained container
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height, // Prevent infinite height
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCopiesField(),
                Divider(color: Colors.grey),
                buildColorSchemeField(),
                Divider(color: Colors.grey),
                buildPaperSizeField(),
                Divider(color: Colors.grey),
                buildSidesField(),
                Divider(color: Colors.grey),
                SizedBox(height: 20),
                buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget buildCopiesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "No. of Copies",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Radio button for 1 copy
              Radio<int>(
                value: 1,
                groupValue: _copiesGroupValue,
                onChanged: (value) {
                  setState(() {
                    _copiesGroupValue = value!;
                    _customCopiesController.clear(); // Clear custom field
                  });
                },
                activeColor: Colors.black,
              ),
              Text("1", style: TextStyle(color: Colors.black, fontSize: 18)),

              // Radio button for 2 copies
              Radio<int>(
                value: 2,
                groupValue: _copiesGroupValue,
                onChanged: (value) {
                  setState(() {
                    _copiesGroupValue = value!;
                    _customCopiesController.clear(); // Clear custom field
                  });
                },
                activeColor: Colors.black,
              ),
              Text("2", style: TextStyle(color: Colors.black, fontSize: 18)),

              // TextField for custom number of copies
              Container(
                width: 80,
                child: TextField(
                  controller: _customCopiesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Custom',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _copiesGroupValue =
                          int.tryParse(value) ?? _copiesGroupValue;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildColorSchemeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Center(
            child: Text(
              "Color Scheme",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "B & W",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              Switch(
                value: _isColor,
                onChanged: (value) {
                  setState(() {
                    _isColor = value;
                  });
                },
                activeColor: Colors.black,
                inactiveThumbColor: Colors.grey,
              ),
              Text(
                "Color",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPaperSizeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Paper Size",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildRadioOption1("A4", 1),
                SizedBox(width: 8),
                buildRadioOption1("A3", 2),
                SizedBox(width: 8),
                buildRadioOption1("Legal", 3),
                SizedBox(width: 8),
                buildRadioOption1("Letter", 4),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget buildRadioOption1(String label, int value) {
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
          activeColor: Colors.black,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

  Widget buildSidesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Sides",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildRadioOptionSides("Front", 1),
                SizedBox(width: 5),
                buildRadioOptionSides("Both", 2),
                SizedBox(width: 5),
                buildRadioOptionSides("Even", 3),
                SizedBox(width: 5),
                buildRadioOptionSides("Odd", 4),
              ],
            ),
          ),
        ],
      ),
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
          activeColor: Colors.black,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }


  Widget buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Send Button
        Center(
          child: MaterialButton(
            onPressed: () {
              _sendDataToFirebase(widget.preferencePDFUrl);
            },
            color: Colors.blue,
            textColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 45, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "Send",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
