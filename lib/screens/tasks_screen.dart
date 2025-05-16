// ✅ TasksScreen - نسخة احترافية مع Timestamp.now() + منع الإرسال أكثر من مرة

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'submitted_tasks_screen.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _noteController = TextEditingController();
  String? academicNumber;
  DocumentSnapshot? weeklyTask;

  @override
  void initState() {
    super.initState();
    _fetchUserAndTask();
  }

  void _fetchUserAndTask() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      academicNumber = userDoc['academicNumber'];

      final now = DateTime.now();
      final thisSunday = now.weekday == 7 ? now : now.subtract(Duration(days: now.weekday));
      final startDate = DateTime(thisSunday.year, thisSunday.month, thisSunday.day, 5);
      final endDate = startDate.add(Duration(days: 4, hours: 12));

      final tasks = await _firestore
          .collection('weekly_tasks')
          .where('academicNumber', isEqualTo: academicNumber)
          .where('startDate', isEqualTo: Timestamp.fromDate(startDate))
          .limit(1)
          .get();

      if (tasks.docs.isEmpty) {
        final newTaskRef = _firestore.collection('weekly_tasks').doc();
        await newTaskRef.set({
          'academicNumber': academicNumber,
          'title': 'مهمة الأسبوع - ${DateFormat('dd/MM/yyyy').format(startDate)}',
          'description': 'يرجى توثيق ما تم إنجازه من مهام التدريب',
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'submitted': false,
          'viewed': true,
          'submissions': [],
        });
        _fetchUserAndTask();
      } else {
        setState(() {
          weeklyTask = tasks.docs.first;
        });
      }
    }
  }

  Future<void> _submitTask() async {
    if (weeklyTask == null) return;
    final data = weeklyTask!.data() as Map<String, dynamic>;
    final submissions = data['submissions'] as List<dynamic>? ?? [];

    if (data['submitted'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ لقد أرسلت المهمة بالفعل ولا يمكنك إرسالها مرة أخرى.")),
      );
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ الرجاء كتابة شرح المهمة قبل الإرسال.")),
      );
      return;
    }

    final newSubmission = {
      "text": _noteController.text.trim(),
      "submittedAt": Timestamp.now(),
    };

    await _firestore.collection('weekly_tasks').doc(weeklyTask!.id).update({
      "submitted": true,
      "viewed": false,
      "submissions": FieldValue.arrayUnion([newSubmission]),
    });

    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ تم إرسال المهمة بنجاح.")),
    );

    _fetchUserAndTask(); // يعيد تحميل المهمة وتحديث الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📋 المهمة الأسبوعية"), backgroundColor: Colors.indigo),
      body: academicNumber == null
          ? Center(child: CircularProgressIndicator())
          : weeklyTask == null
              ? Center(child: Text("🟢 لا توجد مهام حالياً"))
              : _buildTaskCard(weeklyTask!),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubmittedTasksScreen()),
          );
        },
        icon: Icon(Icons.assignment_turned_in),
        label: Text("المهام المرسلة", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildTaskCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? endTimestamp = data['endDate'];
    DateTime? dueDate = endTimestamp?.toDate();
    final submissions = data['submissions'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📌 ${data['title'] ?? 'عنوان غير متوفر'}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              dueDate != null
                  ? Text("🗓️ التاريخ النهائي: ${DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(dueDate)}")
                  : SizedBox.shrink(),
              SizedBox(height: 12),
              Text("📝 شرح المهمة:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(hintText: "قم بكتابة المهام الاسبوعية هنا...", border: OutlineInputBorder()),
                maxLines: 4,
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _submitTask,
                icon: Icon(Icons.send),
                label: Text("إرسال المهمة"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              if (submissions.isNotEmpty) ...[
                SizedBox(height: 24),
                Text("📑 جميع الإرسالات السابقة:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...submissions.reversed.map((sub) {
                  final time = (sub['submittedAt'] as Timestamp).toDate();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text("🕒 ${DateFormat('yyyy-MM-dd – hh:mm a').format(time)}"),
                        Text("📝 ${sub['text'] ?? ''}"),
                      ],
                    ),
                  );
                }),
              ],
              if (data['evaluation'] != null) ...[
                SizedBox(height: 20),
                Row(
                  children: [
                    Text("⭐ التقييم: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${data['evaluation']} من 5"),
                  ],
                ),
              ],
              if (data['note'] != null && data['note'].toString().trim().isNotEmpty) ...[
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("💬 ملاحظة المشرف: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(data['note'])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}