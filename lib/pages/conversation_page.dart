import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_state.dart';
import '../selection/file_picker.dart';
import '../selection/file_preview.dart';
import '../services/chat_services.dart';
import 'package:intl/intl.dart';
import '../services/file_state.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ConversationPage extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;
  final String receiverAvatarUrl;

  const ConversationPage({
    Key? key,
    required this.receiverId,
    required this.receiverUsername,
    required this.receiverAvatarUrl,
  }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _textFieldFocus;

  @override
  void initState() {
    super.initState();
    _textFieldFocus = FocusNode();
    debugPrint('ConversationPage init: receiver=${widget.receiverUsername}, url=${widget.receiverAvatarUrl}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    debugPrint('ConversationPage disposing');
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  void _sendMessage(ChatState chatState, String senderId) {
    if (_messageController.text.trim().isNotEmpty) {
      debugPrint('Sending message to ${widget.receiverId}: ${_messageController.text.trim()}');
      chatState.sendMessage(widget.receiverId, _messageController.text.trim());
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      debugPrint('Scrolling to bottom of message list');
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndPreviewFile(String type) async {
    try {
      debugPrint("Calling pickFile for type: $type");
      File? file = await pickFile(type, context);
      debugPrint("Selected file path: ${file?.path}");
      if (file != null && file.existsSync()) {
        final provider = Provider.of<FileAttachmentProvider>(context, listen: false);
        provider.setFile(file, type);
        debugPrint("Navigating to FilePreviewScreen with file: ${file.path}");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FilePreviewScreen(
              file: file,
              fileType: type,
              receiverId: widget.receiverId,
              receiverUsername: widget.receiverUsername,
              receiverAvatarUrl: widget.receiverAvatarUrl,
            ),
          ),
        );
        debugPrint('Returned from FilePreviewScreen to ConversationPage');
      } else {
        debugPrint("No file picked or file doesn’t exist");
      }
    } catch (e) {
      debugPrint("Error in _pickAndPreviewFile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick $type: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ConversationPage for ${widget.receiverUsername}');
    final authState = Provider.of<AuthState>(context);
    final chatState = Provider.of<ChatState>(context);
    final senderId = authState.uid!;

    return WillPopScope(
      onWillPop: () async {
        debugPrint('System back button pressed, popping to HomePage');
        return true; // Allow pop
      },
      child: Scaffold(
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
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  debugPrint('AppBar back button pressed, popping to HomePage');
                  Navigator.pop(context);
                },
              ),
              CircleAvatar(
                radius: 16,
                backgroundImage: _getAvatarImage(widget.receiverAvatarUrl),
                child: _getAvatarImage(widget.receiverAvatarUrl) == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ],
          ),
          title: Text(widget.receiverUsername,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          leadingWidth: 80,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Text(
                  'Inbox',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            Expanded(child: _buildMessageList(senderId, chatState)),
            _buildUserInput(chatState, senderId),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage(String url) {
    if (url.isEmpty) {
      debugPrint('Avatar URL is empty');
      return null;
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    try {
      return AssetImage(url);
    } catch (e) {
      debugPrint('Error loading asset image: $e');
      return null;
    }
  }

  Widget _buildMessageList(String senderId, ChatState chatState) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatState.getMessages(senderId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Message stream error: ${snapshot.error}');
          return Center(
            child: Text("Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Loading messages...');
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          debugPrint('No messages found');
          return const Center(
            child: Text(
              "No Messages Yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          );
        }

        final messages = snapshot.data!.docs;
        messages.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime); // Descending: newest first
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;
            final isCurrentUser = data['senderID'] == senderId;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            if (data.containsKey('fileUrl')) {
              return _buildFileMessageItem(data, isCurrentUser, timestamp);
            } else {
              return _buildTextMessageItem(data['message'], isCurrentUser, timestamp);
            }
          },
        );
      },
    );
  }

  Widget _buildTextMessageItem(String message, bool isCurrentUser, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: _getAvatarImage(widget.receiverAvatarUrl),
              child: _getAvatarImage(widget.receiverAvatarUrl) == null
                  ? const Icon(Icons.person, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue : Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(timestamp),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFileMessageItem(Map<String, dynamic> data, bool isCurrentUser, DateTime timestamp) {
    final fileUrl = data['fileUrl'] as String;
    final type = data['type'] as String;
    final preferences = data['preferences'] as Map<String, dynamic>? ?? {};
    final fileName = data['fileName'] as String? ?? 'PDF File';

    final caption = [
      'Copies: ${preferences['copies'] ?? '1'}',
      'Color: ${preferences['isColor'] == true ? 'Color' : 'B & W'}',
      'Paper: ${preferences['paperSize'] ?? 'A4'}',
      'Sides: ${preferences['sides'] ?? 'Front'}',
      if (type == 'pdf' && preferences['startPage'] != null && preferences['endPage'] != null)
        'Pages: ${preferences['startPage']}-${preferences['endPage']}',
    ].join(', ');

    if (type == 'pdf') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 14,
                backgroundImage: _getAvatarImage(widget.receiverAvatarUrl),
                child: _getAvatarImage(widget.receiverAvatarUrl) == null
                    ? const Icon(Icons.person, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          caption,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(timestamp),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser) const SizedBox(width: 8),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundImage: _getAvatarImage(widget.receiverAvatarUrl),
                  child: _getAvatarImage(widget.receiverAvatarUrl) == null
                      ? const Icon(Icons.person, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Colors.blue : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              fileUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[900],
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white70,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Image load error: $error');
                                return Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[900],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              caption,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(timestamp),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser) const SizedBox(width: 8),
            ],
          ),
        );
      }
    }

    Widget _buildUserInput(ChatState chatState, String senderId) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white54),
              onPressed: () {
                debugPrint('Attachment button pressed');
                _textFieldFocus.unfocus();
                _showAttachmentDialog(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.payment, color: Colors.green),
              onPressed: () {
                debugPrint('Payment button pressed');
              },
            ),
            Expanded(
              child: TextField(
                focusNode: _textFieldFocus, // Fixed typo: _textSilverFocus -> _textFieldFocus
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                onTap: () {
                  debugPrint('Text field tapped');
                  FocusScope.of(context).requestFocus(_textFieldFocus);
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(chatState, senderId),
              ),
            ),
          ],
        ),
      );
    }

    void _showAttachmentDialog(BuildContext context) {
      debugPrint('Showing attachment dialog');
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.2),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return WillPopScope(
            onWillPop: () async {
              debugPrint('Attachment dialog dismissed');
              FocusScope.of(context).unfocus();
              return true;
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Attach File",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAttachmentOption(
                            icon: Icons.image,
                            label: "Image",
                            onTap: () {
                              debugPrint('Image attachment selected');
                              Navigator.pop(context);
                              _pickAndPreviewFile('image');
                            },
                          ),
                          _buildAttachmentOption(
                            icon: Icons.picture_as_pdf,
                            label: "PDF",
                            onTap: () {
                              debugPrint('PDF attachment selected');
                              Navigator.pop(context);
                              _pickAndPreviewFile('pdf');
                            },
                          ),
                          _buildAttachmentOption(
                            icon: Icons.more_horiz,
                            label: "More",
                            onTap: () {
                              debugPrint('More attachment selected');
                              Navigator.pop(context);
                              // Placeholder for future expansion
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget _buildAttachmentOption({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 40),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
}