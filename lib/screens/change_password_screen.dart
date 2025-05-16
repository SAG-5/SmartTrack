import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    try {
      await _auth.currentUser!.updatePassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ تم تغيير كلمة المرور بنجاح"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context); // العودة إلى الشاشة السابقة بعد النجاح
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ فشل التغيير: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تغيير كلمة المرور")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "كلمة المرور الجديدة"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text("تغيير"),
            ),
          ],
        ),
      ),
    );
  }
}
