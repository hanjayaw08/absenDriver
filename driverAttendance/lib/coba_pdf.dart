import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:excel/excel.dart' as Excel;

class MyHomePagePdf extends StatefulWidget {
  @override
  _MyHomePagePdfState createState() => _MyHomePagePdfState();
}

class _MyHomePagePdfState extends State<MyHomePagePdf> {
  List<Map<String, dynamic>> detailAbsenDataPDF = [];
  List<Map<String, dynamic>> detailRencanaRutePDF = [];
  List<Map<String, dynamic>> detailStatusAbsen = [];
  List<Map<String, dynamic>> combinedData = [];

  Future<void> fetchDataDetailPDF() async {
    final GraphQLClient client = GraphQLClient(
      link: HttpLink('http://45.64.3.54:40380/absendriver-api/v1/graphql',
        defaultHeaders: {
          'Authorization': 'Bearer ${'eyJhbGciOiJIUzI1NiJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsibWUiLCJ1c2VyIiwiaHJkIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6ImhyZCIsIngtaGFzdXJhLXVzZXItaWQiOiI1NTg3MTkwMS01ZjgyLTQ4MTctYWQ2MS1mYjZkMzM4MzA4NTIiLCJ4LWhhc3VyYS11c2VyLWlzLWFub255bW91cyI6ImZhbHNlIn0sInN1YiI6IjU1ODcxOTAxLTVmODItNDgxNy1hZDYxLWZiNmQzMzgzMDg1MiIsImlhdCI6MTcwMjM2MjQzNiwiZXhwIjoxNzA0OTU0NDM2LCJpc3MiOiJoYXN1cmEtYXV0aCJ9.RY4i8tVsDlPUDaBIz2K72Yy3kEfqwca5Ch4_3hRLOfY'}', // Ganti dengan token autentikasi Anda
        },
      ),
      cache: GraphQLCache(),
    );

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql('''
         query MyQuery {
  status_absen {
    tanggal
    user_id
      driver {
      displayName
    }
  }
  absen {
    jam
    jenis
    tanggal
    user_id
  }
  rencana_rute {
    keterangan
    jam_mulai
    tanggal
    user_id
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
      detailStatusAbsen = List<Map<String, dynamic>>.from(result.data?['status_absen'] ?? []);
    }
  }

  Future<String> generatePDF() async {
    final pdf = pw.Document();

    final totalItems = combinedData.length;

    final maxItemsPerPage = 3;

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
                pw.Column(
                    children: [
                      pw.Text(
                        'Laporan Absens',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Senin, 19 Januari 2023',
                        style: pw.TextStyle(fontSize: 13),
                      ),
                    ]
                ),
                pw.SizedBox(height: 10),
                for (int i = startIndex; i < endIndex && i < totalItems; i++) ...[
                  pw.Row(
                      children: [
                        pw.Text(
                          combinedData[i]['nama'] ?? '',
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
                                  for (var item in combinedData[i]['absen'])...[
                                    if (item['jenis'] == 'DATANG')
                                      _buildCell(item['jam'], isHeader: true),
                                  ],
                                  if (combinedData[i]['absen'].isEmpty ||
                                      combinedData[i]['absen'].every((item) => item['jenis'] != 'DATANG'))
                                    pw.Text(
                                      'Tidak Ada',
                                      style: pw.TextStyle(fontSize: 13),
                                    ),
                                ]
                            ),
                            pw.Column(
                                children: [
                                  _buildCell('Ijin Sakit', isHeader: true),
                                  for (var item in combinedData[i]['absen'])...[
                                    if (item['jenis'] == 'IZIN SAKIT')
                                      _buildCell(item['jam'], isHeader: true),
                                  ],
                                  if (combinedData[i]['absen'].isEmpty ||
                                      combinedData[i]['absen'].every((item) => item['jenis'] != 'IZIN SAKIT'))
                                    pw.Text(
                                      'Tidak Ada',
                                      style: pw.TextStyle(fontSize: 13),
                                    ),
                                ]
                            ),
                            pw.Column(
                                children: [
                                  _buildCell('Ijin Keluar', isHeader: true),
                                  for (var item in combinedData[i]['absen'])...[
                                    if (item['jenis'] == 'IJIN KELUAR')
                                      _buildCell(item['jam'], isHeader: true),
                                  ],
                                  if (combinedData[i]['absen'].isEmpty ||
                                      combinedData[i]['absen'].every((item) => item['jenis'] != 'IJIN KELUAR'))
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
                                  for (var item in combinedData[i]['absen'])...[
                                    if (item['jenis'] == 'PULANG')
                                      _buildCell(item['jam'], isHeader: true),
                                  ],
                                  if (combinedData[i]['absen'].isEmpty ||
                                      combinedData[i]['absen'].every((item) => item['jenis'] != 'PULANG'))
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
                            if (combinedData[i]['rencana_rute'] != null)
                              for (var item in combinedData[i]['rencana_rute'])...[
                                pw.Text(
                                  '${item['keterangan']} - ${item['jam_mulai']}',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw
                                      .FontWeight.normal),
                                ),
                              ],
                            if (combinedData[i]['rencana_rute'].isEmpty)
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
                ]
              ],
            );
          }
        ),
      );
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
      String pdfPath = '${directory.path}/example.pdf';

      // Menyimpan konten PDF ke dalam file
      File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await File(pdfContent).readAsBytes());

      // Membuka file PDF
      OpenFile.open(pdfPath, type: 'application/pdf', uti: 'public.pdf');
    } else {
      print('Gagal mendapatkan direktori penyimpanan eksternal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Generation Example'),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    fetchDataDetailPDF();
                  });
                  final pdfPath = await generatePDF();
                  print('PDF generated successfully.');
                  openPDF(pdfPath);
                  _saveAndViewPdf(pdfPath);

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
                        element['user_id'] == '$userId',).toList();
                    print('ini rencana rute $rencanaRute');
                    print('ini absen $absen');
                    print('ini user id $userId');

                    // Gabungkan data dan tambahkan ke dalam array hasil
                    var combinedItem = {
                      'nama' : nama,
                      'tanggal': tanggal,
                      'user_id': userId,
                      'absen': absen,
                      'rencana_rute': rencanaRute,
                    };
                    combinedData.add(combinedItem);
                  }

// Hasil akhirnya adalah combinedData
                  // fetchDataDetail();
                },
                child: Column(
                  children: [

                  ],
                ),
              ),
              // Container(
              //   height: 100,
              //   child: ListView.builder(
              //     itemCount: combinedData.length,
              //     itemBuilder: (context, index) {
              //       var item = combinedData[index];
              //       var absenList = item['absen'] as List<Map<String, dynamic>>;
              //
              //       return Column(
              //         children: [
              //           Text(item['tanggal']),
              //           Text(item['user_id']),
              //           for (var absen in absenList)
              //             Column(
              //               children: [
              //                 Text('Jenis: ${absen['jenis'] ?? ''}'),
              //                 // Tambahkan Text widget lainnya untuk properti absen lainnya
              //               ],
              //             ),
              //           Text(item['rencana_rute']['jam_mulai'] ?? ''),
              //         ],
              //       );
              //     },
              //   ),
              // )
            ],
          ),
      ),
    );
  }
}

