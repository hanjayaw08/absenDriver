import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final VoidCallback onPressed;
  final double width;
  final double? radius;
  final double height;
  final IconData? icon;
  final IconData? icon1;
  final Color? iconColor;
  final Color? buttonColor;
  final bool? cekSpacer;
  final Color? borderColor;
  final Color? textColor;

  const CustomButton({
    this.text,
    required this.onPressed,
    required this.width,
    required this.height,
    this.icon,
    this.icon1,
    this.iconColor,
    this.buttonColor,
    this.cekSpacer,
    this.borderColor,
    this.textColor,
    this.radius
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: iconColor ?? Colors.white,
            ),
          SizedBox(width: icon != null ? 8.0 : 0.0),
          if (text != null)
            Text(
              text!,
              style: TextStyle(
                color: textColor ?? Colors.white,
              ),
            ),
          if (cekSpacer != false)
            Spacer(),
          if (icon1 != null)
            Icon(
              icon1,
              color: iconColor ?? Colors.white,
            ),
        ],
      ),
      style: TextButton.styleFrom(
        backgroundColor: buttonColor ?? Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? 30.0),
          side: BorderSide(color: borderColor ?? Colors.white, width: 1.0),
        ),
        minimumSize: Size(width, height),
      ),
    );
  }
}
