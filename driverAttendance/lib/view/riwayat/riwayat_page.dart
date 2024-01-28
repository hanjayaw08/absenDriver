import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class riwayatPage extends StatefulWidget {
  String tokenDriver;
  String nameDriver;
  String idDriver;

  riwayatPage({
    required this.tokenDriver,
    required this.idDriver,
    required this.nameDriver,
    Key? key,
  }) : super(key: key);
  @override
  _riwayatPageState createState() =>
      _riwayatPageState();
}

class _riwayatPageState extends State<riwayatPage> {

  DateTime? selectedDate1 = null;
  DateTime? selectedDate2 = null;
  RxList<Map<String, dynamic>> absenData = <Map<String, dynamic>>[].obs;
  String toTitleCase(String text) {
    if (text == null || text.isEmpty) {
      return text;
    }

    return text
        .split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toLowerCase()}${word.substring(1)}'
        : word)
        .join(' ');
  }

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
  List<int> numberList = [0, 1, 0, 0, 0, 0];
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailJadwalKerja = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailApprove = [];

  late String formattedDate;
  late String currentTime;
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
                        for(var item in detailBbsenData)
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
                                            if(item['jenis'] == 'SAKIT')
                                              TextButton(
                                                  onPressed: (){
                                                    print(item['files']);
                                                    Get.back();
                                                    getPresignedUrl('${item['files']}');
                                                  }, child: Text('Open Image'))
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
                        for(var item in detailRencanaRute)
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
  List<int> numberList1 = [1];

  void initState() {
    super.initState();
    var now = DateTime.now();
    formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    updateTime();
    setState(() {
      fetchData1();
    });
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
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 31)))}"
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
          jadwal_driver (where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}", _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"}, _and: {active: {_eq: true}}})
          {
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
      absenData.value = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }
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
      absenData.value = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }

      print(absenData[2]['ownerData']['displayName']);
    }
  }
  Future<void> fetchDataDetail(String tanggal) async {
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
  absen(where: {tanggal: {_eq: "$tanggal"}, _and: {user_id: {_eq: "${widget.idDriver}"}}}) {
    jam
    jenis
    tanggal
    keterangan
    longitude
    latitude
  }

rencana_rute(where: {user_id: {_eq: "${widget.idDriver}"}, _and: {tanggal: {_eq: "$tanggal"}}}) {
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
  jadwal_driver(where: {tanggal: {_eq: "$tanggal"}, _and: {driver_id: {_eq: "${widget.idDriver}"}}}) {
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
      for (var item in detailBbsenData)
        print(item);
    }
  }

  void updateTime() {
    setState(() {
      var now = DateTime.now();
      currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

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

    return Obx(() {
      return RefreshIndicator(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 25,),
                // judul Dan Kalendar
                Row(
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
                SizedBox(height: 15,),
                for(var item in absenData)
                  InkWell(
                    onTap: () async {
                      await fetchDataDetail(item['tanggal']);
                      showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['ownerData'] != null ? '${item['ownerData']['displayName']}' ?? '' : ''
                      );
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
                          ),
                        ),
                        SizedBox(height: 15,),
                      ],
                    ),
                  )
              ]
          ),
        ),
      ),
          onRefresh: refreshData);
    });
  }
}
