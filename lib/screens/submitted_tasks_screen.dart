import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubmittedTasksScreen extends StatefulWidget {
  @override
  _SubmittedTasksScreenState createState() => _SubmittedTasksScreenState();
}

class _SubmittedTasksScreenState extends State<SubmittedTasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? academicNumber;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        academicNumber = userDoc['academicNumber'];
      });
    }
  }

  Stream<QuerySnapshot> _getSubmittedTasks() {
    return _firestore
        .collection('weekly_tasks')
        .where('academicNumber', isEqualTo: academicNumber)
        .where('submitted', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📦 المهام المرسلة'),
        backgroundColor: Colors.indigo,
      ),
      body: academicNumber == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _getSubmittedTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
                }

                final tasks = snapshot.data!.docs;
                if (tasks.isEmpty) {
                  return Center(child: Text('لا توجد مهام مرسلة'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index].data() as Map<String, dynamic>;
                    final submissions = List<Map<String, dynamic>>.from(task['submissions'] ?? []);
                    final latestSubmission = submissions.isNotEmpty ? submissions.last : null;

                    return Card(
                      color: index == 0 ? Colors.grey[200] : Colors.pink[100],
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📌 ${task['title'] ?? ''}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '📅 ${task['startDate'] != null ? DateFormat('yyyy-MM-dd').format((task['startDate'] as Timestamp).toDate()) : ''}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 8),
                            if (latestSubmission != null) ...[
                              Text('📝 الشرح الأخير:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(latestSubmission['text'] ?? ''),
                              SizedBox(height: 8),
                              Text('🕒 تاريخ الإرسال: ${latestSubmission['submittedAt'] != null ? DateFormat('yyyy-MM-dd – hh:mm a').format((latestSubmission['submittedAt'] as Timestamp).toDate()) : ''}'),
                            ] else ...[
                              Text('📝 لا توجد شروحات مرسلة.'),
                            ],
                            if (task['evaluation'] != null) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('⭐ تقييم المشرف: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${task['evaluation']} / 5'),
                                ],
                              ),
                            ],
                            if (task['note'] != null && task['note'].toString().trim().isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('💬 ملاحظة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(task['note'])),
                                ],
                              ),
                            ]
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
