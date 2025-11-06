import 'package:flutter/material.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? trailingIcon; // For the "Next" arrow

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = kPrimaryBlue, // Use the new constant
    this.width = double.infinity, // Default to full width if not specified
    this.height = 68.0, // Default height from your spec
    this.borderRadius = 50.0, // Default radius from your spec
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          // Remove default padding to control size exactly with SizedBox
          padding: EdgeInsets.zero, 
          elevation: 5, // Adds a subtle lift/shadow
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon!,
            ],
          ],
        ),
      ),
    );
  }
}
