import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getAcademicNumber() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists ||
        !(userDoc.data() as Map<String, dynamic>)
            .containsKey('academicNumber')) {
      return null;
    }

    return (userDoc.data() as Map<String, dynamic>)['academicNumber'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getAcademicNumber(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(child: Text("❌ لم يتم العثور على الرقم الأكاديمي")),
          );
        }

        String academicNumber = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text("سجل الحضور",
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Color(0xFF0D47A1),
            elevation: 4,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('attendance')
                .doc(academicNumber)
                .collection('records')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text("❌ خطأ في تحميل البيانات: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("🚫 لا يوجد حضور مسجل"));
              }

              var records = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var record = records[index];
                  Timestamp timestamp = record['timestamp'];
                  DateTime dateTime = timestamp.toDate();
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _formatDate(dateTime),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _formatTime(dateTime),
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(iconData, color: iconColor),
                              SizedBox(width: 8),
                              Text(
                                "الحالة: $status",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat("d MMMM yyyy", "ar").format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat("hh:mm a", "ar").format(date);
  }
}
