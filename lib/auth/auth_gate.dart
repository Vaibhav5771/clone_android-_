import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_state.dart';
import 'login_or_register.dart';
import '../pages/launcher_screen.dart'; // Import LauncherScreen
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            final authState = Provider.of<AuthState>(context, listen: false);

            if (authState.uid == null) {
              authService.getUserData(user.uid).then((userData) {
                authState.setUser(
                  user.uid,
                  userData?['email'] ?? user.email ?? 'unknown@email.com',
                  userData?['username'] ?? user.email?.split('@')[0] ?? 'Guest',
                  userData?['avatarUrl'] ?? 'assets/avatar_1.png',
                );
                print('Restored AuthState: ${authState.username}, ${authState.avatarUrl}');
              }).catchError((e) {
                print('Failed to restore user data: $e');
                authState.setUser(
                  user.uid,
                  user.email ?? 'unknown@email.com',
                  user.email?.split('@')[0] ?? 'Guest',
                  'assets/avatar_1.png',
                );
              });
            }

            // Show LauncherScreen on auto-login
            return LauncherScreen(autoLogin: true);
          } else {
            Provider.of<AuthState>(context, listen: false).clearUser();
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}