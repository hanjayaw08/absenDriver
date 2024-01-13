import 'package:flutter/material.dart';

class HRDContactView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontak HRD'),
      ),
      body: Center(
        child: Text(
          'Harap Kontak HRD',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}