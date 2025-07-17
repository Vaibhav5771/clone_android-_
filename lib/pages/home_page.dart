import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_android/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/auth_gate.dart';
import '../auth_state.dart';
import '../services/chat_services.dart';
import '../services/map_state.dart';
import '../services/profile_state.dart';
import '../services/qr_code_manager.dart';
import 'conversation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../widgets/bottom_navigator.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggingOut = false;
  int _currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        title: Text(
          'Confirm Logout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Do you really want to log out?',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(dialogContext);
              setState(() => _isLoggingOut = false);
            },
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                final authState = Provider.of<AuthState>(context, listen: false);
                await FirebaseAuth.instance.signOut();
                authState.clearUser();
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AuthGate()),
                  );
                }
              } catch (e) {
                debugPrint('Error signing out: $e');
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoggingOut = false);
              }
            },
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);

    if (authState.uid == null) {
      return Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => MapState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: MediaQuery.of(context).size.height * 0.077,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF62C3F4),
                  Color(0xFF0469C4),
                ],
              ),
            ),
          ),
          title: Container(
            height: MediaQuery.of(context).size.height * 0.070,
            width: MediaQuery.of(context).size.width * 0.30,
            padding: const EdgeInsets.all(5),
            child: SvgPicture.asset(
              'assets/Logo.svg',
              height: 36,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.qr_code, color: Colors.black87),
              onPressed: () => QRCodeManager.showQRCode(context, authState.uid!),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.black87),
              onPressed: _isLoggingOut ? null : () => _logout(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildTabContent(),
            if (_currentIndex == 0)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF62C3F4),
                        Color(0xFF0469C4),
                      ],
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () => QRCodeManager.scanQRCode(context),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return Consumer<ChatState>(
          builder: (context, chatState, _) {
            return _buildChatsList(Provider.of<AuthState>(context), chatState);
          },
        );
      case 1:
        return const MapPage();
      case 2:
        return const ProfilePage();
      default:
        return Consumer<ChatState>(
          builder: (context, chatState, _) {
            return _buildChatsList(Provider.of<AuthState>(context), chatState);
          },
        );
    }
  }

  Widget _buildChatsList(AuthState authState, ChatState chatState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Chats',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatState.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Chats stream error: ${snapshot.error}');
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Loading chats...');
                return Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data ?? [];
              print('Loaded ${users.length} users for Chats');
              if (users.isEmpty) {
                print('No users found for Chats');
                return Center(
                  child: Text(
                    'No users available',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              final filteredUsers = users.where((user) => user['email'] != authState.email).toList();
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredUsers.length + (filteredUsers.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < filteredUsers.length) {
                    final user = filteredUsers[index];
                    print('Showing chat user: ${user['email']}');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          child: ClipOval(
                            child: user['avatarUrl'] != null && user['avatarUrl'].startsWith('http')
                                ? CachedNetworkImage(
                              imageUrl: user['avatarUrl'],
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => CircularProgressIndicator(strokeWidth: 2),
                              errorWidget: (context, url, error) {
                                print('Failed to load avatar for ${user['email']}: $error');
                                return Image.asset('assets/avatar_1.png', fit: BoxFit.cover);
                              },
                            )
                                : Image.asset(
                              user['avatarUrl'] ?? 'assets/avatar_1.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          user['username'] ?? user['email']?.split('@')[0] ?? 'Anonymous',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onTap: () {
                          print('Tapped chat user: ${user['email']}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationPage(
                                receiverId: user['uid'],
                                receiverUsername: user['username'] ?? user['email']?.split('@')[0] ?? 'Anonymous',
                                receiverAvatarUrl: user['avatarUrl'] ?? 'assets/avatar_1.png',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No More Chats',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}