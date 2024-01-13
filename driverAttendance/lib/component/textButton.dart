import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String? text;
  final VoidCallback onPressed;
  final Color? buttonColor;
  final IconData? icon;
  final Color? iconColor;
  final IconData? icon1;

  const CustomTextButton({
    this.text,
    required this.onPressed,
    this.icon,
    this.icon1,
    this.iconColor,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon1 != null)
            Icon(
              icon1,
              color: iconColor ?? Colors.white,
            ),
          if (text != null )
            Text(
              text!,
              style: TextStyle(
                color: buttonColor ?? Colors.blue,
              ),
            ),
          if (icon != null)
            Icon(
              icon,
              color: iconColor ?? Colors.white,
            ),
        ],
      ),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
