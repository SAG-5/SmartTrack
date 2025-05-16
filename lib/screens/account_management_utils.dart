import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart'; // تأكد من أنك استوردت SettingsScreen بشكل صحيح

Future<void> deleteAccount(BuildContext context) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ لا يوجد مستخدم مسجل حالياً")),
      );
      return;
    }

    // حذف الوجه من Face++
    await deleteFaceFromFaceSet(user.uid);

    // حذف حساب المستخدم من Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

    // حذف الحساب من Firebase Authentication
    await FirebaseAuth.instance.currentUser?.delete();

    // إظهار رسالة تأكيد بعد حذف الحساب
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ تم حذف الحساب بنجاح")),
    );

    // الانتقال إلى شاشة الإعدادات بعد الحذف (بدلاً من LoginScreen)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(toggleTheme: () {})), // استبدل بـ SettingsScreen
      (route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ فشل في حذف الحساب: ${e.toString()}")),
    );
  }
}

Future<void> deleteFaceFromFaceSet(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final faceToken = doc.data()?['face_token'];

    if (faceToken != null) {
      final url = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/faceset/removeface");

      final response = await http.post(url, body: {
        'api_key': 'YOUR_API_KEY', // استبدل بـ API KEY الخاصة بك
        'api_secret': 'YOUR_API_SECRET', // استبدل بـ API SECRET الخاصة بك
        'outer_id': 'smarttrack_faceset',
        'face_tokens': faceToken,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['face_removed'] != null) {
        print('✅ تم حذف الوجه من FaceSet');
      } else {
        print('❌ فشل الحذف: ${data['error_message']}');
      }
    } else {
      print("❌ لا يوجد face_token لهذا المتدرب.");
    }
  } catch (e) {
    print("❌ حدث خطأ أثناء حذف الوجه من Face++: ${e.toString()}");
  }
}
