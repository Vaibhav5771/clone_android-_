import 'package:chats/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/gradient_button.dart';
import '../widgets/login_field.dart';
import '../pages/register_screen.dart';
import '../widgets/widget_button.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _password = TextEditingController();

  final void  Function()? onTap;

  LoginScreen({super.key, required this.onTap});

  void login(BuildContext context) async {
    // auth service
    final authService = AuthService();

    // try login
    try {
      await authService.signInWithEmailPassword(_emailController.text, _password.text);
    }
    catch(e){
      showDialog(context: context,
          builder: (context) => AlertDialog(
        title: Text(e.toString()),
      ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/signin_balls.png'),
              const Text('Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 50,),
              LoginField(
                hintText: 'Email',
                obscureText: false,
                controller: _emailController,
              ),
              const SizedBox(height: 15,),
              LoginField(
                hintText: 'Password',
                obscureText: true,
                controller: _password,
              ),
              const SizedBox(height: 30,),
              GradientButton(
                onTap: () => login(context),
                label: 'Login',
              ),
              const SizedBox(height: 15,),
              const Text('or',style: TextStyle(
                fontSize: 17,
              ),),
              const SizedBox(height: 15,),
              SocialButton(iconPath: 'assets/g_logo.svg', label: 'Continue with Google'),
              SizedBox(height: 15,),
              SocialButton(iconPath: 'assets/f_logo.svg', label: 'Continue with GitHub'),
              SizedBox(height: 15,),
              RichText(
                text: TextSpan(
                  text: "If not registered yet ",
                  style: TextStyle(
                    color: Colors.black, // Normal black text
                    fontSize: 16, // Adjust font size as needed
                  ),
                  children: [
                    TextSpan(
                        text: "Register",
                        style: TextStyle(
                          color: Colors.blue, // Blue color for 'Register'
                          fontWeight: FontWeight.bold, // Optional: Make 'Register' bold
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onTap
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
