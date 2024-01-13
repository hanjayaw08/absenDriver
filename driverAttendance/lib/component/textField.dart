import 'package:flutter/material.dart';

class MyCustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color? buttonColor;

  MyCustomTextField({required this.controller, required this.hintText, this.buttonColor});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true, // Mengaktifkan pengisian latar belakang
        fillColor: buttonColor ??  Color.fromRGBO(239, 240, 246, 1.0), // Warna latar belakang
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0), // Atur radius border
          borderSide: BorderSide.none, // Menghilangkan border
        ),
      ),
    );
  }
}
