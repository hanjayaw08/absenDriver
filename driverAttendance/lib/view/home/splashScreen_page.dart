import 'package:driverattendance/coba_pdf.dart';
import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:driverattendance/linkUtama_server.dart';
import 'package:driverattendance/navBar_page.dart';
import 'package:driverattendance/navbarHrd_page.dart';
import 'package:driverattendance/navbarOwner_page.dart';
import 'package:driverattendance/view/GAview/navbarGA_page.dart';
import 'package:driverattendance/view/home_owner/homeOwner_Page.dart';
import 'package:driverattendance/view/profil/profil_page.dart';
import 'package:driverattendance/view/riwayat/riwayat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animated_widgets/animated_widgets.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class splashScreenPage extends StatefulWidget {
  @override
  _splashScreenPageState createState() => _splashScreenPageState();
}

class _splashScreenPageState extends State<splashScreenPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late String fcmToken;
  final TextEditingController usernameText = TextEditingController();
  final TextEditingController emailText = TextEditingController();
  final TextEditingController passwordText = TextEditingController();
  final TextEditingController konfirmasiPasswordText = TextEditingController();

  // bolean untuk cek modalnya
  RxBool cek = false.obs;
  RxBool cekPunyaAkun = false.obs;

  // void performLogin() async {
  //   try {
  //     await nhost.auth.signInEmailPassword(
  //       email: emailText.text,
  //       password: passwordText.text,
  //     );
  //
  //     final currentUser = nhost.auth.currentUser;
  //     final tokenUser = nhost.auth.accessToken;
  //
  //     await saveLoginState(tokenUser.toString(), currentUser?.defaultRole, currentUser!.displayName, passwordText.text, currentUser!.id);
  //
  //     // Arahkan ke halaman yang sesuai berdasarkan peran pengguna
  //     if (currentUser?.defaultRole == 'driver') {
  //       await _firebaseMessaging.getToken().then((String? token) {
  //         assert(token != null);
  //         print("FCM Token: $token");
  //
  //         // Simpan token dalam variabel
  //         fcmToken = token!;
  //       });
  //       insertFCM(token: tokenUser.toString(), tokenFCM: fcmToken.toString());
  //       Get.to(navBarPage(
  //         tokenDriver: tokenUser.toString(),
  //         idDriver: currentUser!.id,
  //         namaDriver: currentUser!.displayName,
  //         password: passwordText.text,
  //       ));
  //     } else if (currentUser?.defaultRole == 'hrd') {
  //       Get.to(navBarHrdPage(idDriver: currentUser.id, tokenDriver: tokenUser.toString(), namaDriver: currentUser!.displayName));
  //     } else if (currentUser?.defaultRole == 'owner') {
  //       Get.to(navBarOwnerPage(
  //         idDriver: currentUser.id,
  //         namaDriver: currentUser!.displayName,
  //         tokenDriver: tokenUser.toString(),
  //       ));
  //     }
  //     print(tokenUser);
  //     print("ini isinya ${currentUser!.id}");
  //   } catch (error) {
  //     print('Gagal login: $error');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Password atau email salah'),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

  bool isLoading = false;

  void performLogin() async {
    try {
      // Menampilkan loading indicator
      showLoadingIndicator();

      await nhost.auth.signInEmailPassword(
        email: emailText.text,
        password: passwordText.text,
      );

      final currentUser = nhost.auth.currentUser;
      final tokenUser = nhost.auth.accessToken;

      await saveLoginState(tokenUser.toString(), currentUser?.defaultRole, currentUser!.displayName, passwordText.text, currentUser!.id, currentUser.email ?? '');

      // Arahkan ke halaman yang sesuai berdasarkan peran pengguna
      if (currentUser?.defaultRole == 'driver') {
        await _firebaseMessaging.getToken().then((String? token) {
          assert(token != null);
          print("FCM Token: $token");

          // Simpan token dalam variabel
          fcmToken = token!;
        });
        insertFCM(token: tokenUser.toString(), tokenFCM: fcmToken.toString());
        Get.to(navBarPage(
          tokenDriver: tokenUser.toString(),
          idDriver: currentUser!.id,
          namaDriver: currentUser!.displayName,
          password: passwordText.text,
          emailDriver: currentUser.email ?? '',
        ));
      } else if (currentUser?.defaultRole == 'hrd') {
        Get.to(navBarHrdPage(idDriver: currentUser.id, tokenDriver: tokenUser.toString(), namaDriver: currentUser!.displayName, password: passwordText.text, emailDriver: currentUser.email ?? '',));
      } else if (currentUser?.defaultRole == 'owner') {
        Get.to(navBarOwnerPage(
          idDriver: currentUser.id,
          namaDriver: currentUser!.displayName,
          tokenDriver: tokenUser.toString(),
          password: passwordText.text,
          emailDriver: currentUser.email ?? '',
        ));
      }else if (currentUser?.defaultRole == 'ga') {
        Get.to(navBarGAPage(idDriver: currentUser.id, tokenDriver: tokenUser.toString(), namaDriver: currentUser!.displayName, password: passwordText.text, emailDriver: currentUser.email ?? '',));
      }
      print(tokenUser);
      print("ini isinya ${currentUser!.id}");
      print(currentUser.defaultRole);
    } catch (error) {
      print('Gagal login: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password atau email salah'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      // Sembunyikan loading indicator setelah proses login selesai
      hideLoadingIndicator();
    }
  }
  Future<void> performSilentLogin() async {
    try {
      // Ambil data login terakhir dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      final password = prefs.getString('password');

      if (email != null && password != null) {
        // Melakukan login ulang dengan data terakhir
        await nhost.auth.signInEmailPassword(
          email: email,
          password: password,
        );

        // Mendapatkan data pengguna setelah login ulang
        final currentUser = nhost.auth.currentUser;
        final tokenUser = nhost.auth.accessToken;

        // Menyimpan ulang data login state
        await saveLoginState(
          tokenUser.toString(),
          currentUser?.defaultRole,
          currentUser?.displayName ?? '',
          password,
          currentUser?.id ?? '',
          email,
        );

        if (currentUser?.defaultRole == 'driver') {
          await _firebaseMessaging.getToken().then((String? token) {
            assert(token != null);
            print("FCM Token: $token");

            // Simpan token dalam variabel
            fcmToken = token!;
          });
          insertFCM(token: tokenUser.toString(), tokenFCM: fcmToken.toString());
          Get.to(navBarPage(
            tokenDriver: tokenUser.toString(),
            idDriver: currentUser!.id,
            namaDriver: currentUser!.displayName,
            password: passwordText.text,
            emailDriver: currentUser.email ?? '',
          ));
        } else if (currentUser?.defaultRole == 'hrd') {
          Get.to(navBarHrdPage(idDriver: currentUser!.id, tokenDriver: tokenUser.toString(), namaDriver: currentUser!.displayName, password: passwordText.text, emailDriver: currentUser.email ?? '',));
        } else if (currentUser?.defaultRole == 'owner') {
          Get.to(navBarOwnerPage(
            idDriver: currentUser!.id,
            namaDriver: currentUser!.displayName,
            tokenDriver: tokenUser.toString(),
            password: passwordText.text,
            emailDriver: currentUser.email ?? '',
          ));
        }else if (currentUser?.defaultRole == 'ga') {
          Get.to(navBarGAPage(idDriver: currentUser!.id, tokenDriver: tokenUser.toString(), namaDriver: currentUser!.displayName, password: passwordText.text, emailDriver: currentUser.email ?? '',));
        }
      }
    } catch (error) {
      print('Gagal login ulang secara diam-diam: $error');
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


  Future<void> saveLoginState(String tokenId, String? userRole, String displayName, String password, String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tokenId', tokenId);
    prefs.setString('driverName', displayName);
    prefs.setString('userRole', userRole ?? '');
    prefs.setString('password', password);
    prefs.setString('userId', userId);
    prefs.setString('email', email);
  }

  // Future<void> checkLoginState() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final tokenId = prefs.getString('tokenId');
  //   final userRole = prefs.getString('userRole');
  //   final userName = prefs.getString('driverName');
  //   final password = prefs.getString('password');
  //   final userId = prefs.getString('userId');
  //   final email = prefs.getString('email');
  //
  //   if (tokenId != null && userRole != null) {
  //     // Pengguna sudah login, arahkan ke halaman yang sesuai berdasarkan peran
  //     if (userRole == 'driver') {
  //       await _firebaseMessaging.getToken().then((String? token) {
  //         assert(token != null);
  //         print("FCM Token: $token");
  //
  //         // Simpan token dalam variabel
  //         fcmToken = token!;
  //       });
  //       insertFCM(token: tokenId.toString(), tokenFCM: fcmToken.toString());
  //       Get.to(navBarPage(
  //         idDriver: userId.toString(),
  //         tokenDriver: tokenId.toString(),
  //         namaDriver: userName.toString(),
  //         password: password.toString(),
  //         emailDriver: email.toString(),
  //       ));
  //     } else if (userRole == 'hrd') {
  //       Get.to(navBarHrdPage(idDriver: userId.toString(), tokenDriver: tokenId.toString(), namaDriver: userName.toString(), password: password.toString(), emailDriver: email.toString(),));
  //     } else if (userRole == 'owner') {
  //       Get.to(navBarOwnerPage(
  //         idDriver: userId.toString(),
  //         namaDriver: userName.toString(),
  //         tokenDriver: tokenId.toString(),
  //         password: password.toString(),
  //         emailDriver: email.toString(),
  //       ));
  //     } else if (userRole == 'ga') {
  //       Get.to(navBarGAPage(idDriver: userId.toString(), tokenDriver: tokenId.toString(), namaDriver: userName.toString(), password: password.toString(), emailDriver: email.toString(),));
  //     }
  //   }
  // }

  void insertFCM({
    required String token,
    required String tokenFCM
  }) async {
    final HttpLink httpLink = HttpLink(
      'http://45.64.3.54:40380/absendriver-api/v1/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer ${token}', // Ganti dengan token autentikasi Anda
      },
    );

    final GraphQLClient client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );

    final MutationOptions options = MutationOptions(
      document: gql('''
      mutation MyMutation {
  insert_user_fcms_one(object: {fcm: "${tokenFCM}"}, on_conflict: {constraint: user_fcms_pkey, update_columns: fcm}) {
    fcm
  }
}
    '''),
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print('Mutation error: ${result.exception.toString()}');
    } else {
      print('Mutation successful: ${result.data}');
    }
  }

  @override
  void initState() {
    super.initState();
    // checkLoginState();
    performSilentLogin();
    Future.delayed(Duration(seconds: 3), () {
     cek.value = true;
    });
  }

  bool isObscured = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Container(
            width: screenSize.width * 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(14, 137, 145, 1),
                  Color.fromRGBO(141, 182, 188, 1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child:  Image.asset(
                            'assets/img/iconLogo.png',
                            scale: 4,
                          ),
                        )
                    ),
                  ),
                  Obx(() =>  AnimatedContainer(
                      height: cek.value ? (cekPunyaAkun.value ? 620 : 500) : 0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          color: Colors.white
                      ),
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              //Judul
                              Text(cekPunyaAkun.value ? 'Daftar Akun' : 'Selamat Datang',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),
                              ),
                              // Subjudul
                              Text(cekPunyaAkun.value ? 'Silahkan isi formulir dengan benar untuk validasi data anda.' : 'Masuk dengan menggunakan Email dan Password kamu.',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 10,),
                              // TexftField nama
                              if (cekPunyaAkun.value == true)
                                OpacityAnimatedWidget.tween(
                                  opacityEnabled: 1, //define start value
                                  opacityDisabled: 0, //and end value
                                  enabled: cekPunyaAkun.value,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text('Nama'),
                                        ],
                                      ),
                                      Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(15.0),
                                        ),
                                        child: MyCustomTextField(controller: usernameText, hintText: 'Nama'),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 10,),
                              // text field email
                              Row(
                                children: [
                                  Text('Email'),
                                ],
                              ),
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black, // Warna border
                                    width: 1.0, // Lebar border
                                  ),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: MyCustomTextField(controller: emailText, hintText: 'Email'),
                              ),

                              SizedBox(height: 10,),
                              // text field password
                              Row(
                                children: [
                                  Text('Password'),
                                ],
                              ),
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black, // Warna border
                                    width: 1.0, // Lebar border
                                  ),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child:  TextField(
                                  controller: passwordText,
                                  obscureText: isObscured, // Mengaktifkan mode password
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    filled: true,
                                    fillColor: Color.fromRGBO(239, 240, 246, 1.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          isObscured = !isObscured;
                                        });
                                      },
                                    ), // Ikona mata untuk menunjukkan/hide password
                                  ),
                                ),
                              ),

                              SizedBox(height: 10,),
                              // text field konfirmasi password
                              if (cekPunyaAkun.value == true)
                                OpacityAnimatedWidget.tween(
                                  opacityEnabled: 1, //define start value
                                  opacityDisabled: 0, //and end value
                                  enabled: cekPunyaAkun.value,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text('Konfirmasi Password'),
                                        ],
                                      ),

                                      Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black, // Warna border
                                            width: 1.0, // Lebar border
                                          ),
                                          borderRadius: BorderRadius.circular(15.0),
                                        ),
                                        child: MyCustomTextField(controller: konfirmasiPasswordText, hintText: 'Konfirmasi Password'),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 20,),
                              // button daftar atau masuk
                              Container(
                                height: 60,
                                child: CustomButton(
                                  onPressed: () {
                                    if (cekPunyaAkun == true){
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return RoundPopup();
                                        },
                                      );
                                      Future.delayed(Duration(seconds: 3), () {
                                        // Menutup dialog setelah 3 detik
                                        Navigator.pop(context);
                                        cekPunyaAkun.value = false;
                                      });
                                    }else{
                                      // print('object');

                                      performLogin();
                                      print(emailText);
                                      print(passwordText);
                                    }
                                  },
                                  width: 100,
                                  height: 100,
                                  cekSpacer: false,
                                  text: cekPunyaAkun.value ? 'Daftar' : 'Masuk',
                                  radius: 15,
                                  buttonColor: Color.fromRGBO(14, 137, 145, 1),
                                ),
                              ),
                              // Button lupa password
                              if (cekPunyaAkun == false)
                                CustomTextButton(
                                  onPressed: () {
                                    String username = "HanjayaW";

                                    // Membuat URL untuk membuka Telegram dan memulai percakapan
                                    String url = "https://t.me/$username";

                                    // Mengecek apakah URL bisa di-launch
                                    canLaunch(url).then((canLaunch) {
                                      if (canLaunch) {
                                        launch(url);
                                      } else {
                                        print('Tidak dapat membuka Telegram.');
                                      }
                                    });
                                  },
                                  text: 'Lupa Password',
                                ),

                              SizedBox(height: 50,),
                            ],
                          ),
                        ),
                      )
                  )
                  )
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class RoundPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(180.0),
      ),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          padding: EdgeInsets.all(0.0),
          child: Image.asset('assets/img/iconCheckAnimation.gif',
            scale: 4,
          ),
        ),
      ),
    );
  }
}
