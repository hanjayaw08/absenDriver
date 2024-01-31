import 'dart:ffi';
import 'dart:io';
import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:driverattendance/linkUtama_server.dart';
import 'package:driverattendance/main.dart';
import 'package:driverattendance/view/home/splashScreen_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';


class homePage extends StatefulWidget {

  final Function(int) navigateToJanjiTamu;
  String tokenDriver;
  String nameDriver;
  String idDriver;// Tambahkan ini

  homePage({
    required this.tokenDriver,
    required this.nameDriver,
    required this.idDriver,
    required this.navigateToJanjiTamu,
    Key? key,
  }) : super(key: key);

  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  // ini untuk waktu menit dan detik untuk absensi
  late String formattedDate;
  late String currentTime;
  late String realTime;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String capitalizeFirstLetterOnly(String text) {
    if (text == null || text.isEmpty) {
      return text;
    }

    // Ambil huruf pertama dan ubah menjadi huruf besar
    String firstLetter = text[0].toUpperCase();

    // Ambil sisa teks dan ubah menjadi huruf kecil
    String restOfText = text.substring(1).toLowerCase();

    // Gabungkan kembali huruf pertama besar dengan sisa teks yang kecil
    return '$firstLetter$restOfText';
  }

  // ini untuk text field modal rencana rute
  late RxString waktuMasuk = "10:00".obs;
  late RxString waktuSelesai = "10:00".obs;
  final TextEditingController ruterText = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<Map<String, dynamic>> absenData = [];
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailJadwalKerja = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailApprove = [];
  List<Map<String, dynamic>> absensi = [];
  double PositionLatitude = 0;
  double PositionLongitude = 0;
  bool absen = false;
  String idImage = '';
  bool isLoding = false;
  //function untuk absen

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: $message");

      // Tampilkan notifikasi menggunakan Awesome Notifications
      AwesomeNotifications().createNotificationFromJsonData(message.data);

