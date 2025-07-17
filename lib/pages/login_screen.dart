import 'package:clone_android/pages/launcher_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../auth_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/login_field.dart';
import '../widgets/widget_button.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void login(BuildContext context) async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    try {
      UserCredential userCredential = await authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      Map<String, dynamic>? userData = await authService.getUserData(userCredential.user!.uid);
      Provider.of<AuthState>(context, listen: false).setUser(
        userCredential.user!.uid,
        _emailController.text,
        userData?['username'] ?? _emailController.text.split('@')[0],
        userData?['avatarUrl'] ?? 'assets/avatar_1.png',
      );
      print('AuthState after email login: ${Provider.of<AuthState>(context, listen: false).username}, ${Provider.of<AuthState>(context, listen: false).avatarUrl}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LauncherScreen()),
      );
    } catch (e) {
      _showErrorDialog('Login Error', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    try {
      final userCredential = await authService.signInWithGoogle();
      if (userCredential != null) {
        final user = userCredential.user!;
        Map<String, dynamic>? userData = await authService.getUserData(user.uid);
        Provider.of<AuthState>(context, listen: false).setUser(
          user.uid,
          user.email ?? 'no-email@example.com',
          userData?['username'] ?? user.email?.split('@')[0] ?? 'Anonymous',
          userData?['avatarUrl'] ?? 'assets/avatar_1.png',
        );
        print('AuthState after Google login: ${Provider.of<AuthState>(context, listen: false).username}, ${Provider.of<AuthState>(context, listen: false).avatarUrl}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LauncherScreen()),
        );
      } else {
        _showErrorDialog('Google Sign-In Error', 'Google Sign-In was canceled.');
      }
    } catch (e) {
      _showErrorDialog('Google Sign-In Error', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
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
                  'OK',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/login_page.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 220,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFF56F8FA), Color(0xFF3388D7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        "Simplify Your Printing\nJourney with Us",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB6BDC4),
                      ),
                    ),
                    SizedBox(height: 30),
                    LoginField(
                      hintText: 'Email',
                      obscureText: false,
                      controller: _emailController,
                      leadingIcon: Icons.email,
                    ),
                    SizedBox(height: 15),
                    LoginField(
                      hintText: 'Password',
                      obscureText: true,
                      controller: _passwordController,
                      leadingIcon: Icons.lock,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Forget Password tapped')),
                          );
                        },
                        child: Text(
                          'Forget Password?',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GradientButton(
                      onTap: _isLoading ? null : () => login(context),
                      label: _isLoading ? '' : 'Login',
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialButton(
                          iconPath: 'assets/g_logo.svg',
                          label: 'Google',
                          onTap: () {
                            print('Google button tapped in LoginScreen, _isLoading: $_isLoading');
                            if (!_isLoading) signInWithGoogle(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Register",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = widget.onTap,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}