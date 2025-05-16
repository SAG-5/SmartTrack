import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ تسجيل الحضور
  Future<void> markAttendance() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String academicNumber = user.email!.split('@')[0];

        await _firestore.collection("attendance").doc().set({ // 🔥 إنشاء سجل جديد كل مرة
          "academicNumber": academicNumber,
          "timestamp": FieldValue.serverTimestamp(),
        });

        print("✅ تم تسجيل الحضور بنجاح!");
      }
    } catch (e) {
      print("❌ خطأ في تسجيل الحضور: $e");
    }
  }

  // ✅ جلب بيانات الحضور من Firestore
  Stream<QuerySnapshot> getAttendanceRecords() {
    return _firestore
        .collection('attendance')
        .orderBy('timestamp', descending: true) // ترتيب الحضور من الأحدث للأقدم
        .snapshots();
  }
}

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📋 سجل الحضور"),
        backgroundColor: Colors.grey[300],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _attendanceService.getAttendanceRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("🚫 لا يوجد حضور مسجل"));
          }

          var records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index];

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green, size: 30),
                  title: Text(
                    "📅 ${_formatDate(record['timestamp'])}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 5),
                      Text("${_formatTime(record['timestamp'])}"),
                      SizedBox(width: 10),
                      Icon(Icons.school, size: 16),
                      SizedBox(width: 5),
                      Text("الأكاديمي: ${record['academicNumber']}"),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 20),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _attendanceService.markAttendance(),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ✅ تنسيق التاريخ
  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.year} ${_getMonthName(date.month)} ${date.day}";
  }

  // ✅ تنسيق الوقت
  String _formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute < 10 ? '0' : ''}${date.minute}";
  }

  // ✅ تحويل رقم الشهر إلى اسم بالعربية
  String _getMonthName(int month) {
    List<String> months = [
      "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
      "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    ];
    return months[month - 1];
  }
}
