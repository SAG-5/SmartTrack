// ✅ تم تعديل الكود ليكون متكامل وقابل للاستخدام الصحيح في التحقق من بصمة الوجه
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class FaceRecognitionService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFaceImage() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  Future<String?> getFaceToken(File imageFile) async {
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

  Future<void> saveFaceToken(String uid, String faceToken) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'face_token': faceToken,
    }, SetOptions(merge: true));
  }

  Future<void> _addFaceToFaceSet(String faceToken) async {
    final uri = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/faceset/addface");
    final response = await http.post(uri, body: {
      'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',
      'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',
      'outer_id': 'smarttrack_faceset',
      'face_tokens': faceToken,
    },
    );

    final body = json.decode(response.body);
    if (response.statusCode == 200 && body['face_added'] == 1) {
      print('✅ Face added to FaceSet');
    } else {
      print('❌ Failed to add face to FaceSet: ${body['error_message']}');
    }
  }

  Future<bool> isFaceAlreadyRegistered(File imageFile) async {
    final faceToken = await getFaceToken(imageFile);
    if (faceToken == null) return false;

    final uriSearch = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/search");
    final searchResponse = await http.post(uriSearch, body: {
      'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',
      'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',
      'face_token': faceToken,
      'outer_id': 'smarttrack_faceset',
    });

    final searchData = json.decode(searchResponse.body);
    if (searchData['results'] != null && searchData['results'].isNotEmpty) {
      final confidence = searchData['results'][0]['confidence'];
      return confidence > 80;
    }
    return false;
  }

  Future<bool> registerFaceForUser(BuildContext context, VoidCallback toggleTheme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ يجب تسجيل الدخول أولًا"), backgroundColor: Colors.red),
      );
      return false;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['face_token'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ تم تسجيل بصمة الوجه مسبقًا"), backgroundColor: Colors.orange),
      );
      return false;
    }

    final pickedFile = await pickFaceImage();
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ لم يتم التقاط الصورة"), backgroundColor: Colors.red),
      );
      return false;
    }

    final file = File(pickedFile.path);
    final alreadyExists = await isFaceAlreadyRegistered(file);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚫 هذا الوجه مسجّل مسبقًا في النظام"), backgroundColor: Colors.red),
      );
      return false;
    }

    final token = await getFaceToken(file);
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل في التعرف على الوجه"), backgroundColor: Colors.red),
      );
      return false;
    }

    await saveFaceToken(user.uid, token);
    await _addFaceToFaceSet(token);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ تم تسجيل بصمة الوجه بنجاح"), backgroundColor: Colors.green),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(toggleTheme: toggleTheme)),
    );

    return true;
  }

  Future<bool> verifyFaceMatch(String capturedToken, String storedToken) async {
    final response = await http.post(
      Uri.parse("https://api-us.faceplusplus.com/facepp/v3/search"),
      body: {
        'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',
        'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',
        'face_token': capturedToken,
        'outer_id': 'smarttrack_faceset',
      },
    );

    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      final matchedToken = data['results'][0]['face_token'];
      final confidence = data['results'][0]['confidence'];
      return confidence > 80 && matchedToken == storedToken;
    }
    return false;
  }
}
