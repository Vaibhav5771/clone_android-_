import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.iconPath,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap, // Use the provided onTap callback
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconPath.endsWith('.svg')
                ? SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
            )
                : Image.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}