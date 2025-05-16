import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/face_recognition_service.dart';
import 'manual_location_picker_screen.dart';
import 'settings_screen.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  final double allowedRadiusInMeters = 5000;
  bool _isSubmitting = false;

  Future<void> markAttendance(BuildContext context) async {
    if (_isSubmitting) return;
    if (mounted) setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackbar("❌ يجب تسجيل الدخول أولاً!", Colors.red);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        _showSnackbar("❌ لم يتم العثور على بياناتك!", Colors.red);
        return;
      }

      final academicNumber = userData['academicNumber'];
      final trainingOrg = userData['trainingOrganization'];
      final trainingCity = userData['trainingCity'];
      var trainingLocation = userData['trainingLocation'];
      final faceToken = userData['face_token'];

      if (academicNumber == null || academicNumber.toString().isEmpty) {
        _showSnackbar("❌ الرقم الأكاديمي غير متوفر!", Colors.red);
        return;
      }

      if (trainingOrg == null || trainingOrg.toString().isEmpty || 
          trainingCity == null || trainingCity.toString().isEmpty) {
        _showSnackbar("⚠️ يجب إدخال اسم جهة التدريب وبصمة ال", Colors.orange);
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(toggleTheme: () {})));
        return;
      }

      if (trainingLocation == null || trainingLocation['lat'] == null || trainingLocation['lon'] == null) {
        final locationResult = await Navigator.push<Map<String, double>>(
          context,
          MaterialPageRoute(
            builder: (_) => ManualLocationPickerScreen(
              onLocationSelected: (lat, lon) async {
                await _firestore.collection('users').doc(user.uid).update({
                  'trainingLocation': {'lat': lat, 'lon': lon}
                });
                return {'lat': lat, 'lon': lon};
              },
            ),
          ),
        );

        if (locationResult != null) {
          if (mounted) setState(() => _isSubmitting = false);
          await markAttendance(context);
          return;
        } else {
          if (mounted) setState(() => _isSubmitting = false);
          return;
        }
      }

      if (faceToken == null) {
        _showSnackbar("⚠️ يجب تسجيل بصمة الوجه أولاً", Colors.orange);
        return;
      }

final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        trainingLocation['lat'],
        trainingLocation['lon'],
      );

      if (distance > allowedRadiusInMeters) {
        _showSnackbar("🚫 يجب أن تكون داخل موقع التدريب (المسافة: ${distance.toStringAsFixed(1)}م)", Colors.red);
        return;
      }

      final pickedFile = await _faceService.pickFaceImage();
      if (pickedFile == null) {
        _showSnackbar("❌ لم يتم التقاط صورة الوجه", Colors.red);
        return;
      }

      final capturedToken = await _faceService.getFaceToken(File(pickedFile.path));
      if (capturedToken == null) {
        _showSnackbar("❌ فشل في تحليل صورة الوجه", Colors.red);
        return;
      }

      final isMatched = await _faceService.verifyFaceMatch(capturedToken, faceToken);
      if (!isMatched) {
        _showSnackbar("❌ التحقق من الوجه فشل", Colors.red);
        return;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final existingRecord = await _firestore
          .collection("attendance")
          .doc(academicNumber)
          .collection("records")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (existingRecord.docs.isNotEmpty) {
        _showSnackbar("⚠️ تم تسجيل حضورك مسبقًا اليوم", Colors.orange);
        return;
      }

      await _firestore
          .collection("attendance")
          .doc(academicNumber)
          .collection("records")
          .add({
        "timestamp": Timestamp.now(),
        "status": "حضر",
        "faceVerified": true,
        "location": {
          "lat": position.latitude,
          "lng": position.longitude,
          "distance": distance,
        }
      });

      _showSnackbar("✅ تم تسجيل حضورك بنجاح", Colors.green);
    } catch (e) {
      _showSnackbar("❌ حدث خطأ أثناء تسجيل الحضور:\n${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

void _showSnackbar(String message, Color color) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "اضغط لتسجيل حضورك",
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => markAttendance(context),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("تسجيل الحضور", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: _isSubmitting ? Colors.grey : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}