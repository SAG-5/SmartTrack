import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool taskNotification = false;
  bool attendanceReminder = false;
  bool traineeMessageAlert = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await _firestore.collection("admins").doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        taskNotification = data["taskNotification"] ?? false;
        attendanceReminder = data["attendanceReminder"] ?? false;
        traineeMessageAlert = data["traineeMessageAlert"] ?? false;
        isLoading = false;
      });
    }
  }

  Future<void> saveSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection("admins").doc(uid).update({
      "taskNotification": taskNotification,
      "attendanceReminder": attendanceReminder,
      "traineeMessageAlert": traineeMessageAlert,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ تم حفظ الإعدادات")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("إعدادات الإشعارات")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات الإشعارات'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text("تنبيهات المهام الجديدة"),
            subtitle: Text("استقبل إشعارات عند إرسال مهمة للمتدرب"),
            value: taskNotification,
            onChanged: (val) {
              setState(() => taskNotification = val);
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text("تذكير الحضور اليومي"),
            subtitle: Text("تنبيه في حال غياب أحد المتدربين"),
            value: attendanceReminder,
            onChanged: (val) {
              setState(() => attendanceReminder = val);
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text("تنبيهات رسائل المتدربين"),
            subtitle: Text("إشعار عند وصول رسالة من متدرب"),
            value: traineeMessageAlert,
            onChanged: (val) {
              setState(() => traineeMessageAlert = val);
            },
          ),
          SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("حفظ التغييرات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: saveSettings,
            ),
          )
        ],
      ),
    );
  }
}
