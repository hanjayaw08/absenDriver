import 'dart:ffi';

import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:driverattendance/component/textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class riwayatOwnerPage extends StatefulWidget {
  String tokenDriver;
  String idDriver;
  String nameDriver;

  riwayatOwnerPage({
    required this.idDriver,
    required this.tokenDriver,
    required this.nameDriver,
    Key? key,
  }) : super(key: key);

  @override
  _riwayatOwnerPageState createState() =>
      _riwayatOwnerPageState();
}

class _riwayatOwnerPageState extends State<riwayatOwnerPage> {

  DateTime? selectedDate1 = null;
  DateTime? selectedDate2 = null;
  Future<DateTime?> _selectDate(BuildContext context, DateTime? selectedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      return picked;
    } else {
      // Pengguna membatalkan pemilihan tanggal
      print('Pemilihan tanggal dibatalkan');
    }


  }
  RxList<Map<String, dynamic>> absenData = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailApprove = [];
  List<Map<String, dynamic>> detailJadwalKerja = [];
  List<Map<String, dynamic>> checkDataList = [];
  List<int> absenID = [];
  List<int> ruterID = [];
  RxList<Map<String, dynamic>> waData = <Map<String, dynamic>>[].obs;
  List<bool> selectedItems = [];
  final TextEditingController ruterText = TextEditingController();
  final TextEditingController alasanText = TextEditingController();
  late RxString waktuMasuk = "10:00pm".obs;
  bool isAllChecked = false;
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
  void openWhatsAppOrBrowser(String phoneNUmber) async {
    try {
      await launch('https://wa.me/$phoneNUmber');
    } catch (e) {
      print('Tidak dapat membuka tautan di browser: $e');
    }
  }
  bool isLoading = false;
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

  late String formattedDate;
  late String currentTime;
  void showDetailAbsensiModal(BuildContext context, bool cekKosong, String tanggal, String driverId, bool cekStatus, String namaOwner) {
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
            child: Stack(
              children: [
                SingleChildScrollView(
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
                            if (detailJadwalKerja.isNotEmpty)
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
                                                Row(
                                                  children: [
                                                    Icon(Icons.arrow_right_sharp),
                                                    Text(item['owner']['displayName'] ?? '',
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

                                            if (cekStatus == true)
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
                                    onTap: (){
                                      MapsLauncher.launchCoordinates(double.parse(item['latitude']), double.parse(item['longitude']));
                                    },
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
                                                          Text(item['keterangan'] ?? '')
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
                                                if(item['jenis' ]== 'SAKIT')
                                                  TextButton(
                                                      onPressed: (){
                                                        print(item['files']);
                                                        Get.back();
                                                        getPresignedUrl('${item['files']}');
                                                      }, child: Text('Open Image'))
                                              ],
                                            ),

                                            Spacer(),

                                            if (cekStatus == true)
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
                                                        Text(item['keterangan'] ?? '')
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

                                            if (cekStatus == true)
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
                            for(var item in detailApprove)
                              if (item['approve'] == false || item['approve'] == null)
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
                                            Icon(
                                              Icons.place,
                                              color: Colors.green,
                                            ),

                                            SizedBox(width: 10,),

                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Keterangan',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  item['reject_reason'] == null ? '' : item['reject_reason'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            Spacer(),

                                            if (cekStatus == true)
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
                                  ],
                                ),
                              if(detailApprove.isNotEmpty)
                                Text('Laporan telah di Approve pada ${detailApprove[0]['tanggal']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                              Row(
                              children: [
                                    Expanded(
                                      child:  Container(
                                        height: 50,
                                        child: CustomButton(
                                          onPressed: (){
                                            // setState(() {
                                            //   isLoading = true;
                                            // });
                                            // for (var item in detailBbsenData) {
                                            //   absenID.add(item['absen_id']);
                                            // }
                                            // for (var item in detailRencanaRute){
                                            //   ruterID.add(item['rute_id']);
                                            // }
                                            // runMutationFunctionRute(absenId: absenID, keterangan: 'oke', driverId: driverId, approve: true, ruteID: ruterID, tanggal: tanggal);
                                            // fetchData1();
                                            // ruterID = [];
                                            // absenID = [];
                                            // setState(() {
                                            //   isLoading = false;
                                            // });
                                            // setState(() {
                                            //   fetchData1();
                                            // });
                                            // Get.back();
                                            // print(item['approve']);
                                          },
                                          width: 100,
                                          height: 100,
                                          text: 'Approve',
                                          radius: 10,
                                          cekSpacer: false,
                                          textColor: Colors.white,
                                          buttonColor: Color.fromRGBO(14, 137, 145, 1),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10,),
                                    Container(
                                      height: 50,
                                      child: CustomButton(
                                        onPressed: (){
                                          showTolakApproval(context, driverId, tanggal);
                                        },
                                        width: 100,
                                        height: 100,
                                        text: 'Tolak',
                                        radius: 10,
                                        cekSpacer: false,
                                        textColor: Color.fromRGBO(14, 137, 145, 1),
                                        buttonColor: Colors.white,
                                        borderColor: Color.fromRGBO(14, 137, 145, 1),
                                      ),
                                    )
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
                    ],
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
            )
          ),
        );
      },
    );
  }

  void showTolakApproval(BuildContext context, String idDriver, String tanggal) {
    final screenSize = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Stack(
                children: [
                    SingleChildScrollView(
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
                                      'Tolak',
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
                                Text(
                                  'Informasikan alasan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 16,
                                  ),
                                ),
                                MyCustomTextField(controller: alasanText, hintText: 'rute', buttonColor: Colors.white,),
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
                                            setState(() {
                                              isLoading = true;
                                            });
                                            if (detailApprove.isEmpty){
                                              for (var item in detailBbsenData) {
                                                absenID.add(item['absen_id']);
                                              }
                                              for (var item in detailRencanaRute){
                                                ruterID.add(item['rute_id']);
                                              }
                                              runMutationFunctionRute(absenId: absenID, keterangan: alasanText.text, driverId: idDriver, approve: false, ruteID: ruterID, tanggal: tanggal);
                                            }
                                            else{
                                              for (var item in detailApprove){
                                                updateTolak(Id: item['id'], keterangan: alasanText.text);
                                              }
                                            }
                                            ruterID = [];
                                            absenID = [];
                                            alasanText.text = '';
                                            setState(() {
                                              isLoading = false;
                                            });
                                            fetchData1();
                                            Get.back();
                                            Get.back();
                                            print('object');
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
                  ),
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                ],
              );
            }
        );
      },
    );
  }

  void initState() {
    super.initState();
    var now = DateTime.now();
    formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    updateTime();
    isiAbsen();
    // fetchData1();
    fetchDataWA2();
  }

  void updateTime() {
    setState(() {
      var now = DateTime.now();
      currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

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
//   status_absen(where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}, _and: {tanggal: {_gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 30)))}"}}}, order_by: {tanggal: desc}) {
//     driver {
//       displayName
//       id
//     }
//     has_approve
//     has_absen
//     tanggal
//
//   }
// }
//       '''),
//       ),
//     );
//
//     if (result.hasException) {
//       print('Error Cuy: ${result.exception.toString()}');
//       print(widget.tokenDriver);
//     } else {
//       absenData.value = List<Map<String, dynamic>>.from(result.data?['status_absen'] ?? []);
//       selectedItems = List.generate(absenData.length, (index) => false);
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
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 31)))}"
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
          jadwal_driver (where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}", _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"}, _and: {active: {_eq: true}}}){
            driver_id 
            id
            tanggal
            owner {
              id
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
        Map<String, dynamic> owner = jadwal['owner'] ?? {};
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
      absenData.value = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }
    }
  }
