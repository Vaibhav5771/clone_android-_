import 'package:flutter/material.dart';
import '../pallete.dart';

class LoginField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  const LoginField({super.key, required this.hintText, required this.obscureText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 340,
      ),
      child: TextFormField(
        obscureText: obscureText,
        controller: controller,
        cursorColor: Colors.black, // Set cursor color to black
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(20),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.borderColor,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.gradient2,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: hintText,
        ),
      ),
    );
  }
}
