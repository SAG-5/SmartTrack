// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';
// import 'package:intl/intl.dart';

// class TaskDetailsScreen extends StatefulWidget {
//   final String taskId;
//   final Map<String, dynamic> taskData;

//   TaskDetailsScreen({required this.taskId, required this.taskData});

//   @override
//   _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
// }

// class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
//   final TextEditingController _notesController = TextEditingController();
//   File? _selectedFile;
//   bool _isSubmitting = false;
//   String? _uploadedFileUrl; // ✅ تخزين رابط الملف بعد رفعه

//   late bool isTaskOverdue;

//   @override
//   void initState() {
//     super.initState();
//     DateTime dueDate = _parseDate(widget.taskData['date']);
//     isTaskOverdue = dueDate.isBefore(DateTime.now()); // ✅ تحديد ما إذا كانت المهمة متأخرة
//   }

//   Future<void> _uploadFile() async {
//     if (_selectedFile == null) return;

//     try {
//       String fileName = "${widget.taskId}_${DateTime.now().millisecondsSinceEpoch}.pdf";
//       Reference storageRef = FirebaseStorage.instance.ref().child("submissions/$fileName");

//       UploadTask uploadTask = storageRef.putFile(_selectedFile!);
//       TaskSnapshot snapshot = await uploadTask;

//       String downloadUrl = await snapshot.ref.getDownloadURL();
//       setState(() {
//         _uploadedFileUrl = downloadUrl;
//       });

//       print("✅ تم رفع الملف بنجاح: $downloadUrl");
//     } catch (e) {
//       print("❌ خطأ في رفع الملف: $e");
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ فشل رفع الملف")));
//     }
//   }

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'txt'],
//     );

//     if (result != null && result.files.isNotEmpty) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//       });
//     }
//   }

//   Future<void> _submitTask() async {
//     if (isTaskOverdue) return;

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       if (_selectedFile != null) {
//         await _uploadFile();
//       }

//       await FirebaseFirestore.instance.collection("tasks").doc(widget.taskId).update({
//         "status": "مكتملة",
//         "submissionNotes": _notesController.text,
//         "submissionFile": _uploadedFileUrl ?? "لم يتم رفع ملف",
//       });

//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ تم إرسال المهمة بنجاح!")));
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ حدث خطأ: $e")));
//     }

//     setState(() {
//       _isSubmitting = false;
//     });
//   }

//   DateTime _parseDate(String? date) {
//     try {
//       return DateFormat('yyyy-MM-dd').parse(date ?? "3000-01-01");
//     } catch (e) {
//       return DateTime(3000, 1, 1);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("📄 ${widget.taskData['title']}")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("📅 تاريخ التسليم: ${widget.taskData['date']}", style: TextStyle(fontSize: 16)),
//             SizedBox(height: 10),
//             Text("📖 الوصف: ${widget.taskData['description']}", style: TextStyle(fontSize: 16)),
//             SizedBox(height: 20),
//             TextField(
//               controller: _notesController,
//               decoration: InputDecoration(labelText: "✍️ أضف ملاحظاتك"),
//               maxLines: 3,
//             ),
//             SizedBox(height: 10),
//             ElevatedButton.icon(
//               onPressed: isTaskOverdue ? null : _pickFile,
//               icon: Icon(Icons.attach_file),
//               label: Text(_selectedFile == null ? "📂 اختر ملف" : "📄 تم اختيار الملف"),
//             ),
//             Spacer(),
//             ElevatedButton(
//               onPressed: isTaskOverdue ? null : _submitTask, // ✅ تعطيل الزر إذا انتهى الوقت
//               child: Text("📤 إرسال المهمة"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isTaskOverdue ? Colors.grey : Colors.blue, // ✅ لون رمادي عند انتهاء المهلة
//                 padding: EdgeInsets.symmetric(vertical: 15),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
