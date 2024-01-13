import 'package:driverattendance/riwayatHrd/riwayatHrd_page.dart';
import 'package:driverattendance/view/home/home_page.dart';
import 'package:driverattendance/view/home_hrd/homeHrdPage.dart';
import 'package:driverattendance/view/home_owner/homeOwner_Page.dart';
import 'package:driverattendance/view/profil/profil_page.dart';
import 'package:driverattendance/view/riwayat/riwayat_page.dart';
import 'package:driverattendance/view/riwayatOwner_page/riwayarOwner_page.dart';
import 'package:flutter/material.dart';

class navBarHrdPage extends StatefulWidget {
  String idDriver;
  String namaDriver;
  String tokenDriver;
  String password;
  String emailDriver;

  navBarHrdPage({
    required this.idDriver,
    required this.tokenDriver,
    required this.namaDriver,
    required this.password,
    required this.emailDriver,
    Key? key,
  }) : super(key: key);

  @override
  _navBarHrdPageState createState() => _navBarHrdPageState();
}

class _navBarHrdPageState extends State<navBarHrdPage> {
  int _currentIndex = 0;

  late List<Widget> _pages;
  void initState() {
    super.initState();
    _pages = [
      homeHrdPage(idDriver: widget.idDriver, nameDriver: widget.namaDriver, tokenDriver: widget.tokenDriver,navigateToJanjiTamu: navigateToJanjiTamu,),
      riwayatHrdPage(idDriver: widget.idDriver, tokenDriver: widget.tokenDriver, nameDriver: widget.namaDriver),
      profilPage(password: widget.password, displayName: widget.namaDriver, email: widget.emailDriver,),
    ];
  }

  void navigateToJanjiTamu(int index) {
    setState(() {
      _currentIndex = index;
    });
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