import 'package:chats/services/auth_service.dart';
import 'package:chats/services/chat_services.dart';
import 'package:chats/widgets/my_drawer.dart';
import 'package:flutter/material.dart';

import '../widgets/user_tile.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  //  chat & auth service
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("Welcome To Homepage"),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      drawer: MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: widget._chatService.getUsersStream(),
      builder: (context, snapshot) {
        // error
        if (snapshot.hasError) {
          return const Text("Error");
        }
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    // display all users except current
    if(userData["email"] != widget._authService.getCurrentUser()!.email) {
      return UserTile(
        text: userData["email"],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                String currentUserID = widget._authService.getCurrentUser()!.uid;
                String receiverID = userData["uid"];

                // Generate chatRoomID using currentUserID and receiverID
                List<String> ids = [currentUserID, receiverID];
                ids.sort(); // Ensure uniqueness
                String chatRoomID = ids.join('_'); // Generate chatRoomID

                return ChatPage(
                  receiverEmail: userData["email"],
                  receiverID: receiverID,
                  chatRoomID: chatRoomID, // Pass the generated chatRoomID
                );
              },
            ),
          );
        },
      );
    }else {
      return Container();
    }
  }
}
