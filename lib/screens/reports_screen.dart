import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'login_screen.dart'; // ✅ تأكد من وجود هذا السطر


class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> attendanceData = {}; // تخزين عدد الأيام اللي حضرها كل طالب

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    DateTime now = DateTime.now();
    DateTime lastWeek = now.subtract(Duration(days: 7)); // تحديد آخر 7 أيام

    var snapshot =
        await _firestore
            .collection("attendance")
            .where(
              "timestamp",
              isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek),
            )
            .get();

    Map<String, int> tempData = {};
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String studentId = data['academicNumber'];

      tempData[studentId] = (tempData[studentId] ?? 0) + 1;
    }

    setState(() {
      attendanceData = tempData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📊 تقارير الحضور (آخر 7 أيام)"),backgroundColor: Colors.grey[300],),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            attendanceData.isEmpty
                ? Center(child: Text("❌ لا يوجد بيانات حضور للأسبوع الماضي"))
                : BarChart(
                  BarChartData(
                    barGroups:
                        attendanceData.entries.map((entry) {
                          return BarChartGroupData(
                            x:
                                int.tryParse(entry.key.toString()) ??
                                0, // ✅ يحول النص إلى رقم بأمان
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: Colors.blue,
                              ),
                            ],
                          );
                        }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString());
                          },
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
