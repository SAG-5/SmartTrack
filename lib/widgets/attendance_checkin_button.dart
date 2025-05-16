import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceCheckInButton extends StatelessWidget {
  const AttendanceCheckInButton({super.key});

  Future<bool> _authenticate() async {
    final LocalAuthentication auth = LocalAuthentication();

    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) return false;

      final authenticated = await auth.authenticate(
        localizedReason: 'الرجاء تأكيد هويتك باستخدام Face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return authenticated;
    } catch (e) {
      debugPrint("خطأ في التحقق البيومتري: $e");
      return false;
    }
  }

  Future<void> _markAttendance(BuildContext context) async {
    final verified = await _authenticate();

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ فشل التحقق من Face ID')),
      );
      return;
    }

    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ المستخدم غير مسجل دخول')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data() as Map<String, dynamic>?;
    final academicNumber = data?['academicNumber'];

    if (academicNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ لم يتم العثور على الرقم الأكاديمي')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(academicNumber)
        .collection('records')
        .add({
      'timestamp': now,
      'status': 'حضر',
      'faceVerified': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم تسجيل الحضور بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _markAttendance(context),
      icon: const Icon(Icons.fingerprint),
      label: const Text('تسجيل الحضور'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
