import 'package:driverattendance/view/home/home_page.dart';
import 'package:driverattendance/view/profil/profil_page.dart';
import 'package:driverattendance/view/riwayat/riwayat_page.dart';
import 'package:flutter/material.dart';

class navBarPage extends StatefulWidget {
  String tokenDriver;
  String namaDriver;
  String password;
  String idDriver;
  String emailDriver;

  navBarPage({
    required this.tokenDriver,
    required this.namaDriver,
    required this.password,
    required this.idDriver,
    required this.emailDriver,
    Key? key,
  }) : super(key: key);

  @override
  _navBarPageState createState() => _navBarPageState();
}

class _navBarPageState extends State<navBarPage> {
  int _currentIndex = 0;

  void navigateToJanjiTamu(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late List<Widget> _pages;
  void initState() {
    super.initState();
    _pages = [
      homePage(tokenDriver: widget.tokenDriver, nameDriver: widget.namaDriver, idDriver: widget.idDriver, navigateToJanjiTamu: navigateToJanjiTamu,),
      riwayatPage(tokenDriver: widget.tokenDriver, nameDriver: widget.namaDriver, idDriver: widget.idDriver,),
      profilPage(password: widget.password,displayName: widget.namaDriver, email: widget.emailDriver,),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.black, // Warna ketika item dipilih
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Utama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Page 1'),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Page 2'),
    );
  }
}
