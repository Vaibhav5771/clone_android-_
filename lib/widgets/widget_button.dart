import 'package:flutter/material.dart';
import '../pallete.dart';


class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final double horizontalPadding;

  const SocialButton({
    super.key,
    required this.iconPath,
    required this.label,
    this.horizontalPadding = 70,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Image.asset(
        iconPath,
        width: 25,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Pallete.blackColor,
          fontSize: 16,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: horizontalPadding),
        side: BorderSide(
          color: Pallete.borderColor,
          width: 3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
