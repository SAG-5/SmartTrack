import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegisterScreen extends StatefulWidget {
  @override
  _AdminRegisterScreenState createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _registerAdmin() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack("❗️الرجاء تعبئة جميع الحقول");
      return;
    }

    if (!RegExp(r'^[0-9]{9,15}$').hasMatch(phone)) {
      _showSnack("📱 رقم الجوال غير صالح");
      return;
    }

    if (password != confirmPassword) {
      _showSnack("❌ كلمات المرور غير متطابقة");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection("admins").doc(uid).set({
        "fullName": name,
        "email": email,
        "phone": phone,
        "role": "admin",
        "createdAt": Timestamp.now(),
      });

      _showSnack("✅ تم إنشاء حساب المشرف بنجاح!");
      Navigator.pop(context);
    } catch (e) {
      _showSnack("❌ خطأ: ${_parseError(e.toString())}");
    }

    setState(() => _isLoading = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _parseError(String error) {
    if (error.contains('email-already-in-use')) {
      return "البريد الإلكتروني مستخدم مسبقًا.";
    } else if (error.contains('weak-password')) {
      return "كلمة المرور ضعيفة جدًا.";
    } else if (error.contains('invalid-email')) {
      return "صيغة البريد الإلكتروني غير صحيحة.";
    } else {
      return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل مشرف جديد")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "الاسم"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "البريد الإلكتروني"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: "رقم الجوال"),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "كلمة المرور"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: "تأكيد كلمة المرور"),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _registerAdmin,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("إنشاء الحساب"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
