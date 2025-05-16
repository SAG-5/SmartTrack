import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import 'manual_location_picker_screen.dart';

class CompleteTrainingInfoScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool allowNameEdit;
  final bool allowLocationEdit;

  const CompleteTrainingInfoScreen({
    Key? key,
    required this.toggleTheme,
    required this.allowNameEdit,
    required this.allowLocationEdit,
  }) : super(key: key);

  @override
  _CompleteTrainingInfoScreenState createState() => _CompleteTrainingInfoScreenState();
}

class _CompleteTrainingInfoScreenState extends State<CompleteTrainingInfoScreen> {
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  LatLng? _manualLocation;

  Future<void> _submitTrainingInfo() async {
    final orgName = _orgController.text.trim();
    final cityName = _cityController.text.trim();

    if (widget.allowNameEdit && (orgName.isEmpty || cityName.isEmpty)) {
      _showMessage("\u26a0\ufe0f أدخل جهة التدريب والمدينة");
      return;
    }

    setState(() => _isLoading = true);

    double? latitude;
    double? longitude;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage("\u274c لم يتم العثور على المستخدم");
        setState(() => _isLoading = false);
        return;
      }

      final oldData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final oldOrg = oldData.data()?['trainingOrganization'] ?? "";
      final oldGroupChatId = "group_${oldOrg.replaceAll(' ', '_')}";

      if (widget.allowLocationEdit && orgName.isNotEmpty && cityName.isNotEmpty) {
        final query = "$orgName, $cityName";
        final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1",
        );

        final response = await http.get(url, headers: {
          'User-Agent': 'SmartTrackApp/1.0 (your_email@example.com)',
        });

        final results = json.decode(response.body);
        if (results.isNotEmpty) {
          latitude = double.tryParse(results[0]['lat']);
          longitude = double.tryParse(results[0]['lon']);
        }
      }

      if ((latitude == null || longitude == null) && _manualLocation != null) {
        latitude = _manualLocation!.latitude;
        longitude = _manualLocation!.longitude;
      }

      if (widget.allowLocationEdit && (latitude == null || longitude == null)) {
        _showMessage("\u274c لم يتم العثور على الموقع. استخدم الخريطة لتحديده يدويًا.");
        setState(() => _isLoading = false);
        return;
      }

      final updates = <String, dynamic>{};

      if (widget.allowNameEdit) {
        updates['trainingOrganization'] = orgName;
        updates['trainingCity'] = cityName;
      }

      if (widget.allowLocationEdit && latitude != null && longitude != null) {
        updates['trainingLocation'] = {'lat': latitude, 'lon': longitude};
      }

      if (oldOrg.isNotEmpty && oldOrg != orgName) {
        await FirebaseFirestore.instance.collection('chats').doc(oldGroupChatId).update({
          'participants': FieldValue.arrayRemove([user.uid])
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

      final newGroupChatId = "group_${orgName.replaceAll(' ', '_')}";
      await FirebaseFirestore.instance.collection('chats').doc(newGroupChatId).set({
        'chatId': newGroupChatId,
        'chatType': 'group',
        'chatName': "قروب $orgName",
        'participants': FieldValue.arrayUnion([user.uid, "AuUE3E5QZShyRGZTmmJdpVTtRBu1"]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context, true); // ✅ هذا أهم شيء يرجع true
      }
    } catch (e) {
      _showMessage("\u274c خطأ أثناء الحفظ:\n$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openManualLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualLocationPickerScreen(
          onLocationSelected: (lat, lon) {
            Navigator.pop(context, LatLng(lat, lon));
          },
        ),
      ),
    );

    if (result is LatLng && mounted) {
      setState(() {
        _manualLocation = result;
      });
      _showMessage("\u2705 تم تحديد الموقع يدويًا");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إكمال جهة التدريب")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.allowNameEdit) ...[
              Text("أدخل اسم جهة التدريب مع المدينة:", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 15),
              TextField(
                controller: _orgController,
                decoration: InputDecoration(
                  hintText: "مثال: الكلية التقنية",
                  border: OutlineInputBorder(),
                  labelText: "جهة التدريب",
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: "مثال: جدة",
                  border: OutlineInputBorder(),
                  labelText: "المدينة",
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (widget.allowLocationEdit)
              ElevatedButton.icon(
                onPressed: _openManualLocationPicker,
                icon: Icon(Icons.map),
                label: Text("تحديد الموقع يدويًا على الخريطة"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              ),

            const SizedBox(height: 10),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitTrainingInfo,
                    child: Text("حفظ"),
                  ),
          ],
        ),
      ),
    );
  }
}
