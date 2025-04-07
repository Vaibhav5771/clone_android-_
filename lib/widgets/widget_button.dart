import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;

  const SocialButton({
    super.key,
    required this.iconPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Wider for social buttons
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          // Placeholder for future auth logic
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label tapped')));
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 16), // White for black background
            ),
          ],
        ),
      ),
    );
  }
}