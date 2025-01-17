import 'package:chats/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/gradient_button.dart';
import '../widgets/login_field.dart';
import '../pages/login_screen.dart';
import '../widgets/widget_button.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();
  final TextEditingController _confirmpasswordcontroller = TextEditingController();

  void register(BuildContext context){
    // get auth service
    final _auth = AuthService();

    // passwords match -> create user
    if (_passwordcontroller.text == _confirmpasswordcontroller.text){
      try {
        _auth.signUpWithEmailPassword(
          _emailcontroller.text, _passwordcontroller.text,
        );
      } catch (e) {
        showDialog(context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    }
    // password doesnt match -> tell user to fix
    else{
      showDialog(context: context,
        builder: (context) => const AlertDialog(
          title: Text("Passwords doesn't Match!!!"),
        ),
      );
    }
  }

  final void  Function()? onTap;

  RegisterScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/signin_balls.png'),
              const Text(
                'Register',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 30),

              // Wrapping LoginFields in ConstrainedBox
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: LoginField(hintText: 'Email',
                  obscureText: false,
                  controller: _emailcontroller,),
              ),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child:  LoginField(hintText: 'Password', obscureText: true,
                  controller: _passwordcontroller,),
              ),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child:  LoginField(hintText: 'Confirm Password', obscureText: true,
                  controller: _confirmpasswordcontroller,),
              ),
              const SizedBox(height: 15),
              GradientButton(
                onTap: () => register(context),
                label: 'Register',
              ),
              const SizedBox(height: 15),
              const Text(
                'or',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 15),
              const SocialButton(iconPath: 'assets/g_logo.svg', label: 'Continue with Google'),
              const SizedBox(height: 15),
              const SocialButton(iconPath: 'assets/f_logo.svg', label: 'Continue with GitHub'),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(
                    color: Colors.black, // Normal black text
                    fontSize: 16, // Adjust font size as needed
                  ),
                  children: [
                    TextSpan(
                        text: "Login",
                        style: TextStyle(
                          color: Colors.blue, // Blue color for 'Login'
                          fontWeight: FontWeight.bold, // Optional: Make 'Login' bold
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
