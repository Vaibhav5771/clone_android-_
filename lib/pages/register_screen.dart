import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../auth_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/login_field.dart';
import '../widgets/widget_button.dart';
import 'home_page.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;

  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String _selectedAvatar = 'assets/avatar_5.jpg'; // Default avatar

  // List of available avatars
  final List<String> _avatarOptions = [
    'assets/avatar_1.jpg',
    'assets/avatar_2.jpg',
    'assets/avatar_3.jpg',
    'assets/avatar_4.jpg',
    'assets/avatar_5.jpg',
    'assets/avatar_6.jpg',
  ];

  bool _isLoading = false;

  void register(BuildContext context) async {
    setState(() => _isLoading = true);
    final _auth = AuthService();
    try {
      UserCredential userCredential = await _auth.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
        _selectedAvatar,
      );
      Provider.of<AuthState>(context, listen: false).setUser(
        userCredential.user!.uid,
        _emailController.text,
        _usernameController.text,
        _selectedAvatar,
      );
      print('AuthState after register: ${Provider.of<AuthState>(context, listen: false).username}, ${Provider.of<AuthState>(context, listen: false).avatarUrl}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog('Firebase Error', 'Code: ${e.code}\nMessage: ${e.message}');
    } catch (e) {
      _showErrorDialog('Unexpected Error', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        title: Text(
          'Choose Your Avatar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          height: 150,
          padding: EdgeInsets.all(10),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1,
            ),
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(avatar),
                    child: isSelected
                        ? Icon(Icons.check_circle, color: Colors.blue, size: 28)
                        : null,
                  ),
                ),
              );
            },
          ),
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
      ),
    );
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
      backgroundColor: Colors.black, // Set Scaffold background to black
      body: Stack(
        children: [
          // Background Image at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/register_page.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Black Container covering the whole screen from bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 220, // Match the original top margin to align with image
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "Register" Title
                    Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB6BDC4),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Centered Avatar with Edit Button
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(_selectedAvatar),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey, width: 2),
                              ),
                              child: Center(
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.black, size: 10),
                                  onPressed: _showAvatarDialog,
                                  padding: EdgeInsets.all(0),
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Username Field
                    LoginField(
                      hintText: 'Username',
                      obscureText: false,
                      controller: _usernameController,
                      leadingIcon: Icons.person,
                    ),
                    SizedBox(height: 15),
                    // Email Field
                    LoginField(
                      hintText: 'Email',
                      obscureText: false,
                      controller: _emailController,
                      leadingIcon: Icons.email,
                    ),
                    SizedBox(height: 15),
                    // Password Field with Icon
                    LoginField(
                      hintText: 'Password',
                      obscureText: true,
                      controller: _passwordController,
                      leadingIcon: Icons.lock,
                    ),
                    SizedBox(height: 20),
                    // Register Button
                    GradientButton(
                      onTap: _isLoading ? null : () => register(context),
                      label: _isLoading ? '' : 'Register',
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: 20),
                    // "OR" with Dividers
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
                    // Google and Guest Sign-In in a Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialButton(
                          iconPath: 'assets/g_logo.svg',
                          label: 'Google',
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Login Link
                    RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = widget.onTap,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20), // Extra padding at the bottom
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