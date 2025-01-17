import 'package:chats/pages/preference_preview.dart';
import 'package:chats/services/auth_service.dart';
import 'package:chats/services/chat_services.dart';
import 'package:chats/widgets/chat_bubble.dart';
import 'package:chats/widgets/login_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/pick_file.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String chatRoomID;



  ChatPage({super.key, required this.receiverEmail, required this.receiverID, required this.chatRoomID});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // Use the passed chatRoomID from HomePage
      await _chatService.sendMessage(widget.receiverID, _messageController.text);

      // Clear the message input
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages yet. Start the conversation!"));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;
    bool isPreference = data['messageType'] == 'preferences';  // Check if the message is of type 'preferences'

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    if (isPreference) {
      // If the message is a preference, display the preferences bubble
      return Container(
        alignment: alignment,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: GestureDetector(
          onTap: () {
            // Retrieve the preferences data from the Firestore document
            Map<String, dynamic> preferencesData = data['preferences'] ?? {};

            // Retrieve the fileUrl from the top-level fields, not from preferences
            String fileUrl = data['fileUrl'] ?? 'No file URL available';

            // Display the preferences information (Here, I'm showing it as a toast)
            Fluttertoast.showToast(
              msg: "Preferences Data: ${preferencesData.toString()}",
              textColor: Colors.white,
              backgroundColor: Colors.blue,
            );

            // Navigate to the PreferencesScreen, passing the preferences data and fileUrl
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreferencesScreen(
                  preferencesData: preferencesData,
                  fileUrl: fileUrl, // Pass the fileUrl here
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              width: 80,  // Size of the bubble
              height: 50, // Size of the bubble
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,  // Center the content inside the bubble
                children: [
                  Icon(
                    Icons.settings,  // Icon for preferences (you can customize this)
                    color: Colors.white,
                  ),
                  Positioned(
                    bottom: 5,  // Position the text slightly lower
                    child: Text(
                      "Preference",  // Text to show inside the bubble
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,  // Adjust the size of the text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Regular message bubble
      return Container(
        alignment: alignment,
        child: ChatBubble(
          message: data["message"],
          isCurrentUser: isCurrentUser,
        ),
      );
    }
  }



  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            child: LoginField(
              hintText: "Type a Message",
              obscureText: false,
              controller: _messageController,
            ),
          ),
          SizedBox(width: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: sendMessage,
              icon: Icon(Icons.send_sharp),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () {
                // Check if chatRoomID is empty before navigating
                if (widget.chatRoomID.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "Chat Room ID is empty!",
                    textColor: Colors.white,
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                // Navigate to PickFile screen if chatRoomID is not empty
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PickFile(
                      receiverID: widget.receiverID,
                      receiverEmail: widget.receiverEmail,
                      chatRoomID: widget.chatRoomID, // Pass it properly
                    ),
                  ),
                );
              },
              icon: Icon(Icons.file_present_sharp),
            ),
          ),
        ],
      ),
    );
  }
}
