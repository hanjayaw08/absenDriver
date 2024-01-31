import 'package:driverattendance/component/buttonBackGroun.dart';
import 'package:driverattendance/component/textButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class riwayatGAPage extends StatefulWidget {
  String tokenDriver;
  String idDriver;
  String nameDriver;

  riwayatGAPage({
    required this.idDriver,
    required this.tokenDriver,
    required this.nameDriver,
    Key? key,
  }) : super(key: key);

  @override
  _riwayatGAPageState createState() =>
      _riwayatGAPageState();
}

class _riwayatGAPageState extends State<riwayatGAPage> {

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
  List<int> numberList = [0, 1, 0, 0, 0, 0];
  RxList<Map<String, dynamic>> absenData = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> detailBbsenData = [];
  List<Map<String, dynamic>> detailRencanaRute = [];
  List<Map<String, dynamic>> detailJadwalKerja = [];
  RxList<Map<String, dynamic>> waData = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataOwner = <Map<String, dynamic>>[].obs;
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
  List<int> numberList1 = [1];

  void initState() {
    super.initState();
    var now = DateTime.now();
    formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    updateTime();
    fetchData1();
    fetchDataWA2();
    fetchDataDetailPDF(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32))), DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  void updateTime() {
    setState(() {
      var now = DateTime.now();
      currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  void openWhatsAppOrBrowser(String phoneNUmber) async {
    try {
      await launch('https://wa.me/$phoneNUmber');
    } catch (e) {
      print('Tidak dapat membuka tautan di browser: $e');
    }
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
//   status_absen(where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}, _and: {tanggal: {_gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"}}}, order_by: {tanggal: desc}) {
//     driver {
//       displayName
//       id
//     }
//     has_absen
//     tanggal
//     has_approve
//   }
//   jadwal_driver(where: {tanggal: {_eq: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}}) {
//             driver_id
//             id
//             tanggal
//             owner_id
//             owner {
//               displayName
//             }
//           }
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
//       print(absenData);
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
                _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"
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
          jadwal_driver
          (where: {tanggal: {_lte: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}", _gte: "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32)))}"}, _and: {active: {_eq: true}}})
          {
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
      absenData.value = statusAbsenData;

      print(absenData);
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
//   defaultRole
//     displayName
//     email
//     id
//   }
//   jadwal_driver {
//     driver_id
//     id
//     tanggal
//     owner_id
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
//       print(waData);
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
          jadwal_driver(where: {tanggal: {_eq: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}, _and: {active: {_eq: true}}}) {
            driver_id
            id
            tanggal
            owner_id
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
          'phoneNumber': user['phoneNumber'],
          'displayName': user['displayName'],
          'defaultRole': user['defaultRole'],
          'idDriver' : user['id']
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
            'idOwner': jadwal['owner']['id'],
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

  Future<void> fetchDataOwner() async {
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
  users(where: {defaultRole: {_eq: "owner"}}) {
  defaultRole
    displayName
    email
    id
  }
}
      '''),
      ),
    );

    if (result.hasException) {
      print('Error Cuy: ${result.exception.toString()}');
      print(widget.tokenDriver);
    } else {
      dataOwner.value = List<Map<String, dynamic>>.from(result.data?['users'] ?? []);
      print(waData);
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
    files
    keterangan
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
      detailJadwalKerja = List<Map<String, dynamic>>.from(result.data?['jadwal_driver'] ?? []);
      // Hasilnya adalah groupedData yang berisi data yang sudah dikelompokkan berdasarkan tanggal
      for (var item in detailBbsenData)
        print(item);
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
      absenData.value = statusAbsenData;

      print(absenData);
    }
  }

  List<Map<String, dynamic>> detailAbsenDataPDF = [];
  List<Map<String, dynamic>> detailRencanaRutePDF = [];
  List<Map<String, dynamic>> detailStatusAbsen = [];
  List<Map<String, dynamic>> combinedData = [];

  Future<void> fetchDataDetailPDF(String tanggalAwal, String tanggalAkhir) async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer  ${widget.tokenDriver}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
         query MyQuery {
  get_status_absen(args: {start_date: "$tanggalAwal", end_date: "$tanggalAkhir"}, order_by: {tanggal: asc}) {
    tanggal
    user_id
    driver {
      displayName
    }
  }
  absen(where: { tanggal: { _gte: "$tanggalAwal", _lte: "$tanggalAkhir" } }, order_by: {tanggal: asc}) {
    jam
    jenis
    tanggal
    user_id
    driver {
      displayName
    }
  }
  rencana_rute(where: { tanggal: { _gte: "$tanggalAwal", _lte: "$tanggalAkhir" } }, order_by: {tanggal: asc}) {
    keterangan
    jam_mulai
    jam_selesai
    tanggal
    user_id
    driver {
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
      detailAbsenDataPDF = List<Map<String, dynamic>>.from(result.data?['absen'] ?? []);
      detailRencanaRutePDF = List<Map<String, dynamic>>.from(result.data?['rencana_rute'] ?? []);
      detailStatusAbsen = List<Map<String, dynamic>>.from(result.data?['get_status_absen'] ?? []);
    }
  }

  // Future<String> generatePDF() async {
  //   final pdf = pw.Document();
  //
  //   final totalItems = combinedData.length;
  //
  //   final maxItemsPerPage = 3;
  //
  //   final totalPages = (totalItems / maxItemsPerPage).ceil();
  //
  //   for (int page = 1; page <= totalPages; page++) {
  //     pdf.addPage(
  //       pw.Page(
  //           build: (context) {
  //             final startIndex = (page - 1) * maxItemsPerPage;
  //             final endIndex = startIndex + maxItemsPerPage;
  //             return pw.Column(
  //               crossAxisAlignment: pw.CrossAxisAlignment.center,
  //               children: [
  //                 pw.Column(
  //                     children: [
  //                       pw.Text(
  //                         'Laporan Absensi',
  //                         style: pw.TextStyle(
  //                             fontSize: 20, fontWeight: pw.FontWeight.bold),
  //                       ),
  //                       pw.Text(
  //                         '${combinedData[i]['tanggal']}',
  //                         style: pw.TextStyle(fontSize: 13),
  //                       ),
  //                     ]
  //                 ),
  //                 pw.SizedBox(height: 10),
  //                 for (int i = startIndex; i < endIndex && i < totalItems; i++) ...[
  //                   pw.Row(
  //                       children: [
  //                         pw.Text(
  //                           combinedData[i]['nama'] ?? '',
  //                           style: pw.TextStyle(
  //                               fontSize: 13, fontWeight: pw.FontWeight.bold),
  //                         ),
  //                       ]
  //                   ),
  //                   pw.SizedBox(height: 5),
  //                   pw.Container(
  //                     margin: pw.EdgeInsets.only(top: 10),
  //                     child: pw.Table(
  //                       columnWidths: {
  //                         0: pw.FlexColumnWidth(1),
  //                         1: pw.FlexColumnWidth(1),
  //                         2: pw.FlexColumnWidth(1),
  //                         3: pw.FlexColumnWidth(1),
  //                       },
  //                       border: pw.TableBorder.all(color: PdfColors.black),
  //                       children: [
  //                         // Table rows
  //                         pw.TableRow(
  //                           children: [
  //                             pw.Column(
  //                                 children: [
  //                                   _buildCell('Absensi Masuk', isHeader: true),
  //                                   for (var item in combinedData[i]['absen'])...[
  //                                     if (item['jenis'] == 'DATANG')
  //                                       _buildCell(item['jam'], isHeader: true),
  //                                   ],
  //                                   if (combinedData[i]['absen'].isEmpty ||
  //                                       combinedData[i]['absen'].every((item) => item['jenis'] != 'DATANG'))
  //                                     pw.Text(
  //                                       'Tidak Ada',
  //                                       style: pw.TextStyle(fontSize: 13),
  //                                     ),
  //                                 ]
  //                             ),
  //                             pw.Column(
  //                                 children: [
  //                                   _buildCell('Ijin Sakit', isHeader: true),
  //                                   for (var item in combinedData[i]['absen'])...[
  //                                     if (item['jenis'] == 'IZIN SAKIT')
  //                                       _buildCell(item['jam'], isHeader: true),
  //                                   ],
  //                                   if (combinedData[i]['absen'].isEmpty ||
  //                                       combinedData[i]['absen'].every((item) => item['jenis'] != 'IZIN SAKIT'))
  //                                     pw.Text(
  //                                       'Tidak Ada',
  //                                       style: pw.TextStyle(fontSize: 13),
  //                                     ),
  //                                 ]
  //                             ),
  //                             pw.Column(
  //                                 children: [
  //                                   _buildCell('Ijin Keluar', isHeader: true),
  //                                   for (var item in combinedData[i]['absen'])...[
  //                                     if (item['jenis'] == 'IJIN KELUAR')
  //                                       _buildCell(item['jam'], isHeader: true),
  //                                   ],
  //                                   if (combinedData[i]['absen'].isEmpty ||
  //                                       combinedData[i]['absen'].every((item) => item['jenis'] != 'IJIN KELUAR'))
  //                                     pw.Text(
  //                                       'Tidak Ada',
  //                                       style: pw.TextStyle(fontSize: 13),
  //                                     ),
  //                                 ]
  //                             ),
  //                             pw.Column(
  //                                 children: [
  //                                   _buildCell(
  //                                       'Absensi Pulang', isHeader: true),
  //                                   for (var item in combinedData[i]['absen'])...[
  //                                     if (item['jenis'] == 'PULANG')
  //                                       _buildCell(item['jam'], isHeader: true),
  //                                   ],
  //                                   if (combinedData[i]['absen'].isEmpty ||
  //                                       combinedData[i]['absen'].every((item) => item['jenis'] != 'PULANG'))
  //                                     pw.Text(
  //                                       'Tidak Ada',
  //                                       style: pw.TextStyle(fontSize: 13),
  //                                     ),
  //                                 ]
  //                             ),
  //                           ],
  //                         ),
  //                         // Add more rows as needed
  //                       ],
  //                     ),
  //                   ),
  //                   pw.SizedBox(height: 10),
  //                   pw.Row(
  //                       mainAxisAlignment: pw.MainAxisAlignment.start,
  //                       children: [pw.Column(
  //                           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                           children: [
  //                             pw.Text(
  //                               'Rencana Rute',
  //                               style: pw.TextStyle(fontSize: 10, fontWeight: pw
  //                                   .FontWeight.normal),
  //                             ),
  //                             pw.SizedBox(height: 5),
  //                             if (combinedData[i]['rencana_rute'] != null)
  //                               for (var item in combinedData[i]['rencana_rute'])...[
  //                                 pw.Text(
  //                                   '${item['keterangan']} - ${item['jam_mulai']}',
  //                                   style: pw.TextStyle(fontSize: 10, fontWeight: pw
  //                                       .FontWeight.normal),
  //                                 ),
  //                               ],
  //                             if (combinedData[i]['rencana_rute'].isEmpty)
  //                               pw.Text(
  //                                 'Tidak Ada',
  //                                 style: pw.TextStyle(fontSize: 10, fontWeight: pw
  //                                     .FontWeight.normal),
  //                               ),
  //                           ]
  //                       )
  //                       ]
  //                   ),
  //                   pw.SizedBox(height: 5),
  //                 ]
  //               ],
  //             );
  //           }
  //       ),
  //     );
  //   }
  //
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/example.pdf');
  //   await file.writeAsBytes(await pdf.save());
  //   return file.path;
  // }

  Future<String> generatePDF(List<Map<String, dynamic>> detailStatusAbsen, List<Map<String, dynamic>> detailAbsenDataPDF, List<Map<String, dynamic>> detailRencanaRutePDF) async {
    final pdf = pw.Document();
    final maxItemsPerPage = 3;

    // Group data berdasarkan tanggal
    for (var statusAbsen in detailStatusAbsen) {
      String tanggal = statusAbsen['tanggal'];
      String userId = statusAbsen['user_id'];
      String nama = statusAbsen['driver']['displayName'];

      // Temukan data absen berdasarkan tanggal dan user_id
      var absen = detailAbsenDataPDF.where(
            (element) =>
        element['tanggal'] == '$tanggal' &&
            element['user_id'] == '$userId',
      ).toList();

      // Temukan data rencana rute berdasarkan tanggal dan user_id
      var rencanaRute = detailRencanaRutePDF.where((element) =>
      element['tanggal'] == '$tanggal' &&
          element['user_id'] == '$userId',
      ).toList();
      print('ini rencana rute $rencanaRute');
      print('ini absen $absen');
      print('ini user id $userId');

      // Gabungkan data dan tambahkan ke dalam array hasil
      var combinedItem = {
        'nama': nama,
        'tanggal': tanggal,
        'user_id': userId,
        'absen': absen,
        'rencana_rute': rencanaRute,
      };

      if (!groupedData.containsKey(tanggal)) {
        groupedData[tanggal] = [];
      }
      groupedData[tanggal]!.add(combinedItem);
    }

    // Loop melalui data yang dikelompokkan dan buat halaman PDF
    for (var tanggal in groupedData.keys) {
      final totalItems = groupedData[tanggal]!.length;
      final totalPages = (totalItems / maxItemsPerPage).ceil();

      for (int page = 1; page <= totalPages; page++) {
        pdf.addPage(
          pw.Page(
            build: (context) {
              final startIndex = (page - 1) * maxItemsPerPage;
              final endIndex = startIndex + maxItemsPerPage;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Laporan Absensi',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '$tanggal',
                        style: pw.TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  for (int i = startIndex; i < endIndex && i < totalItems; i++) ...[
                      pw.Row(
                          children: [
                            pw.Text(
                              groupedData[tanggal]![i]['nama'] ?? '',
                              style: pw.TextStyle(
                                  fontSize: 13, fontWeight: pw.FontWeight.bold),
                            ),
                          ]
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        margin: pw.EdgeInsets.only(top: 10),
                        child: pw.Table(
                          columnWidths: {
                            0: pw.FlexColumnWidth(1),
                            1: pw.FlexColumnWidth(1),
                            2: pw.FlexColumnWidth(1),
                            3: pw.FlexColumnWidth(1),
                          },
                          border: pw.TableBorder.all(color: PdfColors.black),
                          children: [
                            // Table rows
                            pw.TableRow(
                              children: [
                                pw.Column(
                                    children: [
                                      _buildCell('Absensi Masuk', isHeader: true),
                                      for (var item in groupedData[tanggal]![i]['absen'])...[
                                        if (item['jenis'] == 'DATANG')
                                          _buildCell(item['jam'], isHeader: true),
                                      ],
                                      if (groupedData[tanggal]![i]['absen'].isEmpty ||
                                          groupedData[tanggal]![i]['absen'].every((item) => item['jenis'] != 'DATANG'))
                                        pw.Text(
                                          'Tidak Ada',
                                          style: pw.TextStyle(fontSize: 13),
                                        ),
                                    ]
                                ),
                                pw.Column(
                                    children: [
                                      _buildCell('Ijin Sakit', isHeader: true),
                                      for (var item in groupedData[tanggal]![i]['absen'])...[
                                        if (item['jenis'] == 'SAKIT')
                                          _buildCell(item['jam'], isHeader: true),
                                      ],
                                      if (groupedData[tanggal]![i]['absen'].isEmpty ||
                                          groupedData[tanggal]![i]['absen'].every((item) => item['jenis'] != 'SAKIT'))
                                        pw.Text(
                                          'Tidak Ada',
                                          style: pw.TextStyle(fontSize: 13),
                                        ),
                                    ]
                                ),
                                pw.Column(
                                    children: [
                                      _buildCell('Ijin Keluar', isHeader: true),
                                      for (var item in groupedData[tanggal]![i]['absen'])...[
                                        if (item['jenis'] == 'KELUAR')
                                          _buildCell(item['jam'], isHeader: true),
                                      ],
                                      if (groupedData[tanggal]![i]['absen'].isEmpty ||
                                          groupedData[tanggal]![i]['absen'].every((item) => item['jenis'] != 'KELUAR'))
                                        pw.Text(
                                          'Tidak Ada',
                                          style: pw.TextStyle(fontSize: 13),
                                        ),
                                    ]
                                ),
                                pw.Column(
                                    children: [
                                      _buildCell(
                                          'Absensi Pulang', isHeader: true),
                                      for (var item in groupedData[tanggal]![i]['absen'])...[
                                        if (item['jenis'] == 'PULANG')
                                          _buildCell(item['jam'], isHeader: true),
                                      ],
                                      if (groupedData[tanggal]![i]['absen'].isEmpty ||
                                          groupedData[tanggal]![i]['absen'].every((item) => item['jenis'] != 'PULANG'))
                                        pw.Text(
                                          'Tidak Ada',
                                          style: pw.TextStyle(fontSize: 13),
                                        ),
                                    ]
                                ),
                              ],
                            ),
                            // Add more rows as needed
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Rencana Rute',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw
                                      .FontWeight.normal),
                                ),
                                pw.SizedBox(height: 5),
                                if (groupedData[tanggal]![i]['rencana_rute'] != null)
                                  for (var item in groupedData[tanggal]![i]['rencana_rute'])...[
                                    pw.Text(
                                      '${item['keterangan']} : ${item['jam_mulai']} - ${item['jam_selesai']}',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw
                                          .FontWeight.normal),
                                    ),
                                  ],
                                if (groupedData[tanggal]![i]['rencana_rute'].isEmpty)
                                  pw.Text(
                                    'Tidak Ada',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw
                                        .FontWeight.normal),
                                  ),
                              ]
                          )
                          ]
                      ),
                      pw.SizedBox(height: 5),
                  ],
                ],
              );
            },
          ),
        );
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/example.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Container _buildCell(String content, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      color: isHeader ? PdfColors.white : PdfColors.white,
      child: pw.Text(
        content,
        style: isHeader
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
            : pw.TextStyle(),
      ),
    );
  }

  void openPDF(String path) {
    OpenFile.open(path, type: 'application/pdf', uti: 'public.pdf');
  }

  Future<void> _saveAndViewPdf(String pdfContent) async {
    // Mendapatkan direktori penyimpanan lokal
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String pdfPath = '${directory.path}/LaporanAbsensi${DateFormat('EEEE, d MMM y', 'id').format(DateTime.now())}.pdf';

      // Menyimpan konten PDF ke dalam file
      File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await File(pdfContent).readAsBytes());

      // Membuka file PDF
      OpenFile.open(pdfPath, type: 'application/pdf', uti: 'public.pdf');
    } else {
      print('Gagal mendapatkan direktori penyimpanan eksternal.');
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
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  // void generateCSV(Map<String, List<Map<String, dynamic>>> groupedData) async {
  //   // Header CSV
  //   List<List<dynamic>> csvData = [
  //     ['Nama', 'Tanggal', 'User ID', 'Absen Masuk', 'Absen Pulang', 'Rencana Rute']
  //   ];
  //
  //   // Data CSV
  //   groupedData.forEach((tanggal, items) {
  //     items.forEach((item) {
  //       String nama = item['nama'] ?? '';
  //       String tanggal = item['tanggal'] ?? '';
  //       String userId = item['user_id'] ?? '';
  //
  //       // Menyiapkan baris untuk nilai absen dan rencana_rute pada tanggal tertentu
  //       List<dynamic> rowData = [nama, tanggal, userId, null, null, null];
  //
  //       // Memeriksa dan menambahkan nilai absen pada baris tersebut
  //       // Memeriksa dan menambahkan nilai absen pada baris tersebut
  //       if (item['absen'] != null) {
  //         item['absen']!.forEach((absenItem) {
  //           if (absenItem['jenis'] == 'DATANG') {
  //             rowData[3] ??= ''; // Inisialisasi jika null
  //             rowData[3] += '${absenItem['jenis']} : ${absenItem['jam']}\n';
  //           } else if (absenItem['jenis'] == 'PULANG') {
  //             rowData[3] ??= ''; // Inisialisasi jika null
  //             rowData[3] += '${absenItem['jenis']} : ${absenItem['jam']}\n';
  //           }
  //         });
  //       }
  //
  //       // Memeriksa dan menambahkan nilai rencana_rute pada baris tersebut
  //       if (item['rencana_rute'] != null) {
  //         item['rencana_rute']!.forEach((rencanaRuteItem) {
  //           rowData[5] = '${rencanaRuteItem['keterangan']} : ${rencanaRuteItem['jam_mulai']} - ${rencanaRuteItem['jam_selesai']}';
  //         });
  //       }
  //
  //       // Menambahkan baris ke csvData
  //       csvData.add(rowData);
  //     });
  //   });
  //
  //   // Tulis ke file CSV
  //   Directory? appDocumentsDirectory = await getExternalStorageDirectory();
  //   String appDocumentsPath = appDocumentsDirectory?.path ?? '';
  //   final csvFile = File('$appDocumentsPath/example.csv');
  //   csvFile.writeAsString(const ListToCsvConverter().convert(csvData));
  //
  //   OpenFile.open(csvFile.path);
  // }

  // Future<void> generateAndDownloadCSV() async {
  //   // Fetch data using the existing fetchDataDetailPDF() function
  //
  //   // Combine 'rencana_rute' and 'absen' data into a single list
  //   List<Map<String, dynamic>> combinedData = [];
  //   combinedData.addAll(detailRencanaRutePDF);
  //   combinedData.addAll(detailAbsenDataPDF);
  //
  //   // Group data by 'tanggal'
  //   Map<String, List<Map<String, dynamic>>> groupedData = {};
  //   combinedData.forEach((item) {
  //     String tanggal = item['tanggal'];
  //     if (!groupedData.containsKey(tanggal)) {
  //       groupedData[tanggal] = [];
  //     }
  //     groupedData[tanggal]?.add(item); // Use the null-aware operator to safely add the item to the list
  //   });
  //
  //   // Prepare CSV data
  //   List<List<dynamic>> csvData = [
  //     ['tanggal', 'nama', 'action']
  //   ];
  //
  //   groupedData.forEach((tanggal, items) {
  //     items.forEach((item) {
  //       String? nama = item['driver']?['displayName'];
  //       String action = (item.containsKey('jam'))
  //           ? item['jenis'] ?? 'unknown' // Use 'jenis' for 'absen'
  //           : item['keterangan'] ?? 'unknown'; // Use 'keterangan' for 'rencana_rute'
  //
  //       csvData.add([tanggal, nama, action]);
  //     });
  //   });
  //
  //   // Generate CSV file
  //   Directory? appDocumentsDirectory = await getExternalStorageDirectory();
  //   String appDocumentsPath = appDocumentsDirectory?.path ?? '';
  //   final csvFile = File('$appDocumentsPath/example.csv');
  //   csvFile.writeAsString(const ListToCsvConverter().convert(csvData));
  //
  //   // Open the CSV file for download
  //   OpenFile.open(csvFile.path);
  // }

  Future<void> generateAndDownloadCSV() async {
    // Fetch data using the existing fetchDataDetailPDF() function

    // Combine 'rencana_rute' and 'absen' data into a single list
    List<Map<String, dynamic>> combinedData = [];
    combinedData.addAll(detailRencanaRutePDF);
    combinedData.addAll(detailAbsenDataPDF);

    // Group data by 'tanggal'
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    combinedData.forEach((item) {
      String tanggal = item['tanggal'];
      if (!groupedData.containsKey(tanggal)) {
        groupedData[tanggal] = [];
      }
      groupedData[tanggal]?.add(item); // Use the null-aware operator to safely add the item to the list
    });

    // Prepare CSV data
    List<List<dynamic>> csvData = [
      ['tanggal', 'nama', 'action']
    ];

    groupedData.forEach((tanggal, items) {
      items.forEach((item) {
        String? nama = item['driver']?['displayName'];
        String action = (item.containsKey('jam'))
            ? item['jenis'] ?? 'null' // Use 'jenis' for 'absen'
            : item['keterangan'] ?? 'null'; // Use 'keterangan' for 'rencana_rute'

        csvData.add([tanggal, nama, action]);
      });
    });

    // Generate CSV file
    Directory? appDocumentsDirectory = await getExternalStorageDirectory();
    String appDocumentsPath = appDocumentsDirectory?.path ?? '';
    final csvFile = File('$appDocumentsPath/example.csv');
    csvFile.writeAsString(const ListToCsvConverter().convert(csvData));

    // Open the CSV file for download
    OpenFile.open(csvFile.path);
    combinedData.clear();
  }

  void _showPopupTombolDownload(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download : '),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final pdfPath = await generatePDF(detailStatusAbsen, detailAbsenDataPDF, detailRencanaRutePDF);
                print('PDF generated successfully.');
                openPDF(pdfPath);
                _saveAndViewPdf(pdfPath);
                combinedData = [];
                groupedData.clear();
              },
              child: Text('PDF'),
            ),
            ElevatedButton(
              onPressed: () async {
                generateAndDownloadCSV();
              },
              child: Text('Excel'),
            ),
          ],
        );
      },
    );
  }

  void showPilihDriver(BuildContext context, String driverId, String ownerId) {
    final screenSize = MediaQuery.of(context).size;
    String selectedOwnerId = '';
    bool isChecked = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: screenSize.height * 1,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                                padding: EdgeInsets.all(16),
                                child:  Row(
                                  children: [
                                    Text(
                                      'Ditugaskan ke',
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
                            ),
                            for (var item in dataOwner)
                              Column(
                                children: [
                                  Padding(
                                      padding: EdgeInsets.all(16),
                                      child:  Container(
                                        height: 50,
                                        child: Row(
                                          children: [
                                            Radio<String>(
                                              value: item['id'],
                                              groupValue: selectedOwnerId,
                                              onChanged: (String? value) {
                                                setState(() {
                                                  selectedOwnerId = value ?? '';
                                                });
                                              },
                                            ),
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
                                                )
                                              ],
                                            ),
                                            Spacer(),
                                          ],
                                        ),
                                      )
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            SizedBox(height: 10,),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Container(
                                  height: 50,
                                  child: CustomButton(
                                    onPressed: () async {
                                      if(ownerId == selectedOwnerId){
                                        print('id sama');
                                        runMutationFunctionInsertDriver(ownerId: selectedOwnerId, driverId: driverId).then((_) {
                                          // This block will be executed after the mutation is complete
                                          fetchData1();
                                          fetchDataWA2();
                                          Get.back();
                                        });
                                      }else{
                                        print('id beda');
                                        runMutationFunctionUpdateDriver(driverId: selectedOwnerId, ownerId: selectedOwnerId).then((_) {
                                          runMutationFunctionUpdateDriver(driverId: ownerId, ownerId: selectedOwnerId).then((_) {
                                            runMutationFunctionInsertDriver(ownerId: selectedOwnerId, driverId: driverId).then((_) {
                                              // This block will be executed after the mutation is complete
                                              fetchData1();
                                              fetchDataWA2();
                                              Get.back();
                                            });
                                          });
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
                            )
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

  Future<void> runMutationFunctionInsertDriver({
    required String ownerId,
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
  insert_jadwal_driver_one(object:  {driver_id: "$driverId", owner_id: "$ownerId", tanggal: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}) {
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

  Future<void> runMutationFunctionUpdateDriver({
    required String driverId,
    required String ownerId
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
  update_jadwal_driver(where: {owner_id: {_eq: "$driverId"}, _and: {tanggal: {_eq: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}"}}}, _set: {active: false}) {
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

    return WillPopScope(child: DefaultTabController(
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
              // InkWell(
              //   onTap: () async {
              //     // await  fetchDataDetailPDF();
              //     // for (var statusAbsen in detailStatusAbsen) {
              //     //   String tanggal = statusAbsen['tanggal'];
              //     //   String userId = statusAbsen['user_id'];
              //     //   String nama = statusAbsen['driver']['displayName'];
              //     //   // Temukan data absen berdasarkan tanggal dan user_id
              //     //   var absen = detailAbsenDataPDF.where(
              //     //         (element) =>
              //     //     element['tanggal'] == '$tanggal' &&
              //     //         element['user_id'] == '$userId',
              //     //   ).toList();
              //     //
              //     //   // Temukan data rencana rute berdasarkan tanggal dan user_id
              //     //   var rencanaRute = detailRencanaRutePDF.where((element) =>
              //     //   element['tanggal'] == '$tanggal' &&
              //     //       element['user_id'] == '$userId',).toList();
              //     //   print('ini rencana rute $rencanaRute');
              //     //   print('ini absen $absen');
              //     //   print('ini user id $userId');
              //     //
              //     //   // Gabungkan data dan tambahkan ke dalam array hasil
              //     //   var combinedItem = {
              //     //     'nama' : nama,
              //     //     'tanggal': tanggal,
              //     //     'user_id': userId,
              //     //     'absen': absen,
              //     //     'rencana_rute': rencanaRute,
              //     //   };
              //     //   combinedData.add(combinedItem);
              //     // }
              //     // final pdfPath = await generatePDF(detailStatusAbsen, detailAbsenDataPDF, detailRencanaRutePDF);
              //     // print('PDF generated successfully.');
              //     // openPDF(pdfPath);
              //     // _saveAndViewPdf(pdfPath);
              //     // combinedData = [];
              //     // groupedData.clear();
              //     _showPopupTombolDownload(context);
              //   },
              //   child: Image.asset('assets/img/Downlaod.png',
              //     scale: 2.9,
              //   )
              // ),
              SizedBox(width: 5,),
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
                      fetchDataDetailPDF(DateFormat('yyyy-MM-dd').format(selectedDate1 ?? DateTime.now()), DateFormat('yyyy-MM-dd').format(selectedDate2 ?? DateTime.now()));
                    },
                    onCancelClick: () {
                      fetchData1();
                      fetchDataDetailPDF(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32))), DateFormat('yyyy-MM-dd').format(DateTime.now()));
                    },
                  );
                },
                child:  Icon(Icons.calendar_month,
                  size: 30,
                ),
              ),
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
            Obx(() {
              return RefreshIndicator(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            // judul Dan Kalendar
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
                                                  fetchDataDetailPDF(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 32))), DateFormat('yyyy-MM-dd').format(DateTime.now()));
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
                                  await fetchDataDetail(item['tanggal'], item['driver']['id']);

                                  showDetailAbsensiModal(context, item['has_absen'], item['tanggal'], item['driver']['id'], item['has_approve'], item['ownerData'] != null ? item['ownerData']['displayName'] ?? '' : '');
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
                              ),
                          ]
                      ),
                    ),
                  ),
                  onRefresh: refreshData
              );
            }),

            // Tab 2:
            Obx(() {
              return RefreshIndicator(
                  child: SingleChildScrollView(
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
                                            width: 50.0,
                                            height: 50.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['displayName'] ?? '',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            Text(item['defaultRole'] ?? '',
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
                                          onTap: () async {
                                            await fetchDataOwner();
                                            showPilihDriver(context, item['idDriver'], item['jadwalData'] != null ? item['jadwalData']['idOwner'] : '');
                                          },
                                          child: Icon(
                                            Icons.person_add_alt_1_outlined,
                                            size: 35,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        InkWell(
                                          onTap: (){
                                            if(item['phoneNumber'] != null) {
                                              openWhatsAppOrBrowser(
                                                  item['phoneNumber']);
                                            }else{
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'No. Telepon Tidak Ada'),
                                                  ));
                                            }
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
                  ),
                  onRefresh: refreshDataWA);
            })
          ],
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
