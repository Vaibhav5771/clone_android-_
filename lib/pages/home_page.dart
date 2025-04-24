import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/auth_gate.dart';
import '../auth_state.dart';
import '../services/chat_services.dart';
import '../services/map_state.dart';
import '../services/search_state.dart';
import '../services/profile_state.dart';
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
  int _currentIndex = 0; // Default to Chats tab

  Future<void> _logout(BuildContext context) async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    final authState = Provider.of<AuthState>(context, listen: false);
    final dialogContext = context;

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
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
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showQRCode(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        title: Text(
          'Your QR Code',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              child: Center(
                child: QrImageView(
                  data: uid,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Close',
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

  Future<void> _scanQRCode(BuildContext context) async {
    debugPrint('Starting QR scan...');
    final authState = Provider.of<AuthState>(context, listen: false);
    debugPrint('Auth UID: ${authState.uid}');

    if (await Permission.camera.request().isGranted) {
      String? scannedUid = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ScannerPage(),
        ),
      );

      debugPrint('Scan result: $scannedUid');
      if (scannedUid != null && scannedUid != authState.uid) {
        try {
          debugPrint('Fetching user data for UID: $scannedUid');
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(scannedUid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final receiverUsername = userData['username'] as String? ?? userData['email'].split('@')[0];
            final receiverAvatarUrl = userData['avatarUrl'] as String? ?? 'https://example.com/default-avatar.jpg';
            debugPrint('Navigating to chat with: $receiverUsername');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationPage(
                  receiverId: scannedUid,
                  receiverUsername: receiverUsername,
                  receiverAvatarUrl: receiverAvatarUrl,
                ),
              ),
            );
            debugPrint('Navigation to ConversationPage complete');
          } else {
            debugPrint('User not found for UID: $scannedUid');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User not found')),
            );
          }
        } catch (e) {
          debugPrint('Error fetching user: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } else if (scannedUid == authState.uid) {
        debugPrint('Cannot chat with self');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot chat with yourself')),
        );
      }
    } else {
      debugPrint('Camera permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied')),
      );
    }
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
        ChangeNotifierProvider(create: (_) => SearchState()),
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
              onPressed: () => _showQRCode(context, authState.uid!),
            ),
            IconButton(
              icon: Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                print('Search icon pressed');
              },
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
            if (_currentIndex == 0) // Show FAB only on Chats tab
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
                    onPressed: () => _scanQRCode(context),
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
        return Consumer<SearchState>(
          builder: (context, searchState, _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Search Page',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Query: ${searchState.query}',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: TextField(
                      onChanged: (value) => searchState.setQuery(value),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter search query',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 3:
        return Consumer<ProfileState>(
          builder: (context, profileState, _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Profile Page',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 16),
                  Text(
                    profileState.isProfileLoaded ? 'Profile Loaded' : 'Profile Not Loaded',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: () => profileState.loadProfile(),
                    child: Text('Load Profile'),
                  ),
                ],
              ),
            );
          },
        );
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
              final users = snapshot.data!;
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
                          backgroundImage: AssetImage(user['avatarUrl'] ?? 'assets/avatar_1.png'),
                        ),
                        title: Text(
                          user['username'] ?? user['email'].split('@')[0],
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onTap: () {
                          print('Tapped chat user: ${user['email']}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationPage(
                                receiverId: user['uid'],
                                receiverUsername: user['username'] ?? user['email'].split('@')[0],
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

class _ScannerPage extends StatefulWidget {
  @override
  __ScannerPageState createState() => __ScannerPageState();
}

class __ScannerPageState extends State<_ScannerPage> {
  QRViewController? _controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((Barcode barcode) {
      final String? uid = barcode.code;
      debugPrint('Scanned UID: $uid');
      if (uid != null) {
        Navigator.pop(context, uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }
}