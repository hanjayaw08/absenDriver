import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:driverattendance/linkUtama_server.dart';
import 'package:driverattendance/view/home/splashScreen_page.dart';
import 'package:driverattendance/view/profil/bantuan_page.dart';
import 'package:driverattendance/view/profil/informasiAplikasi_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class profilPage extends StatefulWidget {
  String password;
  String displayName;
  String email;
  String idUSer;
  String token;

  profilPage({
    required this.password,
    required this.displayName,
    required this.email,
    required this.token,
    required this.idUSer,
    Key? key,
  }) : super(key: key);

  @override
  _profilPageState createState() =>
      _profilPageState();
}

class _profilPageState extends State<profilPage> {

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void initState() {
    super.initState();
    fetchAbsensi();
  }

  void performLogout() async {
    // Hapus data sesi dan data pengguna
    showLoadingIndicator();
    await nhost.auth.signOut();
    await clearLoginState();
    await AwesomeNotifications().cancelAll();
    await _firebaseMessaging.deleteToken();
    hideLoadingIndicator();
    Get.offAll(splashScreenPage());
  }

  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  Future<void> gantiPassword() async {
    try {
      // Menampilkan loading indicator
      showLoadingIndicator();

      await nhost.auth.changePassword(newPassword: konfirmasiPasswordBaruText.text);
      print('Sukses');
    } catch (error) {
      print('$error');
    } finally {
      // Sembunyikan loading indicator setelah proses ganti password selesai
      hideLoadingIndicator();
    }
  }

  void showLoadingIndicator() {
    setState(() {
      isLoading = true;
    });
  }

