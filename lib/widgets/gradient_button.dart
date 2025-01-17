import 'package:flutter/material.dart';
import '../pallete.dart';

class GradientButton extends StatelessWidget {
  final void Function()? onTap;
  final String label;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Pallete.gradient1,
            Pallete.gradient2,
            Pallete.gradient3,
          ],
        ),
        borderRadius: BorderRadius.circular(10), // Rounded corners for the button
      ),
      child: ElevatedButton(
        onPressed: onTap, // Use the passed onTap function here
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(340, 55),
          backgroundColor: Colors.transparent, // Transparent to show gradient
          shadowColor: Colors.transparent, // Removes shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Match the container border
          ),
        ),
        child: Text(
          label, // Use the passed label here
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
