import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get stream of all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return {
          'uid': doc.id, // Add uid explicitly
          ...user,
        };
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add({
      'senderID': currentUserID,
      'senderEmail': currentUserEmail,
      'receiverID': receiverId,
      'message': message,
      'timestamp': timestamp,
    });

    // Update chat room metadata (optional for your old logic)
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'participants': [currentUserID, receiverId],
      'lastMessage': message,
      'lastMessageTime': timestamp,
    }, SetOptions(merge: true));
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}