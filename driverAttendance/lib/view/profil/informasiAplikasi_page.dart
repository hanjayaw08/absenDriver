import 'package:flutter/material.dart';

class informasiAplikasiView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informasi Aplikasi'),
      ),
      body: Center(
        child: Text(
          'Informasi Aplikasi',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}