      // Memainkan ringtone
      FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: false,
        volume: 100,
      );

      // Tampilkan notifikasi di dalam aplikasi.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("New Notification"),
            content: Text(message.notification?.body ?? "Default Body"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    });
    var now = DateTime.now();
    formattedDate = DateFormat('yyyy-MM-d').format(now);
    currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    print('ini token ${widget.tokenDriver}');
    updateTime();
    fetchData1();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status == PermissionStatus.granted) {
      // Izin lokasi diberikan, lanjutkan dengan operasi lokasi
      _getLocation();
    } else {
      // Izin ditolak, Anda bisa memberikan feedback atau memberikan tindakan tambahan
      // seperti menampilkan pesan bahwa lokasi tidak akan dapat diakses tanpa izin
    }
  }

  void updateTime() {
    setState(() {
      Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      });
    });
  }

  void showRencanaRuterModal(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    RxBool cekKosong = false.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Rencana Ruter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    ruterText.clear();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 5,),
                            Text(
                              'Bagaimana dengan rencana rute kamu hari ini',
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 5,),
                            MyCustomTextField(controller: ruterText, hintText: 'rute', buttonColor: Colors.white,),
                            Obx(() {
                              if (cekKosong == true) {
                                return Text(
                                  '* Harus diisi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }),
                            SizedBox(height: 5,),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Waktu Mulai'),
                                    SizedBox(height: 5,),
                                    InkWell(
                                      onTap: () {
                                        _selectTime(context);
                                      },
                                      child: Container(
                                        width: screenSize.width * 0.44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.black, // Warna border yang diinginkan
                                            width: 1.0, // Ketebalan border
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Obx(() => Text(waktuMasuk.value)),
                                              Spacer(),
                                              Icon(Icons.arrow_drop_down)
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(width: 10,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Waktu Selesai'),
                                    SizedBox(height: 5,),
                                    InkWell(
                                      onTap: () {_selectTimeSelesai(context);},
                                      child: Container(
                                        width: screenSize.width * 0.44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Obx(() => Text("${waktuSelesai.value}")),
                                              Spacer(),
                                              Icon(Icons.arrow_drop_down)
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                            SizedBox(height: 15,),
                            Row(
                              children: [
                                Container(
                                  height: 50,
                                  child: CustomButton(
                                    onPressed: (){
                                      ruterText.clear();
                                      Get.back();
                                    },
                                    width: 100,
                                    height: 100,
                                    text: 'Batal',
                                    radius: 10,
                                    cekSpacer: false,
                                    textColor: Colors.red,
                                    buttonColor: Colors.white,
                                    borderColor: Colors.transparent,
                                  ),
                                ),
                                SizedBox(width: 10,),
                                Expanded(
                                  child:  Container(
                                    height: 50,
                                    child: CustomButton(
                                      onPressed: (){
                                        if (ruterText.text == ''){
                                          cekKosong.value = true;
                                        }else{
                                          runMutationFunctionRute(
                                              jam_mulai: waktuMasuk.toString(),
                                              jam_selesai: waktuSelesai.toString(),
                                              keterangan: ruterText.text,
                                              tanggal: formattedDate);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return RoundPopup();
                                            },
                                          );
                                          ruterText.clear();
                                          cekKosong.value = false;
                                          Future.delayed(Duration(seconds: 3), () {
                                            Get.back();
                                            Get.back();
                                          });
                                        }
                                      },
                                      width: 100,
                                      height: 100,
                                      text: 'Kirim',
                                      radius: 10,
                                      cekSpacer: false,
                                      textColor: Colors.white,
                                      buttonColor: Color.fromRGBO(14, 137, 145, 1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  // ini function untuk pop up absensi
  void showKonfirmasiMenuAbsensiModal(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            child: Wrap(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Menu Absensi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      if (absenData[0]['has_absen'] == false || absensi.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'DATANG');
                            await _getLocation();
                            _showPopupKonfirmasiAbsensi(context, PositionLatitude, PositionLongitude);
                          },
                          child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                color: Color.fromRGBO(14, 137, 145, 1),
                              ),
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        'assets/img/backgroundHome.png',
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text('Absensi masuk',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.white
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.login,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                      SizedBox(height: 15,),
                      if (absenData[0]['has_absen'] == false || absensi.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'SAKIT');
                            _getLocation();
                            _showPopupKonfirmasiIjinSakit(context, PositionLatitude, PositionLongitude);
                          },
                          child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                color: Color.fromRGBO(207, 255, 208, 1),
                              ),
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        'assets/img/backgroundHome.png',
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text('Ijin Sakit',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.file_present,
                                          color: Colors.black,
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                      if (absenData[0]['has_absen'] == true && absensi.isEmpty)
                        InkWell(
                          onTap: () async {
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'PULANG');
                            await _getLocation();
                            _showPopupKonfirmasiPulang(context, PositionLatitude, PositionLongitude);
                          },
                          child:  Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                color: Colors.red,
                              ),
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        'assets/img/backgroundHome.png',
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text('Absensi pulang',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.white
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.logout,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                      SizedBox(height: 15,),
                      if (absenData[0]['has_absen'] == true && absensi.isEmpty)
                        InkWell(
                          onTap: () async {
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'KELUAR');
                            await _getLocation();
                            _showPopupKonfirmasiIjinPulang(context, PositionLatitude, PositionLongitude);
                          },
                          child:  Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                color: Colors.grey,
                              ),
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        'assets/img/backgroundHome.png',
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text('Pulang Lebih Awal',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.white
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.logout,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showPopupKonfirmasiAbsensi(BuildContext context, double PositionLatitude, double PositionLongitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {

            realTime = DateFormat('HH:mm:ss').format(DateTime.now());
            Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                realTime = DateFormat('HH:mm:ss').format(DateTime.now());
              });
            });

            return AlertDialog(
              title: Center(child: Text('Kamu akan melakukan absensi pada',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(realTime,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      child: CustomButton(
                        onPressed: (){
                          Get.back();
                        },
                        width: 100,
                        height: 100,
                        text: 'Batal',
                        radius: 10,
                        cekSpacer: false,
                        textColor: Colors.red,
                        buttonColor: Colors.white,
                        borderColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(width: 10,),
                        Expanded(
                        child:  Container(
                          height: 50,
                          child: CustomButton(
                            onPressed: (){
                              // if (absensi.isEmpty && absen == true) {
                              //   // runMutationFunction(
                              //   //     jam: realTime,
                              //   //     tanggal: formattedDate,
                              //   //     jenis: "DATANG",
                              //   //     keterangan: "",
                              //   //     imagesId: ""
                              //   // );
                              // }
                              if (absensi.isEmpty && absen == true) {
                                fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'SAKIT').then((value){
                                  if(absensi.isEmpty) {
                                    runMutationFunction(
                                        jam: realTime,
                                        tanggal: formattedDate,
                                        jenis: "DATANG",
                                        keterangan: "",
                                        imagesId: ""
                                    );
                                    setState(() {
                                      // Lakukan sesuatu setelah setState selesai
                                      fetchData1();
                                      // Update UI atau lakukan aksi lainnya jika diperlukan
                                    });
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return RoundPopup();
                                      },
                                    );
                                    setState(() {
                                      // Lakukan sesuatu setelah setState selesai
                                      fetchData1();
                                      // Update UI atau lakukan aksi lainnya jika diperlukan
                                    });
                                    Future.delayed(Duration(seconds: 1), () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    });
                                  }else{
                                    print('sakit');
                                    Get.back();
                                    Get.back();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Anda sudah melakukan absen Sakit hari ini'),
                                        ));
                                  }
                                });
                              }
                              if (absensi.isNotEmpty) {
                                Navigator.pop(context);
                                Get.back();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Anda sudah melakukan absen datang hari ini'),
                                    ));
                              }
                              if (absen == false && absensi.isEmpty) {
                                absen = false;
                                Get.back();
                                Get.back();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Anda Tidak berada dikantor'),
                                    ));
                              }
                              setState(() {
                                // Lakukan sesuatu setelah setState selesai
                                fetchData1();
                                // Update UI atau lakukan aksi lainnya jika diperlukan
                              });
                            },
                            width: 100,
                            height: 100,
                            text: 'Konfirmasi Absensi',
                            radius: 10,
                            cekSpacer: false,
                            textColor: Colors.white,
                            buttonColor: Color.fromRGBO(14, 137, 145, 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showPopupKonfirmasiIjinSakit(BuildContext context, double PositionLatitude, double PositionLongitude) {
    final TextEditingController alasanText = TextEditingController();
    RxBool cekKosong = true.obs;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {

            realTime = DateFormat('HH:mm:ss').format(DateTime.now());
            Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                realTime = DateFormat('HH:mm:ss').format(DateTime.now());
              });
            });

            return AlertDialog(
              title: Center(child: Text('Kamu akan melakukan Ijin Sakit',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
              content:  Container(
                height: 140,
                child:  Column(children: [
                  MyCustomTextField(controller: alasanText, hintText: 'Alasan', buttonColor: Colors.white,),
                  Obx(() {
                    if (cekKosong.value == false) {
                      return Text(
                        'Alasan Harus Diisi *',
                        style: TextStyle(color: Colors.red),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),
                  TextButton(
                      onPressed: (){
                        _takePictureAndUpload('');
                      }, child: Text('Upload Image'))
                ],),
              ),
              actions: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      child: CustomButton(
                        onPressed: (){
                          Get.back();
                        },
                        width: 100,
                        height: 100,
                        text: 'Batal',
                        radius: 10,
                        cekSpacer: false,
                        textColor: Colors.red,
                        buttonColor: Colors.white,
                        borderColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child:  Container(
                        height: 50,
                        child: CustomButton(
                          onPressed: (){
                            if (alasanText.text.isEmpty){
                              cekKosong.value = false;
                            }else{
                              cekKosong.value = true;
                            }
                            if (absensi.isEmpty && alasanText.text != '') {
                              runMutationFunction(
                                  jam: realTime,
                                  tanggal: formattedDate,
                                  jenis: "SAKIT",
                                  keterangan: alasanText.text,
                                  imagesId: idImage
                              );
                              setState(() {
                                fetchData1();
                              });
                              setState(() {
                                // Lakukan sesuatu setelah setState selesai
                                fetchData1();
                                // Update UI atau lakukan aksi lainnya jika diperlukan
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return RoundPopup();
                                },
                              );
                              setState(() {
                                // Lakukan sesuatu setelah setState selesai
                                fetchData1();
                                // Update UI atau lakukan aksi lainnya jika diperlukan
                              });
                              Future.delayed(Duration(seconds: 1), () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              });
                            }
                            if (absensi.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Anda sudah melakukan ijin sakit hari ini'),
                                  )
                              );
                              Get.back();
                              Get.back();
                            }
                            setState(() {
                              // Lakukan sesuatu setelah setState selesai
                              fetchData1();
                              // Update UI atau lakukan aksi lainnya jika diperlukan
                            });
                          },
                          width: 100,
                          height: 100,
                          text: 'Kirimkan',
                          radius: 10,
                          cekSpacer: false,
                          textColor: Colors.white,
                          buttonColor: Color.fromRGBO(14, 137, 145, 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showPopupKonfirmasiPulang(BuildContext context, double PositionLatitude, double PositionLongitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {

            realTime = DateFormat('HH:mm:ss').format(DateTime.now());
            Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                realTime = DateFormat('HH:mm:ss').format(DateTime.now());
              });
            });

            return AlertDialog(
              title: Center(child: Text('Kamu akan melakukan absen pulang',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                ),
              ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(realTime,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      child: CustomButton(
                        onPressed: (){
                          Get.back();
                        },
                        width: 100,
                        height: 100,
                        text: 'Batal',
                        radius: 10,
                        cekSpacer: false,
                        textColor: Colors.red,
                        buttonColor: Colors.white,
                        borderColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(width: 10,),
                      Expanded(
                        child:  Container(
                          height: 50,
                          child: CustomButton(
                            onPressed: (){
                              if (absensi.isEmpty && absen == true){
                                runMutationFunction(
                                    jam: realTime,
                                    tanggal: formattedDate,
                                    jenis: "PULANG",
                                    keterangan: "",
                                    imagesId: ""
                                );
                                setState(() {
                                  fetchData1();
                                });
                                setState(() {
                                  // Lakukan sesuatu setelah setState selesai
                                  fetchData1();
                                  // Update UI atau lakukan aksi lainnya jika diperlukan
                                });
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return RoundPopup();
                                  },
                                );
                                setState(() {
                                  // Lakukan sesuatu setelah setState selesai
                                  fetchData1();
                                  // Update UI atau lakukan aksi lainnya jika diperlukan
                                });
                                Future.delayed(Duration(seconds: 1), () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              }
                              if (absensi.isNotEmpty) {
                                Navigator.pop(context);
                                Get.back();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Anda sudah melakukan absen pulang hari ini'),
                                ));
                              }
                              if (absen == false && absensi.isEmpty) {
                                Get.back();
                                Get.back();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Anda Tidak berada dikantor'),
                                    ));
                              }
                              setState(() {
                                // Lakukan sesuatu setelah setState selesai
                                fetchData1();
                                // Update UI atau lakukan aksi lainnya jika diperlukan
                              });
                            },
                            width: 100,
                            height: 100,
                            text: 'Absensi Pulang',
                            radius: 10,
                            cekSpacer: false,
                            textColor: Colors.white,
                            buttonColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showPopupKonfirmasiIjinPulang(BuildContext context, double PositionLatitude, double PositionLongitude) {
    final TextEditingController alasanText = TextEditingController();
    RxBool cekKosong = true.obs;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {

            realTime = DateFormat('HH:mm:ss').format(DateTime.now());
            Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                realTime = DateFormat('HH:mm:ss').format(DateTime.now());
              });
            });

            return AlertDialog(
              title: Center(child: Text('Kamu akan melakukan Pulang awal',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                ),
              ),
              ),
              content: Container(
                height: 120,
                child: Column(
                  children: [
                    MyCustomTextField(controller: alasanText, hintText: 'Alasan', buttonColor: Colors.white,),
                    Obx(() {
                      if (cekKosong.value == false) {
                        return Text(
                          'Alasan Harus Diisi *',
                          style: TextStyle(color: Colors.red),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      child: CustomButton(
                        onPressed: (){
                          Get.back();
                        },
                        width: 100,
                        height: 100,
                        text: 'Batal',
                        radius: 10,
                        cekSpacer: false,
                        textColor: Colors.red,
                        buttonColor: Colors.white,
                        borderColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child:  Container(
                        height: 50,
                        child: CustomButton(
                          onPressed: (){
                            if(alasanText.text == ''){
                              cekKosong.value = false;
                            }else{
                              cekKosong.value = true;
                            }
                            if (absensi.isEmpty && alasanText.text != '') {
                              fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'PULANG').then((value){
                                if(absensi.isEmpty){
                                  runMutationFunction(
                                      jam: realTime,
                                      tanggal: formattedDate,
                                      jenis: "KELUAR",
                                      keterangan: alasanText.text,
                                      imagesId: ""
                                  );
                                  setState(() {
                                    fetchData1();
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return RoundPopup();
                                    },
                                  );
                                  Future.delayed(Duration(seconds: 1), () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  });
                                }else{
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Anda sudah melakukan absen pulang hari ini'),
                                  ));
                                  Navigator.pop(context);
                                  Get.back();
                                }
                              });
                            }
                            if (absensi.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Anda sudah melakukan ijin pulang hari ini'),
                              ));
                              Navigator.pop(context);
                              Get.back();
                            }
                          },
                          width: 100,
                          height: 100,
                          text: 'Kirimkan',
                          radius: 10,
                          cekSpacer: false,
                          textColor: Colors.white,
                          buttonColor: Color.fromRGBO(14, 137, 145, 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ini function untuk memilih waktu
  Future<void> _selectTime(BuildContext context) async {
    // Dapatkan waktu saat ini
    TimeOfDay currentTime = TimeOfDay.now();

    // Tampilkan dialog time picker
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    // Proses waktu yang dipilih
    if (selectedTime != null) {
      // Format waktu dengan jam dan menit
      String formattedHour = selectedTime.hour.toString().padLeft(2, '0');
      String formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
      waktuMasuk.value = "${formattedHour}:${formattedMinute}";
      print('Waktu yang dipilih: $waktuMasuk');
    } else {
      waktuMasuk.value = '${currentTime.hour} : ${currentTime.minute}';
    }
  }
  Future<void> _selectTimeSelesai(BuildContext context) async {
    // Dapatkan waktu saat ini
    TimeOfDay currentTime = TimeOfDay.now();

    // Tampilkan dialog time picker
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    // Proses waktu yang dipilih
    if (selectedTime != null) {
      // Format waktu dengan jam dan menit
      String formattedHour = selectedTime.hour.toString().padLeft(2, '0');
      String formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
      waktuSelesai.value = "${formattedHour}:${formattedMinute}";
      print('Waktu yang dipilih: $waktuSelesai');
    } else {
      waktuSelesai.value = '${currentTime.hour} : ${currentTime.minute}';
    }
  }

  void showDetailAbsensiModal(BuildContext context, bool cekKosong, String tanggal, String namaOwner) {
    final screenSize = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Atur isScrollControlled ke true agar modal dapat di-scroll
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 1.0,
          widthFactor: 1.0, // Modal mengisi seluruh lebar layar
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 25,),
                  Row(
                    children: [
                      Text(
                        'Detail absensi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                          // print(widget.tokenDriver);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  Text(
                    "${ DateFormat('EEEE, d MMM y', 'id').format(DateTime.parse(tanggal))}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15,),
                  if (cekKosong == true)
                    Column(
                      children: [
                        for(var item in detailJadwalKerja)
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                  color: Color.fromRGBO(218, 218, 218, 1),
                                  border: Border.all(
                                    color: Colors.black, // Warna border yang diinginkan
                                    width: 1.0, // Ketebalan border
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('Ditugaskan ke',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: screenSize.width * 0.6,
                                            child: Wrap(
                                              children: [
                                                Icon(Icons.arrow_right_sharp),
                                                Text(item['owner']['displayName'] ?? '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),

                                      Spacer(),

                                      if (detailApprove[0]['has_approve'] == true)
                                        Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        )
                                      else
                                        Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 15,)
                            ],
                          ),
                        // SizedBox(height: 15,),
                        for(var item in detailBbsenData)
                          Column(
                            children: [
                              InkWell(
                                onTap: (){MapsLauncher.launchCoordinates(double.parse(item['latitude']), double.parse(item['longitude']));},
                                child:  Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                    color: Color.fromRGBO(218, 218, 218, 1),
                                    border: Border.all(
                                      color: Colors.black, // Warna border yang diinginkan
                                      width: 1.0, // Ketebalan border
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (item['jenis'] == "DATANG")
                                          Icon(
                                            Icons.login,
                                            color: Colors.green,
                                          )
                                        else
                                          Icon(
                                            Icons.logout,
                                            color: Colors.red,
                                          ),

                                        SizedBox(width: 10,),

                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Absensi ${item['jenis'] == 'KELUAR' ? 'Pulang Lebih Awal' : capitalizeFirstLetterOnly(item['jenis'])}',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              width: screenSize.width * 0.6,
                                              child: Wrap(
                                                children: [
                                                  Text(item['jam'],
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  if (item['jenis'] != "DATANG" && item['jenis'] != "PULANG")
                                                    Wrap(
                                                      children: [
                                                        Icon(Icons.arrow_right),
                                                        Text(item['keterangan'] ?? '')
                                                      ],
                                                    )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: screenSize.width * 0.6,
                                              child:  Wrap(
                                                children: [
                                                  Text(
                                                    item['latitude'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Icon(Icons.arrow_right),
                                                  Text(
                                                    item['longitude'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if(item['jenis'] == "SAKIT")
                                              Row(
                                                children: [
                                                  TextButton(
                                                        onPressed: () async {
                                                          _takePictureAndUpload(item['id'].toString());
                                                        }, child: Text('Upload Image')),
                                                  TextButton(
                                                      onPressed: (){
                                                        print(item['files']);
                                                        getPresignedUrl('${item['files']}');
                                                      }, child: Text('Open Image'))
                                                ],
                                              )
                                          ],
                                        ),

                                        Spacer(),

                                        if (detailApprove[0]['has_approve'] == true)
                                          Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        else
                                          Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),),
                              SizedBox(height: 15,),
                            ],
                          ),
                        for(var item in detailRencanaRute)
                          Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  MapsLauncher.launchCoordinates(double.parse(item['latitude']), double.parse(item['longitude']));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                    color: Color.fromRGBO(218, 218, 218, 1),
                                    border: Border.all(
                                      color: Colors.black, // Warna border yang diinginkan
                                      width: 1.0, // Ketebalan border
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.place,
                                          color: Colors.green,
                                        ),

                                        SizedBox(width: 10,),

                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Rencana Rute',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              width: screenSize.width * 0.6,
                                              child: Wrap(
                                                children: [
                                                  Text(item['jam_mulai'],
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Icon(Icons.arrow_right),
                                                  Text(item['keterangan'] ?? '')
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: screenSize.width * 0.6,
                                              child:  Wrap(
                                                children: [
                                                  Text(
                                                    item['latitude'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Icon(Icons.arrow_right),
                                                  Text(
                                                    item['longitude'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        Spacer(),

                                        if (detailApprove[0]['has_approve'] == true)
                                          Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        else
                                          Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15,),
                            ],
                          ),
                      ],
                    ),
                  if (detailApprove[0]['has_approve'] == true)
                    Text('Laporan telah di Approve pada ${detailApprove[0]['tanggal']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (cekKosong == false)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenSize.height * 0.25,),
                        Image.asset('assets/img/BeepBeepUFO.png',
                          scale: 3,
                        ),
                        Text('Tidak ada kegiatan absensi terekam')
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // func untuk input absen
  void runMutationFunction({
    required String jam,
    required String tanggal,
    required String jenis,
    required String keterangan,
    required String imagesId,
  }) async {
    final HttpLink httpLink = HttpLink(
      'http://45.64.3.54:40380/absendriver-api/v1/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
      },
    );

    final GraphQLClient client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );

    final MutationOptions options = MutationOptions(
      document: gql('''
      mutation MyMutation {
        insert_absen_one(object: {
          jam: "$jam",
          tanggal: "$tanggal",
          jenis: "$jenis",
          keterangan: "$keterangan",
          latitude: "$PositionLatitude", 
          longitude: "$PositionLongitude",
          files: "$imagesId"
        }) {
          id
        }
      }
    '''),
    );

    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      print('Mutation error: ${result.exception.toString()}');
    } else {
      fetchData1();
      print('Mutation successful: ${result.data}');
    }
  }

  void runMutationFunctionImage({
    required String id,
    required String fileId,
  }) async {
    final HttpLink httpLink = HttpLink(
      'http://45.64.3.54:40380/absendriver-api/v1/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
      },
    );

    final GraphQLClient client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );

    final MutationOptions options = MutationOptions(
      document: gql('''
      mutation MyMutation {
  update_absen(where: {id: {_eq: "$id"}}, _set: {files: "$fileId"}) {
    affected_rows
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

  void runMutationFunctionRute({
    required String jam_mulai,
    required String jam_selesai,
    required String keterangan,
    required String tanggal,
  }) async {
    final HttpLink httpLink = HttpLink(
      'http://45.64.3.54:40380/absendriver-api/v1/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
      },
    );

    final GraphQLClient client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );

    final MutationOptions options = MutationOptions(
      document: gql('''
      mutation MyMutation {
        insert_rencana_rute_one(object: {
          jam_mulai: "$jam_mulai",
          jam_selesai: "$jam_selesai",
          keterangan: "$keterangan",
          tanggal: "$tanggal",
          latitude: "$PositionLatitude", 
          longitude: "$PositionLongitude"
        }) {
          id
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

  Future<void> fetchData1() async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
        query MyQuery {
          status_absen(
            where: {
              tanggal: {
                _lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 7)))}"
              }
            },
            order_by: {tanggal: desc}
          ) {
            driver {
              displayName
            }
            user_id
            has_absen
            tanggal
            has_approve
          }
          jadwal_driver (where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}", _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 7)))}"}, _and: {active: {_eq: true}}}) {
            driver_id  
            id
            tanggal
            owner {
              displayName
            }
            owner_id
          }
        }
      '''),
      ),
    );

    if (result.hasException) {
      print('Error Cuy: ${result.exception.toString()}');
      print(widget.tokenDriver);
    } else {
      List<Map<String, dynamic>> statusAbsenData = List<Map<String, dynamic>>.from(result.data?['status_absen'] ?? []);
      List<Map<String, dynamic>> jadwalData = List<Map<String, dynamic>>.from(result.data?['jadwal_driver'] ?? []);

      // Membuat Map untuk mengakses ownerData berdasarkan driver_id dan tanggal
      Map<String, Map<String, dynamic>> ownerDataMap = {};
      for (var jadwal in jadwalData) {
        String driverId = jadwal['driver_id'];
        String tanggal = jadwal['tanggal'];
        Map<String, dynamic> owner = jadwal['owner'] ?? {};
        ownerDataMap['$driverId-$tanggal'] = owner;
      }

      // Menggabungkan hasil dari status_absen dan jadwal_driver
      for (var absen in statusAbsenData) {
        String driverId = absen['user_id'];
        String tanggal = absen['tanggal'];
        Map<String, dynamic>? owner = ownerDataMap['$driverId-$tanggal'];

        if (owner != null) {
          // Menambahkan data owner ke dalam status_absen
          absen['ownerData'] = owner;
        }
      }

      // Hasil akhir diassign ke absenData
      absenData = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }
    }
  }
  Future<void> fetchDataDetail(String tanggal, String idDriver) async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
          query MyQuery {
  absen(where: {tanggal: {_eq: "$tanggal"}, _and: {user_id: {_eq: "$idDriver"}}}) {
    jam
    jenis
    tanggal
    longitude
    files
    latitude
    keterangan
    id
  }
  rencana_rute(where: {user_id: {_eq: "$idDriver"}, _and: {tanggal: {_eq: "$tanggal"}}}) {
    jam_mulai
    jam_selesai
    keterangan
    tanggal
    user_id
    longitude
    latitude
  }
  status_absen(where: {tanggal: {_eq: "$tanggal"}}) {
    has_absen
    tanggal
    has_approve
  }
  jadwal_driver(where: {tanggal: {_eq: "$tanggal"}, _and: {driver_id: {_eq: "$idDriver"}}}) {
    owner_id
    tanggal
    owner {
      displayName
    }
  }
}
      '''),
      ),
    );

    if (result.hasException) {
      print('Error: ${result.exception.toString()}');
    } else {
      detailBbsenData = List<Map<String, dynamic>>.from(result.data?['absen'] ?? []);
      detailRencanaRute = List<Map<String, dynamic>>.from(result.data?['rencana_rute'] ?? []);
      detailApprove = List<Map<String, dynamic>>.from(result.data?['status_absen'] ?? []);
      detailJadwalKerja = List<Map<String, dynamic>>.from(result.data?['jadwal_driver'] ?? []);
      // Hasilnya adalah groupedData yang berisi data yang sudah dikelompokkan berdasarkan tanggal
    }
  }
  Future<void> fetchAbsensi(String tanggal, String jenis) async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
query MyQuery {
  absen(where: {tanggal: {_eq: "$tanggal"}, _and: {user_id: {_eq: "${widget.idDriver}"}, jenis: {_eq: "$jenis"}}}) {
    jam
    jenis
    tanggal
  }
}
      '''),
      ),
    );

    if (result.hasException) {
      print('Error: ${result.exception.toString()}');
    } else {
      absensi = List<Map<String, dynamic>>.from(result.data?['absen'] ?? []);
      print(absensi);
    }
  }

  Future<void> refreshData() async {
    // Tambahkan logika pembaruan data di sini
    await fetchData1();
  }

  // Future<void> _getLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //       forceAndroidLocationManager: true,
  //     );
  //
  //     double distanceInMeters = await Geolocator.distanceBetween(
  //       position.latitude,
  //       position.longitude,
  //       -7.291266, 112.740890
  //     );
  //     PositionLatitude = position.latitude;
  //     PositionLongitude = position.longitude;
  //     if (distanceInMeters <= 25) {
  //       setState(() {
  //         PositionLatitude = position.latitude;
  //         PositionLongitude = position.longitude;
  //         absen = true;
  //       });
  //     } else {
  //       setState(() {
  //          print('kejauhan');
  //          absen = false;
  //       });
  //     }
  //     print(PositionLatitude);
  //     print(PositionLongitude);
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  Future<void> _getLocation() async {
    final double maxSpeed = 10; // Sesuaikan dengan kecepatan maksimal yang dianggap wajar
    bool isUsingFakeGPS = false;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );

      // Mengecek kecepatan
      double speedInMps = position.speed ?? 0;
      if (speedInMps > maxSpeed) {
        setState(() {
          isUsingFakeGPS = true;
        });
      } else {
        setState(() {
          isUsingFakeGPS = false;
        });

        // Lanjutkan pengecekan jarak dan tindakan lainnya jika perlu
        double distanceInMeters = await Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          -7.291266,
          112.740890,
        );

        setState(() {
          PositionLatitude = position.latitude;
          PositionLongitude = position.longitude;
          absen = distanceInMeters <= 25;
        });

        if (distanceInMeters <= 25) {
          print('Absen berhasil, jarak: $distanceInMeters meter');
          if(isUsingFakeGPS == false){
             showDialog(
              context: context,
               barrierDismissible: false,
               builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Peringatan'),
                  content: Text('Terdeteksi penggunaan GPS palsu!'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        await EasyLoading.isShow;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('email');
                        await prefs.remove('password');
                        EasyLoading.isShow;
                        await nhost.auth.signOut();
                        await AwesomeNotifications().cancelAll();
                        await _firebaseMessaging.deleteToken();
                        EasyLoading.dismiss();
                        await EasyLoading.dismiss();
                        Get.offAll(splashScreenPage());
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }else{
            absen = true;
          }
        } else {
          print('Terlalu jauh, jarak: $distanceInMeters meter');
          absen = false;
        }
      }

      print('Position Latitude: ${position.latitude}');
      print('Position Longitude: ${position.longitude}');
    } catch (e) {
      print('Error: $e');
    }
  }


  List<int> numberList = [0, 1, 0, 0, 0, 0];
  List<int> numberList1 = [1,1];

  Future<void> _takePictureAndUpload(String id) async {
    try {
      final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (file != null) {
        // Upload gambar ke penyimpanan Nhost
        await uploadImage(file.path, id);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> uploadImage(String imagePath, String id) async {
    EasyLoading.show();
    try {
      // Membaca isi file ke dalam byte array
      setState(() {
        isLoding = true;
      });
      List<int> bytes = await File(imagePath).readAsBytes();

      // Upload gambar ke penyimpanan Nhost
      final fileMetadata = await nhost.storage.uploadBytes(
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileContents: bytes,
        mimeType: 'image/jpeg',
        // Tambahkan header Authorization ke dalam request
      );
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File berhasil diunggah dengan ID: ${fileMetadata.id}'),
          ));
      print('File berhasil diunggah dengan ID: ${fileMetadata.id} ');
      setState(() {
        idImage = fileMetadata.id;
      });
      setState(() {
        isLoding = false;
      });
      runMutationFunctionImage(id: id, fileId: fileMetadata.id);
    } catch (e) {
      showDialog(
        context: context, // pastikan ada parameter context
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Gagal Menggunggah'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // tutup dialog saat tombol ditekan
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      print('Gagal mengunggah file. Error: $e');
    } finally {
      EasyLoading.dismiss();
      showDialog(
        context: context, // pastikan ada parameter context
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Behasil'),
            content: Text('Berhasil Menggunggah'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // tutup dialog saat tombol ditekan
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> openUrl(String url) async {
    if (await canLaunch('$url')) {
      await launch('$url');
    } else {
      print('Tidak dapat membuka URL: $url');
    }
  }

  void openLinkInBrowser(String url) async {
    try {
      await launch('$url');
    } catch (e) {
      print('Tidak dapat membuka tautan di browser: $e');
    }
  }

  Future<String?> getPresignedUrl(String fileId) async {
    final apiUrl = 'http://45.64.3.54:40380/absendriver-api/v1/storage/files/$fileId/presignedurl';
    try {
      final response = await http.get(Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer ${widget.tokenDriver}'},
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String presignedUrl = responseData['url'];
        print(responseData['url']);
        openLinkInBrowser(responseData['url']);
        return presignedUrl;
      } else {
        print('Failed to get presigned URL. Status code: ${response.statusCode}');
        showDialog(
          context: context, // pastikan ada parameter context
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Foto tidak ada'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // tutup dialog saat tombol ditekan
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return 'Foto tidak ada';
      }
    } catch (error) {
      print('Error getting presigned URL: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return WillPopScope(
        child: Scaffold(
          appBar: null,
          body: Container(
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
                  SizedBox(height: 25),
                  Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/img/backgroundHome.png',
                            scale: 2,
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Selamat Pagi, ${widget.nameDriver}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  color: Colors.white
                              ),
                            ),
                            Text('Tingkatkan produktivitas Anda sekarang',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  Expanded(child: Container(
                    // height: screenSize.height * 0.8,
                      width: screenSize.width * 1,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          color: Colors.white
                      ),
                      child: RefreshIndicator(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[

                                  Text(DateFormat('EEEE, d MMM y', 'id').format(DateTime.now()),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    ),
                                  ),

                                  SizedBox(height: 15,),

                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                      color: Color.fromRGBO(218, 218, 218, 1),
                                      border: Border.all(
                                        color: Colors.black, // Warna border yang diinginkan
                                        width: 1.0, // Ketebalan border
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_box,
                                            color:Colors.green,
                                          ),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(currentTime,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text('Jadwal masuk kamu jam 08:00 Wib',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w300
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 15,),

                                  Row(
                                    children: [
                                      Expanded(
                                        child:  Container(
                                          height: 50,
                                          child: CustomButton(
                                            onPressed: () async {
                                              await fetchData1();
                                              await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'SAKIT');
                                              print(absensi);
                                              showKonfirmasiMenuAbsensiModal(context);
                                            },
                                            width: 100,
                                            height: 100,
                                            text: 'Menu Absensi',
                                            radius: 10,
                                            cekSpacer: false,
                                            textColor: Colors.white,
                                            buttonColor: Color.fromRGBO(14, 137, 145, 1),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10,),
                                      Expanded(
                                          child: Container(
                                            height: 50,
                                            child: CustomButton(
                                              onPressed: () async {
                                                await _getLocation();
                                                showRencanaRuterModal(context);
                                              },
                                              width: 100,
                                              height: 100,
                                              text: 'Rencana Rute',
                                              radius: 10,
                                              cekSpacer: false,
                                              textColor: Color.fromRGBO(14, 137, 145, 1),
                                              buttonColor: Colors.white,
                                              borderColor: Color.fromRGBO(14, 137, 145, 1),
                                            ),
                                          )
                                      )
                                    ],
                                  ),

                                  SizedBox(height: 15,),

                                  Row(
                                    children: [
                                      Text('Riwayat Absensi',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16
                                        ),
                                      ),
                                      Spacer(),
                                      CustomTextButton(
                                        onPressed: () async {
                                          widget.navigateToJanjiTamu(1);
                                          print(widget.tokenDriver);
                                        },
                                        text: 'Lihat Semua',
                                      )
                                    ],
                                  ),

                                  for(var item in absenData)
                                    InkWell(
                                      onTap: () async {
                                        await fetchDataDetail(item['tanggal'], widget.idDriver);
                                        showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['ownerData'] != null ? ' ${item['ownerData']['displayName']}' ?? '' : '');
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                              color: Color.fromRGBO(218, 218, 218, 1),
                                              border: Border.all(
                                                color: Colors.black, // Warna border yang diinginkan
                                                width: 1.0, // Ketebalan border
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  if (item['has_absen'] == false)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red, // Warna latar belakang
                                                      ),
                                                      padding: EdgeInsets.all(0.0), // Jarak antara ikon dan latar belakang
                                                      child: Icon(
                                                        Icons.close,
                                                        color: Colors.white, // Warna ikon
                                                        size: 20.0, // Ukuran ikon
                                                      ),
                                                    )
                                                  else
                                                    Icon(
                                                      Icons.check_box,
                                                      color: Colors.green,
                                                    ),

                                                  SizedBox(width: 10,),

                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(DateFormat('EEEE, d MMM y', 'id').format(DateTime.parse(item['tanggal'])),
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold
                                                        ),
                                                      ),
                                                      if (item['ownerData'] != null)
                                                        Row(
                                                          children: [
                                                            Icon(Icons.arrow_right_alt_outlined),
                                                            Text(
                                                              item['ownerData'] != null ? '${item['ownerData']['displayName']}' ?? '' : '',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (item['has_absen'] == false)
                                                        Text('Tidak ada aktifitas terekam',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w300
                                                          ),
                                                        ),
                                                      if (item['has_approve'] == false && item['has_absen'] == true)
                                                        Text('Laporan Belum Diapprove',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w300
                                                          ),
                                                        ),
                                                      if (item['has_approve'] == true)
                                                        Text('Laporan Sudah Diapprove',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w300
                                                          ),
                                                        )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 15,),
                                        ],
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                          onRefresh: refreshData)
                  )
                  )
                ],
              ),
            ),
          ),
        ),
        onWillPop: () async {
          return false;
        });
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
