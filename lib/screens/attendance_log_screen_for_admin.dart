import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreenForAdmin extends StatelessWidget {
  final String academicNumber;

  AttendanceLogScreenForAdmin({required this.academicNumber});

  Stream<QuerySnapshot> getAttendanceRecords() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(academicNumber)
        .collection('records') // ✅ لازم تكون عندك مجموعة فرعية بهذا الاسم
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📋 سجل حضور $academicNumber'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAttendanceRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("❌ لا يوجد حضور مسجل لهذا المتدرب"));
          }

          var records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index];
              Timestamp timestamp = record['timestamp'];
              DateTime dateTime = timestamp.toDate();
              String date = DateFormat('d MMMM yyyy', 'ar').format(dateTime);
              String time = DateFormat('hh:mm a', 'ar').format(dateTime);
              String status = record['status'];

              IconData iconData;
              Color iconColor;
              if (status == "حضر") {
                iconData = Icons.check_circle;
                iconColor = Colors.green;
              } else if (status == "متأخر") {
                iconData = Icons.access_time;
                iconColor = Colors.orange;
              } else {
                iconData = Icons.cancel;
                iconColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(iconData, color: iconColor, size: 30),
                  title: Text("📅 $date", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text("🕒 $time"),
                      Text("📌 الحالة: $status"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
