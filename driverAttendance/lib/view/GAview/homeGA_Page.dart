import 'package:driverattendance/coba_pdf.dart';
import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class homeGAPage extends StatefulWidget {
  final Function(int) navigateToJanjiTamu;
  String tokenDriver;
  String idDriver;
  String nameDriver;

  homeGAPage({
    required this.idDriver,
    required this.tokenDriver,
    required this.nameDriver,
    required this.navigateToJanjiTamu,
    Key? key,
  }) : super(key: key);

  @override
  _homeGAPageState createState() => _homeGAPageState();
}

class _homeGAPageState extends State<homeGAPage> {
  // ini untuk waktu menit dan detik untuk absensi
  late String formattedDate;
  late String currentTime;
  late String realTime;

  // ini untuk text field modal rencana rute
  late RxString waktuMasuk = "10:00".obs;
  late RxString waktuSelesai = "10:00".obs;
  final TextEditingController ruterText = TextEditingController();
  final TextEditingController alasanText = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<Map<String, dynamic>> absenData = [];
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailApprove = [];
  List<Map<String, dynamic>> detailJadwalKerja = [];
  List<Map<String, dynamic>> latestItems = [];
  List<int> absenID = [];
  List<int> ruterID = [];
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

  //function untuk absen

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
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

  void showRencanaRuterModal(BuildContext context, String idDriver) {
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
                                  'Request Jemput',
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
                            SizedBox(height: 10,),
                            Text(
                              'Informasikan lokasi/tempat penjemputan',
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10,),
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
                                return Container(); // Widget kosong jika tidak perlu menampilkan pesan.
                              }
                            }),
                            SizedBox(height: 10,),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Waktu Jemput'),
                                    SizedBox(height: 10,),
                                    InkWell(
                                      onTap: () {
                                        _selectTime(context);
                                      },
                                      child: Container(
                                        width: screenSize.width * 0.89,
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
                              ],
                            ),
                            SizedBox(height: 15,),
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
                                        if(ruterText.text == ''){
                                          cekKosong.value = true;
                                        }else{
                                          runMutationFunctionRute(jam_mulai: waktuMasuk.toString(), keterangan: ruterText.text, driverId: idDriver);
                                          ruterText.clear();
                                          waktuMasuk.value = "10:00";
                                          Get.back();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return RoundPopup();
                                            },
                                          );
                                          Future.delayed(Duration(seconds: 3), () {
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

  // void showTolakApproval(BuildContext context, String idDriver, String tanggal) {
  //   final screenSize = MediaQuery.of(context).size;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //           builder: (context, setState) {
  //             return SingleChildScrollView(
  //               child: Container(
  //                 padding: EdgeInsets.only(
  //                   bottom: MediaQuery.of(context).viewInsets.bottom,
  //                 ),
  //                 child: ListView(
  //                   shrinkWrap: true,
  //                   children: <Widget>[
  //                     Container(
  //                       padding: EdgeInsets.all(16.0),
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.max,
  //                         crossAxisAlignment: CrossAxisAlignment.stretch,
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Text(
  //                                 'Alasan',
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.w600,
  //                                   fontSize: 16,
  //                                 ),
  //                               ),
  //                               Spacer(),
  //                               IconButton(
  //                                 icon: Icon(Icons.close),
  //                                 onPressed: () {
  //                                   Navigator.pop(context);
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                           Text(
  //                             'Informasikan alasan',
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.w300,
  //                               fontSize: 16,
  //                             ),
  //                           ),
  //                           MyCustomTextField(controller: alasanText, hintText: 'Alasan', buttonColor: Colors.white,),
  //                           SizedBox(height: 15,),
  //                           Row(
  //                             children: [
  //                               Container(
  //                                 height: 50,
  //                                 child: CustomButton(
  //                                   onPressed: (){
  //                                     Get.back();
  //                                   },
  //                                   width: 100,
  //                                   height: 100,
  //                                   text: 'Batal',
  //                                   radius: 10,
  //                                   cekSpacer: false,
  //                                   textColor: Colors.red,
  //                                   buttonColor: Colors.white,
  //                                   borderColor: Colors.transparent,
  //                                 ),
  //                               ),
  //                               SizedBox(width: 10,),
  //                               Expanded(
  //                                 child:  Container(
  //                                   height: 50,
  //                                   child: CustomButton(
  //                                     onPressed: (){
  //                                       for (var item in detailBbsenData) {
  //                                         absenID.add(item['absen_id']);
  //                                       }
  //                                       for (var item in detailRencanaRute){
  //                                         ruterID.add(item['rute_id']);
  //                                       }
  //                                       runMutationFunctionApprove(absenId: absenID, keterangan: alasanText.text, driverId: idDriver, approve: false, ruteID: ruterID, tanggal: tanggal);
  //                                       fetchData1();
  //                                       showDialog(
  //                                         context: context,
  //                                         builder: (BuildContext context) {
  //                                           return RoundPopup();
  //                                         },
  //                                       );
  //                                       Future.delayed(Duration(seconds: 3), () {
  //                                         Get.back();
  //                                       });
  //                                       ruterID = [];
  //                                       absenID = [];
  //                                       alasanText.text = '';
  //                                       Get.back();
  //                                       Get.back();
  //                                     },
  //                                     width: 100,
  //                                     height: 100,
  //                                     text: 'Kirim',
  //                                     radius: 10,
  //                                     cekSpacer: false,
  //                                     textColor: Colors.white,
  //                                     buttonColor: Color.fromRGBO(14, 137, 145, 1),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }
  //       );
  //     },
  //   );
  // }
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

  void showDetailAbsensiModal(BuildContext context, bool cekKosong, String tanggal, String driverId, bool cekApprove, String namaOwner) {
    final screenSize = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 1.0,
          widthFactor: 1.0,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 15,),
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
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  Text(
                    DateFormat('EEEE, d MMM y', 'id').format(DateTime.parse(tanggal)),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15,),
                  if (cekKosong == true)
                    Column(
                      children: [
                        if (detailJadwalKerja != null && detailJadwalKerja.isNotEmpty)
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

                                        if (cekApprove == true)
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
                        for(var item in detailBbsenData)
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
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: screenSize.width * 0.6,
                                              child: Wrap(
                                                children: [
                                                  Text(item['latitude'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Wrap(
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
                                            ),
                                            if(item['jenis' ]== 'SAKIT')
                                              TextButton(
                                                  onPressed: (){
                                                    print(item['files']);
                                                    getPresignedUrl('${item['files']}');
                                                  }, child: Text('Open Image'))
                                          ],
                                        ),

                                        Spacer(),

                                        if (cekApprove == true)
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
                        for(var item in detailRencanaRute)
                          Column(
                            children: [
                              InkWell(
                                onTap: (){
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
                                              child: Wrap(
                                                children: [
                                                  Text(item['latitude'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Wrap(
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
                                            )
                                          ],
                                        ),

                                        Spacer(),

                                        if (cekApprove == true)
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
                  if (cekApprove == true)
                    Text('Laporan telah di Approve pada ${tanggal}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
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

  void runMutationFunctionRute({
    required String jam_mulai,
    required String keterangan,
    required String driverId
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
  insert_request_jemput_one(object: {driver_id: "$driverId", jam: "$jam_mulai", lokasi: "$keterangan"}) {
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

//   void runMutationFunctionApprove({
//     required List<int> absenId,
//     required String keterangan,
//     required String driverId,
//     required bool approve,
//     required List<int> ruteID,
//     required String tanggal,
//   }) async {
//     final HttpLink httpLink = HttpLink(
//       'http://45.64.3.54:40380/absendriver-api/v1/graphql',
//       defaultHeaders: {
//         'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
//       },
//     );
//
//     final GraphQLClient client = GraphQLClient(
//       link: httpLink,
//       cache: GraphQLCache(),
//     );
//
//     final MutationOptions options = MutationOptions(
//       document: gql('''
//         mutation MyMutation {
//   insert_approval_one(object: {absen_ids: $absenID, approve: $approve, driver_id: "$driverId", reject_reason: "$keterangan", rute_ids: $ruteID, tanggal: "$tanggal"}) {
//     id
//   }
// }
//     '''),
//     );
//
//     final QueryResult result = await client.mutate(options);
//
//     if (result.hasException) {
//       print('Mutation error: ${result.exception.toString()}');
//     } else {
//       print('Mutation successful: ${result.data}');
//     }
//   }

//   Future<void> fetchData() async {
//     final GraphQLClient client = GraphQLClient(
//       link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
//         defaultHeaders: {
//           'Authorization': 'Bearer ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
//         },
//       ),
//       cache: GraphQLCache(),
//     );
//
//     final QueryResult result = await client.query(
//       QueryOptions(
//         document: gql('''
//         query MyQuery {
//   status_absen(where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}, _and: {tanggal: {_gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 7)))}"}}}, order_by: {tanggal: desc}) {
//     driver {
//       displayName
//       id
//     }
//     has_approve
//     has_absen
//     tanggal
//   }
// }
//       '''),
//       ),
//     );
//
//     if (result.hasException) {
//       print('Error Cuy: ${result.exception.toString()}');
//     } else {
//       absenData = List<Map<String, dynamic>>.from(result.data?['status_absen'] ?? []);
//       print(absenData);
//       for (var item in absenData)
//         print(item['jenis']);
//     }
//   }
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
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
              }
            },
            order_by: {tanggal: desc}
          ) {
            driver {
              id
              displayName
            }
            has_absen
            tanggal
            has_approve
          }
          jadwal_driver(
            where: {
              tanggal: {
                _lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"
              }
            }
          ) {
            driver_id
            id
            tanggal
            owner_id
            owner {
              displayName
            }
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
        Map<String, dynamic> owner = jadwal['owner'];
        ownerDataMap['$driverId-$tanggal'] = owner;
      }

      // Menggabungkan hasil dari status_absen dan jadwal_driver
      for (var absen in statusAbsenData) {
        String driverId = absen['driver']['id'];
        String tanggal = absen['tanggal'];
        Map<String, dynamic>? owner = ownerDataMap['$driverId-$tanggal'];

        if (owner != null) {
          // Menambahkan data owner ke dalam status_absen
          absen['ownerData'] = owner;
        }
      }

      // Hasil akhir diassign ke absenData
      absenData = statusAbsenData;

      print(absenData);
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
    absen_id :id
    jam
    jenis
    tanggal
    keterangan
    files
    user_id
    longitude
    latitude
  }
  rencana_rute(where: {user_id: {_eq: "$idDriver"}, _and: {tanggal: {_eq: "$tanggal"}}}) {
    rute_id :id
    jam_mulai
    jam_selesai
    keterangan
    tanggal
    user_id
    longitude
    latitude
  }
  
  approval(where: {tanggal: {_eq: "$tanggal"}, _and: {driver_id: {_eq: "$idDriver"}}}) {
    approve
    reject_reason
    tanggal
  }
  jadwal_driver(where: {tanggal: {_eq: "$tanggal"}, _and: {driver_id: {_eq: "$idDriver"}}}) {
    tanggal
    owner {
      displayName
      id
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
      detailApprove = List<Map<String, dynamic>>.from(result.data?['approval'] ?? []);
      detailJadwalKerja = List<Map<String, dynamic>>.from(result.data?['jadwal_driver'] ?? []);
      // Hasilnya adalah groupedData yang berisi data yang sudah dikelompokkan berdasarkan tanggal
      for (var item in detailBbsenData){
        print(item['id']);
        print(item['user_id']);
        print(item['tanggal']);}
      for (var item in detailApprove){
        print(item['id']);
        print(item['user_id']);
        print(item['approve']);}
    }
  }

  List<int> numberList = [0, 1, 0, 0, 0, 0];
  List<int> numberList1 = [1,1];

  Future<void> refreshData() async {
    // Tambahkan logika pembaruan data di sini
    await fetchData1();
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
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return null;
      }
    } catch (error) {
      print('Error getting presigned URL: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return WillPopScope(child:  Scaffold(
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
              SizedBox(height: 25,),
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
                        Text('Monitoring selalu kegiatan driver',
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
              Expanded(child:
              Container(
                // height: screenSize.height * 0.8,
                  width: screenSize.width * 1,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      color: Colors.white
                  ),
                  child: RefreshIndicator(child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Text('Kegiatan Driver',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),
                              ),
                              Spacer(),
                              CustomTextButton(
                                onPressed: () {
                                  widget.navigateToJanjiTamu(1);
                                },
                                text: 'Lihat Semua',
                              )
                            ],
                          ),

                          for(var item in absenData)
                            InkWell(
                              onTap: () async {
                                await fetchDataDetail(item['tanggal'], item['driver']['id']);

                                showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['driver']['id'], item['has_approve'], item['ownerData'] != null ? '${item['ownerData']['displayName']}' ?? '' : '');

                              },
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                      color: Color.fromRGBO(218, 218, 218, 1),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
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
                                                  Text(item['driver']['displayName'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Text(DateFormat('EEEE, d MMM y', 'id').format(DateTime.parse(item['tanggal'])),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (item['ownerData'] != null)
                                                    Row(
                                                      children: [
                                                        Icon(Icons.arrow_right_alt_rounded),
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
                                          SizedBox(height: 10,),
                                          // if (item['has_absen'] == true
                                          //     && item['tanggal'] == DateFormat('yyyy-MM-dd').format(DateTime.now())
                                          // )
                                          //   Container(
                                          //     height: 40,
                                          //     child: CustomButton(
                                          //       onPressed: (){
                                          //         showRencanaRuterModal(context, item['driver']['id']);
                                          //       },
                                          //       width: 100,
                                          //       height: 100,
                                          //       text: 'Request Jemput',
                                          //       radius: 10,
                                          //       cekSpacer: false,
                                          //       textColor: Colors.white,
                                          //       buttonColor: Color.fromRGBO(14, 137, 145, 1),
                                          //     ),
                                          //   ),
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
                  ), onRefresh: refreshData)
              )
              )
            ],
          ),
        ),
      ),
    ), onWillPop: () async {
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
