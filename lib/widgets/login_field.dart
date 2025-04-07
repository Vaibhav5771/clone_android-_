import 'package:flutter/material.dart';

class LoginField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final IconData? leadingIcon; // Added for email/password icons

  const LoginField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: Colors.white, // Added cursor color
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: leadingIcon != null ? Icon(leadingIcon, color: Colors.grey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: Colors.white), // White text on black background
    );
  }
}