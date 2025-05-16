// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class TraineeTasksScreen extends StatefulWidget {
//   final String academicNumber;
//   final String fullName;
//   const TraineeTasksScreen({required this.academicNumber, required this.fullName});

//   @override
//   State<TraineeTasksScreen> createState() => _TraineeTasksScreenState();
// }

// class _TraineeTasksScreenState extends State<TraineeTasksScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, TextEditingController> _gradeControllers = {};
//   Map<String, TextEditingController> _noteControllers = {};

//   @override
//   void dispose() {
//     _gradeControllers.forEach((key, controller) => controller.dispose());
//     _noteControllers.forEach((key, controller) => controller.dispose());
//     super.dispose();
//   }

//   Stream<QuerySnapshot> getTasksStream() {
//     return _firestore
//         .collection("tasks")
//         .where("academicNumber", isEqualTo: widget.academicNumber)
//         .orderBy("assignedDate", descending: true)
//         .snapshots();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("📋 مهام ${widget.fullName}"),
//         backgroundColor: Colors.indigo,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: getTasksStream(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text("حدث خطأ في تحميل البيانات"));
//           }

//           final tasks = snapshot.data!.docs;
//           final now = DateTime.now();

//           final ongoing = tasks.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final dueDate = (data['reopenedUntil'] ?? data['dueDate']) as Timestamp?;
//             final due = dueDate?.toDate();
//             return data['status'] == 'قيد التنفيذ' && due != null && now.isBefore(due);
//           }).toList();

//           final completed = tasks.where((doc) => doc['status'] == 'مكتملة').toList();

//           final expired = tasks.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final dueDate = (data['reopenedUntil'] ?? data['dueDate']) as Timestamp?;
//             final due = dueDate?.toDate();
//             return data['status'] == 'قيد التنفيذ' && due != null && now.isAfter(due);
//           }).toList();

//           return ListView(
//             padding: EdgeInsets.all(16),
//             children: [
//               if (ongoing.isNotEmpty) ...[
//                 _buildSectionTitle("🟡 مهام قيد التنفيذ"),
//                 ...ongoing.map((doc) => _buildTaskCard(doc, Colors.amber[100]!)),
//               ],
//               if (completed.isNotEmpty) ...[
//                 _buildSectionTitle("✅ مهام مكتملة"),
//                 ...completed.map((doc) => _buildTaskCard(doc, Colors.green[100]!)),
//               ],
//               if (expired.isNotEmpty) ...[
//                 _buildSectionTitle("⛔ مهام منتهية"),
//                 ...expired.map((doc) => _buildTaskCard(doc, Colors.red[100]!)),
//               ],
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//     );
//   }

//   Widget _buildTaskCard(DocumentSnapshot doc, Color color) {
//     final data = doc.data() as Map<String, dynamic>;
//     final taskId = doc.id;
//     final due = (data['dueDate'] as Timestamp?)?.toDate();
//     final reopenedUntil = (data['reopenedUntil'] as Timestamp?)?.toDate();
//     final isGraded = data['grade'] != null && data['grade'].toString().isNotEmpty;

//     _gradeControllers.putIfAbsent(taskId, () => TextEditingController());
//     _noteControllers.putIfAbsent(taskId, () => TextEditingController());

//     return Card(
//       color: color,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(child: Text("📌 ${data['title'] ?? ''}", style: TextStyle(fontWeight: FontWeight.bold))),
//                 PopupMenuButton<String>(
//                   onSelected: (value) {
//                     if (value == 'reopen') {
//                       _reopenTask(taskId);
//                     } else if (value == 'delete') {
//                       _confirmDelete(taskId);
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     PopupMenuItem(value: 'reopen', child: Text('إعادة فتح المهمة')),
//                     PopupMenuItem(value: 'delete', child: Text('حذف المهمة')),
//                   ],
//                   icon: Icon(Icons.settings, color: Colors.black54),
//                 ),
//               ],
//             ),
//             SizedBox(height: 4),
//             if (data['submittedText'] != null) Text("📝 ملاحظات المتدرب: ${data['submittedText']}"),
//             if (due != null) Text("📅 الموعد النهائي: ${DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(due)}"),
//             if (reopenedUntil != null)
//               Text("⏳ مفتوح حتى: ${DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(reopenedUntil)}"),
//             SizedBox(height: 10),
//             if (isGraded)
//               Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green),
//                   SizedBox(width: 6),
//                   Text("تم تقييم المتدرب", style: TextStyle(color: Colors.green)),
//                 ],
//               )
//             else ...[
//               TextField(
//                 controller: _gradeControllers[taskId],
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: "درجة من 10"),
//               ),
//               TextField(
//                 controller: _noteControllers[taskId],
//                 decoration: InputDecoration(labelText: "ملاحظات للمُتدرب"),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () => _submitGrade(taskId),
//                     icon: Icon(Icons.check),
//                     label: Text("تقييم"),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                   ),
//                 ],
//               ),
//             ]
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _reopenTask(String taskId) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );

//     if (pickedDate != null) {
//       TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );

//       if (pickedTime != null) {
//         DateTime reopenedUntil = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );

//         await _firestore.collection("tasks").doc(taskId).update({
//           "status": "قيد التنفيذ",
//           "submitted": false,
//           "submittedText": "",
//           "reopenedUntil": Timestamp.fromDate(reopenedUntil),
//         });
//       }
//     }
//   }

//   Future<void> _submitGrade(String taskId) async {
//     final grade = _gradeControllers[taskId]?.text.trim();
//     final note = _noteControllers[taskId]?.text.trim();
//     if (grade != null && grade.isNotEmpty) {
//       await _firestore.collection("tasks").doc(taskId).update({
//         "grade": grade,
//         "adminNote": note ?? "",
//       });
//     }
//   }

//   Future<void> _confirmDelete(String taskId) async {
//     bool? confirmed = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("تأكيد الحذف"),
//         content: Text("هل أنت متأكد من حذف المهمة؟"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: Text("إلغاء")),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: Text("حذف", style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await _firestore.collection("tasks").doc(taskId).delete();
//     }
//   }
// }
