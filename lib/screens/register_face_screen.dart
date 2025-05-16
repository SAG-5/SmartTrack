import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart'; // تأكد أنك مستورد هذا الملف

class RegisterFaceScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const RegisterFaceScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _RegisterFaceScreenState createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _handleFaceRegistration() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?['face_token'] != null) {
      setState(() => _loading = false);
      _showDialog("تم تسجيل الوجه مسبقًا", "لا يمكنك تسجيل بصمة الوجه أكثر من مرة.");
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) {
      setState(() => _loading = false);
      _showDialog("لم يتم التقاط صورة", "يرجى إعادة المحاولة.");
      return;
    }

    final imageFile = File(pickedFile.path);

    // التحقق من تسجيل الوجه مسبقًا
    final alreadyExists = await _isFaceAlreadyRegistered(imageFile);
    if (alreadyExists) {
      setState(() => _loading = false);
      _showDialog("⚠️ هذا الوجه مسجّل سابقًا", "تم رفض الصورة لأنها مستخدمة مسبقًا.");
      return;
    }

    final faceToken = await _getFaceToken(imageFile);
    if (faceToken == null) {
      setState(() => _loading = false);
      _showDialog("فشل التعرف على الوجه", "تأكد من أن وجهك ظاهر بوضوح.");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'face_token': faceToken,
    }, SetOptions(merge: true));

    await _addFaceToFaceSet(faceToken);

    setState(() => _loading = false);
    _showDialog("تم بنجاح", "✅ تم تسجيل بصمة الوجه بنجاح.");

    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(toggleTheme: widget.toggleTheme)),
      );
    });
  }

  Future<String?> _getFaceToken(File imageFile) async {
    final uri = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/detect");
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf'
      ..fields['api_secret'] = 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM'
      ..fields['return_landmark'] = '1'
      ..files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final decoded = json.decode(responseData);

    if (decoded['faces'] != null && decoded['faces'].isNotEmpty) {
      return decoded['faces'][0]['face_token'];
    }
    return null;
  }

  Future<bool> _isFaceAlreadyRegistered(File imageFile) async {
    final token = await _getFaceToken(imageFile);
    if (token == null) return false;

    final uriSearch = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/search");
    final response = await http.post(uriSearch, body: {
      'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',
      'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',
      'face_token': token,
      'outer_id': 'smarttrack_faceset',
    });

    final result = json.decode(response.body);
    if (result['results'] != null && result['results'].isNotEmpty) {
      final confidence = result['results'][0]['confidence'];
      return confidence > 80;
    }
    return false;
  }

  Future<void> _addFaceToFaceSet(String faceToken) async {
    final uri = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/faceset/addface");
    final response = await http.post(uri, body: {
      'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',
      'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',
      'outer_id': 'smarttrack_faceset',
      'face_tokens': faceToken,
    });

    final body = json.decode(response.body);
    if (response.statusCode == 200 && body['face_added'] == 1) {
      print("✅ تم إضافة الوجه إلى FaceSet");
    } else {
      print("❌ خطأ أثناء الإضافة إلى FaceSet: ${body['error_message']}");
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("موافق"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل بصمة الوجه")),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: Icon(Icons.camera_alt),
                label: Text("التقاط صورة الوجه"),
                onPressed: _handleFaceRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
      ),
    );
  }
}
