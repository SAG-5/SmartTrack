import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WeeklyAttendanceReport extends StatefulWidget {
  @override
  State<WeeklyAttendanceReport> createState() => _WeeklyAttendanceReportState();
}

class _WeeklyAttendanceReportState extends State<WeeklyAttendanceReport> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedTraineeId;
  String? selectedTraineeName;
  String? selectedAcademicNumber;
  DateTime selectedDate = DateTime.now();
  String reportType = "weekly";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تقرير الحضور"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("نوع التقرير: "),
                DropdownButton<String>(
                  value: reportType,
                  items: const [
                    DropdownMenuItem(value: "weekly", child: Text("أسبوعي")),
                    DropdownMenuItem(value: "monthly", child: Text("شهري")),
                  ],
                  onChanged: (val) => setState(() => reportType = val!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("users").where("role", isEqualTo: "trainee").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final trainees = snapshot.data!.docs;
                return DropdownButton<String>(
                  value: selectedTraineeId,
                  isExpanded: true,
                  hint: const Text("اختر اسم المتدرب"),
                  items: trainees.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['fullName'] ?? 'بدون اسم'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final doc = trainees.firstWhere((d) => d.id == val);
                    final data = doc.data() as Map<String, dynamic>;
                    setState(() {
                      selectedTraineeId = val;
                      selectedTraineeName = data['fullName'];
                      selectedAcademicNumber = data['academicNumber'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text("اختر التاريخ"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("إنشاء التقرير"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: selectedTraineeId == null
                  ? null
                  : () {
                      if (reportType == "weekly") {
                        _generateWeeklyReport();
                      } else {
                        _generateMonthlyReport();
                      }
                    },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _generateWeeklyReport() async {
    final int diffFromSunday = selectedDate.weekday == DateTime.sunday ? 0 : (selectedDate.weekday - DateTime.sunday);
    final startOfWeek = selectedDate.subtract(Duration(days: diffFromSunday));
    final days = List.generate(5, (i) => startOfWeek.add(Duration(days: i)));

    final records = await _firestore.collection("attendance").doc(selectedAcademicNumber).collection("records").get();

    final dataMap = <String, Map<String, dynamic>>{};
    for (var doc in records.docs) {
      final data = doc.data();
      final date = (data['timestamp'] as Timestamp).toDate();
      final key = DateFormat('yyyy-MM-dd').format(date);
      dataMap[key] = data;
    }

    int presentDays = 0;
    int absentDays = 0;

    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    final arabicFont = pw.Font.ttf(fontData.buffer.asByteData());

    final statuses = days.map((day) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      final status = dataMap.containsKey(key)
          ? (dataMap[key]!['status']?.toString() ?? 'غير معروف')
          : 'غياب';
      if (status == "حضور") presentDays++;
      else absentDays++;
      return status;
    }).toList();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Text("تقرير الحضور الأسبوعي", style: pw.TextStyle(font: arabicFont, fontSize: 22)),
              pw.SizedBox(height: 10),
              pw.Text("اسم المتدرب: $selectedTraineeName", style: pw.TextStyle(font: arabicFont)),
              pw.Text("الرقم الأكاديمي: $selectedAcademicNumber", style: pw.TextStyle(font: arabicFont)),
              pw.Text("الأسبوع: ${DateFormat('dd/MM/yyyy').format(days.first)} إلى ${DateFormat('dd/MM/yyyy').format(days.last)}", style: pw.TextStyle(font: arabicFont)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: days.map((day) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(DateFormat('EEEE', 'ar').format(day), style: pw.TextStyle(font: arabicFont)),
                    )).toList(),
                  ),
                  pw.TableRow(
                    children: statuses.map((status) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(status, style: pw.TextStyle(font: arabicFont)),
                    )).toList(),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text("عدد أيام الحضور: $presentDays", style: pw.TextStyle(font: arabicFont)),
              pw.Text("عدد أيام الغياب: $absentDays", style: pw.TextStyle(font: arabicFont)),
            ],
          ),
        );
      },
    ));

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "تقرير_الحضور_الأسبوعي_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf",
    );
  }

  
Future<void> _generateMonthlyReport() async {
  final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
  final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1, 1);
  final lastDay = nextMonth.subtract(const Duration(days: 1));
  final days = List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));

  final records = await _firestore
      .collection("attendance")
      .doc(selectedAcademicNumber)
      .collection("records")
      .get();

  final dataMap = <String, Map<String, dynamic>>{};
  for (var doc in records.docs) {
    final data = doc.data();
    final date = (data['timestamp'] as Timestamp).toDate();
    final key = DateFormat('yyyy-MM-dd').format(date);
    dataMap[key] = data;
  }

  int presentDays = 0;
  int absentDays = 0;

  final pdf = pw.Document();
  final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
  final arabicFont = pw.Font.ttf(fontData.buffer.asByteData());

  final rows = <pw.TableRow>[
    pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("اليوم", style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("التاريخ", style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("الحالة", style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold))),
      ],
    )
  ];

  for (var day in days) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final status = dataMap.containsKey(key)
        ? (dataMap[key]!['status']?.toString() ?? 'غير معروف')
        : 'غياب';

    if (status == "حضور") presentDays++;
    else absentDays++;

    rows.add(pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('EEEE', 'ar').format(day), style: pw.TextStyle(font: arabicFont))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd/MM/yyyy').format(day), style: pw.TextStyle(font: arabicFont))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(status, style: pw.TextStyle(font: arabicFont))),
      ],
    ));
  }

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    textDirection: pw.TextDirection.rtl,
    build: (context) => [
      pw.Text("تقرير الحضور الشهري", style: pw.TextStyle(font: arabicFont, fontSize: 22)),
      pw.SizedBox(height: 10),
      pw.Text("اسم المتدرب: $selectedTraineeName", style: pw.TextStyle(font: arabicFont)),
      pw.Text("الرقم الأكاديمي: $selectedAcademicNumber", style: pw.TextStyle(font: arabicFont)),
      pw.Text("الشهر: ${DateFormat('MMMM yyyy', 'ar').format(selectedDate)}", style: pw.TextStyle(font: arabicFont)),
      pw.SizedBox(height: 20),
      pw.Table(border: pw.TableBorder.all(), children: rows),
      pw.SizedBox(height: 16),
      pw.Text("عدد أيام الحضور: $presentDays", style: pw.TextStyle(font: arabicFont)),
      pw.Text("عدد أيام الغياب: $absentDays", style: pw.TextStyle(font: arabicFont)),
    ],
  ));

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: "تقرير_الحضور_الشهري_${DateFormat('yyyyMM').format(selectedDate)}.pdf",
  );
}
}
