import 'dart:ffi';
import 'dart:io';
import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:driverattendance/linkUtama_server.dart';
import 'package:driverattendance/main.dart';
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

class homePage extends StatefulWidget {

  final Function(int) navigateToJanjiTamu;
  String tokenDriver;
  String nameDriver;
  String idDriver;

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

  // ini untuk text field modal rencana rute
  late RxString waktuMasuk = "10:00".obs;
  late RxString waktuSelesai = "10:00".obs;
  final TextEditingController ruterText = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<Map<String, dynamic>> absenData = [];
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailApprove = [];
  List<Map<String, dynamic>> absensi = [];
  double PositionLatitude = 0;
  double PositionLongitude = 0;
  bool absen = false;

  //function untuk absen

  @override
  void initState() {
    super.initState();
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
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'Izin Sakit');
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
                            await fetchAbsensi(DateFormat('yyyy-MM-dd').format(DateTime.now()), 'PULANG');
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
                              if (absensi.isEmpty && absen == true) {
                                runMutationFunction(
                                    jam: realTime,
                                    tanggal: formattedDate,
                                    jenis: "DATANG",
                                    keterangan: ""
                                );
                              }
                              if (absensi.isEmpty && absen == true) {
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
                              }
                              if (absensi.isEmpty && absen == true)
                                Future.delayed(Duration(seconds: 1), () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              if (absensi.isNotEmpty)
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Anda sudah melakukan absen datang hari ini'),
                                ));
                              if (absen == false && absensi.isEmpty) {
                                Get.back();
                                Get.back();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Anda Tidak berada dikantor'),
                                    ));
                              }
                              absen = false;
                              if (absensi.isNotEmpty) {
                                Navigator.pop(context);
                                Get.back();
                              }
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
              content: MyCustomTextField(controller: alasanText, hintText: 'Alasan', buttonColor: Colors.white,),
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
                            if (absensi.isEmpty) {
                              runMutationFunction(
                                  jam: realTime,
                                  tanggal: formattedDate,
                                  jenis: "SAKIT",
                                  keterangan: alasanText.text
                              );
                              setState(() {
                                fetchData1();
                              });
                            }
                            if (absensi.isEmpty)
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return RoundPopup();
                                },
                              );
                            if (absensi.isEmpty)
                              Future.delayed(Duration(seconds: 1), () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              });
                            if (absensi.isNotEmpty)
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Anda sudah melakukan ijin sakit hari ini'),
                              ));
                            if (absensi.isNotEmpty) {
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
                                    keterangan: ""
                                );
                                setState(() {
                                  fetchData1();
                                });
                              }
                              if (absensi.isEmpty && absen == true)
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return RoundPopup();
                                  },
                                );
                              if (absensi.isEmpty && absen == true)
                                Future.delayed(Duration(seconds: 1), () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              if (absensi.isNotEmpty)
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Anda sudah melakukan absen datang hari ini'),
                                ));
                              if (absensi.isNotEmpty) {
                                Navigator.pop(context);
                                Get.back();
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
              title: Center(child: Text('Kamu akan melakukan Pulang awalt',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                ),
              ),
              ),
              content: MyCustomTextField(controller: alasanText, hintText: 'Alasan', buttonColor: Colors.white,),
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
                            if (absensi.isEmpty) {
                              runMutationFunction(
                                  jam: realTime,
                                  tanggal: formattedDate,
                                  jenis: "KELUAR",
                                  keterangan: alasanText.text
                              );
                              setState(() {
                                fetchData1();
                              });
                            }
                            if (absensi.isEmpty)
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return RoundPopup();
                                },
                              );
                            if (absensi.isEmpty)
                              Future.delayed(Duration(seconds: 1), () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              });
                            if (absensi.isNotEmpty)
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Anda sudah melakukan ijin sakit hari ini'),
                              ));
                            if (absensi.isNotEmpty) {
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
          heightFactor: 1.0, // Modal mengisi seluruh tinggi layar
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
                        if (namaOwner != '')
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
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_right_sharp),
                                          Text(namaOwner ?? '',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
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
                          ),
                        SizedBox(height: 15,),
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
                                          Text('Absensi ${item['jenis']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(item['jam'],
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              if (item['jenis'] != "DATANG" && item['jenis'] != "PULANG")
                                                Row(
                                                  children: [
                                                    Icon(Icons.arrow_right),
                                                    Text('Tidak Masuk Kerja')
                                                  ],
                                                )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(item['latitude'] ?? '',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.arrow_right),
                                                  Text(item['longitude'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                          if(item['jenis'] == "SAKIT")
                                           TextButton(
                                              onPressed: (){
                                                _takePictureAndUpload(item['id'].toString());
                                              }, child: Text('Upload Image'))
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
                                            Row(
                                              children: [
                                                Text(item['jam_mulai'],
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.arrow_right),
                                                    Text(item['keterangan'])
                                                  ],
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(item['latitude'] ?? '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.arrow_right),
                                                    Text(item['longitude'] ?? '',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold
                                                      ),
                                                    )
                                                  ],
                                                )
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
          jadwal_driver{
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

      print(absenData[2]['ownerData']['displayName']);
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
    latitude
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

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double distanceInMeters = await Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        -7.291266, 112.740890
      );
      PositionLatitude = position.latitude;
      PositionLongitude = position.longitude;
      if (distanceInMeters <= 25) {
        setState(() {
          PositionLatitude = position.latitude;
          PositionLongitude = position.longitude;
          absen = true;
        });
      } else {
        setState(() {
           print('kejauhan');
           absen = false;
        });
      }
      print(PositionLatitude);
      print(PositionLongitude);
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
    try {
      // Membaca isi file ke dalam byte array
      List<int> bytes = await File(imagePath).readAsBytes();

      // Upload gambar ke penyimpanan Nhost
      final fileMetadata = await nhost.storage.uploadBytes(
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileContents: bytes,
        mimeType: 'image/jpeg',
        // Tambahkan header Authorization ke dalam request
      );

      print('File berhasil diunggah dengan ID: ${fileMetadata.id}');
      runMutationFunctionImage(id: id, fileId: fileMetadata.id);
    } catch (e) {
      print('Gagal mengunggah file. Error: $e');
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
                                        },
                                        text: 'Lihat Semua',
                                      )
                                    ],
                                  ),

                                  for(var item in absenData)
                                    InkWell(
                                      onTap: () async {
                                        await fetchDataDetail(item['tanggal'], widget.idDriver);
                                        showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['ownerData'] != null ? '--> ${item['ownerData']['displayName']}' ?? '' : '');
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
                                                        Text(
                                                          item['ownerData'] != null ? '--> ${item['ownerData']['displayName']}' ?? '' : '',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                          ),
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