//   Future<void> fetchDataWA() async {
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
//           query MyQuery {
//   users(where: {defaultRole: {_eq: "driver"}}) {
//     defaultRole
//     displayName
//     email
//     id
//   }
// }
//       '''),
//       ),
//     );
//
//     if (result.hasException) {
//       print('Error Cuy: ${result.exception.toString()}');
//       print(widget.tokenDriver);
//     } else {
//       waData.value = List<Map<String, dynamic>>.from(result.data?['users'] ?? []);
//       print('ini wa $waData');
//     }
//   }
  Future<void> fetchDataWA2() async {
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
          users(where: {defaultRole: {_eq: "driver"}}) {
            defaultRole
            displayName
            email
            id
            phoneNumber
          }
          jadwal_driver(where: {tanggal: {_eq: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}}) {
            driver_id 
            id
            tanggal
            owner {
              id
              displayName
            }
          }
        }
      '''),
      ),
    );

    print('Raw Query Result:');
    print(result.data);

    if (result.hasException) {
      print('Error Cuy: ${result.exception.toString()}');
      print(widget.tokenDriver);
    } else {
      List<Map<String, dynamic>> usersData =
      List<Map<String, dynamic>>.from(result.data?['users'] ?? []);

      List<Map<String, dynamic>> jadwalData =
      List<Map<String, dynamic>>.from(result.data?['jadwal_driver'] ?? []);

      // Menggunakan Map untuk menyimpan data driver berdasarkan ID
      Map<String, Map<String, dynamic>> driversMap = {};

      // Memasukkan data driver dari users ke dalam Map
      for (Map<String, dynamic> user in usersData) {
        String driverId = user['id'];
        driversMap[driverId] = {
          'displayName': user['displayName'],
          'defaultRole': user['defaultRole'],
          'idDriver' : user['id'],
          'phoneNumber' : user['phoneNumber']
        };
      }

      // Memasukkan data driver dari jadwal_driver ke dalam Map
      for (Map<String, dynamic> jadwal in jadwalData) {
        String driverId = jadwal['driver_id'];

        // Memastikan bahwa driversMap[driverId] tidak null sebelum mengakses elemennya
        if (driversMap[driverId] != null) {
          // Jika ID driver sudah ada di Map, tambahkan informasi baru
          driversMap[driverId]!['jadwalData'] = {
            'id': jadwal['id'],
            'tanggal': jadwal['tanggal'],
            'nama' : jadwal['owner']['displayName'],
            // tambahkan informasi lain sesuai kebutuhan
          };
        }
      }

      // Hasil akhir diassign ke waData
      waData.value = driversMap.values.toList();

      print("ini sinya ${waData[0]['idDriver']}");
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
    files
    keterangan
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
    id
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
      // for (var item in detailBbsenData){
      //   print(item['id']);
      //   print(item['user_id']);
      //   print(item['tanggal']);}
      // for (var item in detailRencanaRute){
      //   print(item['id']);
      //   print(item['user_id']);
      //   print(item['tanggal']);}
    }
  }
  Future<void> fetchCondition(String tanggalAwal, String tanggalAkhir) async {
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
                _lte: "${tanggalAkhir}",
                _gte: "${tanggalAwal}"
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
          jadwal_driver{
            driver_id 
            id
            tanggal
            owner {
              id
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
        Map<String, dynamic> owner = jadwal['owner'] ?? {};
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
      absenData.value = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }

      print(absenData[2]['ownerData']['id']);
    }
  }

  void runMutationFunctionRute({
    required List<int> absenId,
    required String keterangan,
    required String driverId,
    required bool approve,
    required List<int> ruteID,
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
  insert_approval_one(object: {absen_ids: $absenID, approve: $approve, driver_id: "$driverId", reject_reason: "$keterangan", rute_ids: $ruteID, tanggal: "$tanggal"}) {
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

  void updateTolak({
    required int Id,
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
  update_approval_by_pk(pk_columns: {id: "$Id"}, _set: {approve: false, reject_reason: "$keterangan"}) {
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

  void runMutationFunctionRequestJemput({
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

  Future<void> refreshData() async {
    // Tambahkan logika pembaruan data di sini
    await fetchData1();
  }
  Future<void> refreshDataWA() async {
    // Tambahkan logika pembaruan data di sini
    await fetchDataWA2();
  }
  Future<void> isiAbsen() async {
    // Tambahkan logika pembaruan data di sini
    await fetchData1();
    selectedItems = List.generate(absenData.length, (index) => false);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Foto tidak ada'),
            ));
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

    return DefaultTabController(
      length: 2, // Sesuaikan jumlah tab
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('Riwayat Absensi',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () async {
                  showCustomDateRangePicker(
                    context,
                    dismissible: true,
                    minimumDate: DateTime.now().subtract(const Duration(days: 30)),
                    maximumDate: DateTime.now().add(const Duration(days: 30)),
                    endDate: selectedDate2,
                    startDate: selectedDate1,
                    backgroundColor: Colors.white,
                    primaryColor: Colors.green,
                    onApplyClick: (start, end) {
                      setState(() {
                        selectedDate2 = end;
                        selectedDate1 = start;
                      });
                      fetchCondition(DateFormat('yyyy-MM-dd').format(selectedDate1 ?? DateTime.now()), DateFormat('yyyy-MM-dd').format(selectedDate2 ?? DateTime.now()));
                    },
                    onCancelClick: () {

                    },
                  );
                },
                child:  Icon(Icons.calendar_month,
                  size: 30,
                ),
              )
            ],
          ),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Laporan'),
              Tab(text: 'Pengguna'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1:
            RefreshIndicator(child: Obx(() {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      // judul Dan Kalendar
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextButton(
                                onPressed: () {
                                  setState(() {
                                    isAllChecked = !isAllChecked;

                                    // Update selectedItems and checkDataList accordingly
                                    for (var i = 0; i < absenData.length; i++) {
                                      selectedItems[i] = isAllChecked;
                                    }

                                    checkDataList = isAllChecked ? List.from(absenData) : [];
                                  });
                                },
                                text: isAllChecked ? 'Uncheck All' : 'Check All',
                              ),
                              if (selectedDate1 != null && selectedDate2 != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 15),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: Color.fromRGBO(14, 137, 145, 0.2)// Radius border
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: IntrinsicWidth(
                                          child: Row(
                                            children: [
                                              Text(
                                                '${DateFormat('MMM dd, yyyy', 'id').format(selectedDate1!)} - ${DateFormat('MMM dd, yyyy', 'id').format(selectedDate2!)}',
                                                style: TextStyle(fontSize: 18.0),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedDate1 = null;
                                                    selectedDate2 = null;
                                                    fetchData1();
                                                  });
                                                },
                                                child: Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                  ),
                                ),
                            ],
                          ),
                          Spacer(),
                          CustomTextButton(
                            onPressed: () async {
                              for (var item in checkDataList){
                                await fetchDataDetail(item['tanggal'], item['driver']['id']);
                                for (var item in detailBbsenData) {
                                  absenID.add(item['absen_id']);
                                }
                                for (var item in detailRencanaRute){
                                  ruterID.add(item['rute_id']);
                                }
                                runMutationFunctionRute(absenId: absenID, keterangan: 'oke', driverId: item['driver']['id'], approve: true, ruteID: ruterID, tanggal: item['tanggal']);
                                ruterID = [];
                                absenID = [];
                              }
                            },
                            text: 'Approve',
                          ),
                        ],
                      ),
                      SizedBox(height: 15,),
                      Flexible(
                        child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: absenData.length,
                            itemBuilder: (context, index){
                              var item = absenData[index];
                              if (index >= absenData.length) {
                                return SizedBox.shrink(); // Tambahkan pengecekan index valid di sini
                              }
                              return  InkWell(
                                onTap: () async {
                                  await fetchDataDetail(item['tanggal'], item['driver']['id']);
                                  fetchData1();
                                  showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['driver']['id'], item['has_approve'], item['ownerData'] != null ? '${item['ownerData']['displayName']}' ?? '' : '');
                                },
                                onLongPress: () {
                                  setState(() {
                                    selectedItems[index] = !selectedItems[index];
                                  });
                                  if (selectedItems[index] == true){
                                    checkDataList.add(absenData[index]);
                                    print(checkDataList);
                                  }else{
                                    checkDataList.remove(absenData[index]);
                                    print(checkDataList);
                                  }
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                        color: selectedItems.length > index && selectedItems[index] ? Colors.green : Color.fromRGBO(218, 218, 218, 1),
                                        border: Border.all(
                                          color: selectedItems.length > index && selectedItems[index] ? Colors.green : Colors.black,
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
                                                    Text(item['driver']['displayName'],
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
                                                    Text(item['has_absen'] == false ? 'Tidak ada aktifitas terekam' : item['has_approve'] == true? 'Laporan di Approve' : 'Laporan Belum DIapprove',
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
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 15,),
                                  ],
                                ),
                              );
                            }
                        ),
                      )
                    ]
                ),
              );

            }), onRefresh: refreshData),

            // Tab 2:
            Obx((){
              return RefreshIndicator(child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    for (var item in waData)
                      Column(
                        children: [
                          Padding(
                              padding: EdgeInsets.all(16),
                              child:  Container(
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        'assets/img/BeepBeepUFO.png',
                                        width: 50.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                                        height: 50.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['displayName'],
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(item['defaultRole'],
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w300
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (item['jadwalData'] != null )
                                              ClipOval(
                                                child: Image.asset(
                                                  'assets/img/BeepBeepUFO.png',
                                                  width: 20.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                                                  height: 20.0, // Sesuaikan ukuran gambar sesuai kebutuhan
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            SizedBox(width: 5,),
                                            Text(item['jadwalData'] != null ? '-> ${item['jadwalData']['nama']}' ?? '' : '',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w300
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    Spacer(),
                                    InkWell(
                                      onTap: (){
                                        openWhatsAppOrBrowser(item['phoneNumber']);
                                      },
                                      child: Image.asset('assets/img/iconWhatsapp.png',
                                        scale: 3.5,
                                      ),
                                    )
                                  ],
                                ),
                              )
                          ),
                          Container(
                            height: 1,
                            color: Colors.grey,
                          ),
                        ],
                      )
                  ],
                ),
              ), onRefresh: refreshDataWA);
            })
          ],
        ),
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
