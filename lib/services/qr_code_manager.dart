import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../auth_state.dart';
import '../pages/conversation_page.dart';

class QRCodeManager {
  static void showQRCode(BuildContext context, String uid) {
    debugPrint('Showing QR code for UID: $uid');
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
            onTap: () {
              debugPrint('Closing QR code dialog');
              Navigator.pop(context);
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

  static Future<void> scanQRCode(BuildContext context) async {
    debugPrint('Starting QR scan...');
    final authState = Provider.of<AuthState>(context, listen: false);
    debugPrint('Auth UID: ${authState.uid}');

    if (await Permission.camera.request().isGranted) {
      final homeContext = context;
      debugPrint('Opening QR scanner dialog');
      String? scannedUid = await showDialog<String>(
        context: context,
        builder: (context) => _ScannerPage(),
      );

      debugPrint('Scan result: $scannedUid');
      if (scannedUid != null && scannedUid != authState.uid) {
        try {
          debugPrint('Fetching user data for UID: $scannedUid');
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(scannedUid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final receiverUsername = userData['username'] as String? ?? userData['email']?.split('@')[0] ?? 'Anonymous';
            final receiverAvatarUrl = userData['avatarUrl'] as String? ?? 'assets/avatar_1.png';
            debugPrint('Navigating to ConversationPage with username: $receiverUsername');
            // Check if homeContext is still valid
            if (homeContext.mounted) {
              await Navigator.push(
                homeContext,
                MaterialPageRoute(
                  builder: (context) => ConversationPage(
                    receiverId: scannedUid,
                    receiverUsername: receiverUsername,
                    receiverAvatarUrl: receiverAvatarUrl,
                  ),
                ),
              );
              debugPrint('Returned from ConversationPage to HomePage');
            } else {
              debugPrint('Error: homeContext is not mounted');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigation error: Context not available')),
              );
            }
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
    debugPrint('Disposing QRViewController');
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    debugPrint('QRView created, listening for scan');
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
    debugPrint('Building ScannerPage dialog');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      title: Text(
        'Scan QR Code',
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.black,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 200,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () {
            debugPrint('Cancel button pressed, closing scanner dialog');
            Navigator.pop(context);
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
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}