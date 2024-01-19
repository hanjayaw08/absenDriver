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

class homeHrdPage extends StatefulWidget {
  String tokenDriver;
  String idDriver;
  String nameDriver;
  final Function(int) navigateToJanjiTamu;

  homeHrdPage({
    required this.idDriver,
    required this.tokenDriver,
    required this.nameDriver,
    required this.navigateToJanjiTamu,
    Key? key,
  }) : super(key: key);

  @override
  _homeHrdPageState createState() => _homeHrdPageState();
}

class _homeHrdPageState extends State<homeHrdPage> {
  // ini untuk waktu menit dan detik untuk absensi
  late String formattedDate;
  late String currentTime;
  late String realTime;

  // ini untuk text field modal rencana rute
  late RxString waktuMasuk = "10:00pm".obs;
  late RxString waktuSelesai = "10:00pm".obs;
  final TextEditingController ruterText = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<Map<String, dynamic>> absenData = [];
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> latestItems = [];

  //function untuk absen

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);
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

  void showDetailAbsensiModal(BuildContext context, bool cekKosong, String tanggal, String driverId, bool cekApprove, String namaOwner) {
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
                        SizedBox(height: 15,),
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
                                                      Text('Kampus A')
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
//   status_absen(where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}, _and: {tanggal: {_gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 8)))}"}}}, order_by: {tanggal: desc}) {
//     driver {
//       displayName
//       id
//     }
//     has_absen
//     tanggal
//     has_approve
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
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 7)))}"
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
      absenData = statusAbsenData;
      for (var jadwal in jadwalData) {
        print('Owner Data: ${jadwal['owner']}');
        // rest of the loop
      }

      print(absenData[2]['ownerData']['id']);
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
}


      '''),
      ),
    );

    if (result.hasException) {
      print('Error: ${result.exception.toString()}');
    } else {
      detailBbsenData = List<Map<String, dynamic>>.from(result.data?['absen'] ?? []);
      detailRencanaRute = List<Map<String, dynamic>>.from(result.data?['rencana_rute'] ?? []);

      // Hasilnya adalah groupedData yang berisi data yang sudah dikelompokkan berdasarkan tanggal
      for (var item in detailBbsenData)
        print(item);
    }
  }
  Future<void> refreshData() async {
    // Tambahkan logika pembaruan data di sini
    await fetchData1();
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
              SizedBox(height: 35,),
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
                  child: RefreshIndicator(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
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

                                showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['driver']['id'], item['has_approve'], item['ownerData'] != null ? '--> ${item['ownerData']['displayName']}' ?? '' : '');
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
                                                    Text(
                                                      item['ownerData'] != null ? '--> ${item['ownerData']['displayName']}' ?? '' : '',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  Text(item['has_absen'] == false ? 'Tidak ada aktifitas terekam' : item['has_approve'] == true ? 'Laporan di Approve' : 'Laporan belum di Approve',
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
                            )
                        ],
                      ),
                    ),
                  ),
                      onRefresh: refreshData
                  )
              )
              )
            ],
          ),
        ),
      ),
    ),
        onWillPop: () async {
          return false;
        }
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