  void hideLoadingIndicator() {
    setState(() {
      isLoading = false;
    });
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passwordLamaText = TextEditingController();
  final TextEditingController passwordBaruText = TextEditingController();
  final TextEditingController konfirmasiPasswordBaruText = TextEditingController();
  bool isObscured = true;
  bool isObscured1 = true;
  bool isObscured2 = true;
  Color _getBorderColor(String value) {
    return value.isEmpty ? Colors.red : Colors.black;
  }

  bool isLoading = false;

  void showGantiPasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 15,),
                    Row(
                      children: [
                        Text(
                          'Ganti Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            passwordLamaText.clear();
                            passwordBaruText.clear();
                            konfirmasiPasswordBaruText.clear();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Text('Password Lama',
                      style: TextStyle(
                          fontWeight: FontWeight.w300
                      ),
                    ),
                    TextFormField(
                      controller: passwordLamaText,
                      obscureText: isObscured,
                      decoration: InputDecoration(
                        hintText: 'Password Lama',
                        filled: true,
                        fillColor: Color.fromRGBO(239, 240, 246, 1.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: _getBorderColor(passwordLamaText.text)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              isObscured = !isObscured;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value != widget.password) {
                          return '* Password Lama kurang tepat';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    Text('Password Baru',
                      style: TextStyle(
                          fontWeight: FontWeight.w300
                      ),
                    ),
                    TextFormField(
                      controller: passwordBaruText,
                      obscureText: isObscured1,
                      decoration: InputDecoration(
                        hintText: 'Password Baru',
                        filled: true,
                        fillColor: Color.fromRGBO(239, 240, 246, 1.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: _getBorderColor(passwordBaruText.text)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(isObscured1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              isObscured1 = !isObscured1;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* Password Baru harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    Text('Konfirmasi Password',
                      style: TextStyle(
                          fontWeight: FontWeight.w300
                      ),
                    ),
                    TextFormField(
                      controller: konfirmasiPasswordBaruText,
                      obscureText: isObscured2,
                      decoration: InputDecoration(
                        hintText: 'Konfirmasi Password',
                        filled: true,
                        fillColor: Color.fromRGBO(239, 240, 246, 1.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: _getBorderColor(konfirmasiPasswordBaruText.text)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(isObscured2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              isObscured2 = !isObscured2;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* Konfirmasi Password Baru harus diisi';
                        } else if (value != passwordBaruText.text) {
                          return '* Konfirmasi Password Baru tidak sesuai';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Menambahkan indikator loading di sini
                    if (isLoading)
                      Center(
                        child: CircularProgressIndicator(),
                      ),

                    Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() == true) {
                          // Menampilkan indikator loading sebelum ganti password
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            await gantiPassword();
                            passwordLamaText.clear();
                            passwordBaruText.clear();
                            konfirmasiPasswordBaruText.clear();
                            // Menyembunyikan modal setelah ganti password berhasil
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ganti password berhasil'),
                              ),
                            );
                          } catch (error) {
                            print('Gagal ganti password: $error');
                          } finally {
                            // Menyembunyikan indikator loading setelah selesai ganti password
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey[300],
                      ),
                      child: Text('Simpan'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchAbsensi() async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer ${widget.token}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
          query MyQuery {
  users(where: {id: {_eq: "${widget.idUSer}"}}) {
    displayName
    email
    phoneNumber
  }
}
      '''),
      ),
    );

    if (result.hasException) {
      print('Error: ${result.exception.toString()}');
    } else {
      absensi.value = RxList<Map<String, dynamic>>(List<Map<String, dynamic>>.from(result.data?['users'] ?? []));
      print(absensi[0]['email']);
    }
  }

  RxList<Map<String, dynamic>> absensi = RxList<Map<String, dynamic>>([]);

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: null,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Image.asset('assets/img/backGroundProfil.png'),
            Padding(
                padding: EdgeInsets.only(top: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child:  Row(
                          children: [
                            Text('Akun Pengguna',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Spacer(),
                            Container(
                              height: 35,
                              child: CustomButton(
                                onPressed: (){
                                  performLogout();
                                },
                                width: 100,
                                height: 100,
                                text: 'Keluar',
                                icon1: Icons.logout,
                                radius: 10,
                                cekSpacer: false,
                                textColor: Colors.red,
                                iconColor: Colors.red,
                                buttonColor: Colors.white,
                              ),
                            )
                          ],
                        ),
                    ),
                    SizedBox(height: 30,),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child:    ClipOval(
                        child: Image.asset(
                          'assets/img/BeepBeepUFO.png',
                          width: 100.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                          height: 100.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 30,),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(absensi.isNotEmpty && absensi[0]['email'] != null
                              ? absensi[0]['email']
                              : '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            ),
                          ),),
                          Obx(() => Text(absensi.isNotEmpty && absensi[0]['displayName'] != null
                              ? absensi[0]['displayName']
                              : '',
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13
                            ),
                          ),),
                          Obx(() => Text(absensi.isNotEmpty && absensi[0]['phoneNumber'] != null
                              ? absensi[0]['phoneNumber']
                              : '',
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13
                            ),
                          )),
                        ],
                      )
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 30,),
                    Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child:  Container(
                          height: 35,
                          child: CustomButton(
                            onPressed: (){
                              showGantiPasswordModal(context);
                            },
                            width: 100,
                            height: 100,
                            text: 'Ganti Password',
                            icon1: Icons.arrow_right,
                            radius: 10,
                            cekSpacer: true,
                            textColor: Colors.black,
                            iconColor: Colors.black,
                            buttonColor: Colors.white,
                          ),
                        )
                    ),
                    SizedBox(height: 15,),
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15,),
                    Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child:  Container(
                          height: 35,
                          child: CustomButton(
                            onPressed: (){
                              Get.to(HRDContactView());
                            },
                            width: 100,
                            height: 100,
                            text: 'Bantuan',
                            icon1: Icons.arrow_right,
                            radius: 10,
                            cekSpacer: true,
                            textColor: Colors.black,
                            iconColor: Colors.black,
                            buttonColor: Colors.white,
                          ),
                        )
                    ),
                    SizedBox(height: 15,),
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15,),
                    Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child:  Container(
                          height: 35,
                          child: CustomButton(
                            onPressed: (){
                              Get.to(informasiAplikasiView());
                            },
                            width: 100,
                            height: 100,
                            text: 'Informasi Aplikasi',
                            icon1: Icons.arrow_right,
                            radius: 10,
                            cekSpacer: true,
                            textColor: Colors.black,
                            iconColor: Colors.black,
                            buttonColor: Colors.white,
                          ),
                        )
                    ),
                    SizedBox(height: 15,),
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                  ],
                ),
            ),
            if (isLoading)
              Container(
                height: MediaQuery.of(context).size.height,  // Menyesuaikan tinggi dengan tinggi layar
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        )
      ),
    );
  }
}
