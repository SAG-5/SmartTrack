import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttrack/screens/admin_account_screen.dart';
import 'package:smarttrack/screens/trainee_statistics_screen.dart';
import 'package:smarttrack/screens/manage_trainees_screen.dart';
import 'package:smarttrack/screens/notification_settings_screen.dart';
import 'package:smarttrack/screens/weekly_attendance_report.dart';
import 'package:smarttrack/screens/login_screen.dart';
import 'package:smarttrack/screens/trainee_training_permissions_screen.dart';
import 'package:smarttrack/utils/face_management_utils.dart';

class AdminSettingsScreen extends StatelessWidget {
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _deleteAllFaces(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تحذير"),
        content: Text("هل أنت متأكد أنك تريد حذف جميع الوجوه من النظام؟"),
        actions: [
          TextButton(child: Text("إلغاء"), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: Text("نعم"), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      await deleteAllFacesFromFaceSet();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم حذف جميع الوجوه من FaceSet")),
      );
    }
  }

  Future<void> _deleteTraineeAccount(BuildContext context, String traineeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تحذير"),
        content: Text("هل أنت متأكد أنك تريد حذف حساب المتدرب؟"),
        actions: [
          TextButton(child: Text("إلغاء"), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: Text("نعم"), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(traineeId).delete();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid == traineeId) {
          await user.delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ تم حذف حساب المتدرب")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ خطأ أثناء حذف الحساب: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _showTraineeListDialog(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'trainee')
        .get();

    final List<Map<String, dynamic>> trainees = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['fullName'],
      };
    }).toList();

    final selectedTraineeId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("اختر المتدرب لحذفه"),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: trainees.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                title: Text(trainees[index]['name']),
                onTap: () => Navigator.of(ctx).pop(trainees[index]['id']),
              );
            },
          ),
        ),
        actions: [
          TextButton(child: Text("إلغاء"), onPressed: () => Navigator.of(ctx).pop(null)),
        ],
      ),
    );

    if (selectedTraineeId != null) {
      _deleteTraineeAccount(context, selectedTraineeId);
    }
  }

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تأكيد تسجيل الخروج"),
        content: Text("هل أنت متأكد أنك تريد تسجيل الخروج؟"),
        actions: [
          TextButton(child: Text("إلغاء"), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: Text("نعم"), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: () {})),
        (route) => false,
      );
    }
  }

  Widget _buildSettingCard({required Icon icon, required String title, String? subtitle, required VoidCallback onTap, Color? iconColor}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: icon,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إعدادات المشرف"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            icon: Icon(Icons.person, color: Colors.indigo),
            title: "إدارة الحساب",
            onTap: () => _navigateTo(context, AdminAccountScreen()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.bar_chart, color: Colors.indigo),
            title: "إحصائيات المتدربين",
            onTap: () => _navigateTo(context, TraineeStatisticsScreen()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.supervised_user_circle, color: Colors.indigo),
            title: "إدارة المتدربين",
            onTap: () => _navigateTo(context, ManageTraineesScreen()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.school, color: Colors.indigo),
            title: "جهات تدريب المتدربين",
            onTap: () => _navigateTo(context, TraineeTrainingPermissionsScreen()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.notifications, color: Colors.indigo),
            title: "إعدادات الإشعارات",
            onTap: () => _navigateTo(context, NotificationSettingsScreen()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.calendar_month, color: Colors.indigo),
            title: "تقرير الحضور",
            subtitle: "عرض + شهري و أسبوعي + طباعة + حفظ + مشاركة",
            onTap: () => _navigateTo(context, WeeklyAttendanceReport()),
          ),
          _buildSettingCard(
            icon: Icon(Icons.logout, color: Colors.red),
            title: "تسجيل الخروج",
            onTap: () => _logout(context),
          ),
        _buildSettingCard(
            icon: Icon(Icons.face_retouching_off_rounded, color: Colors.red),
            title: "حذف جميع الوجوه من النظام",
            onTap: () => _deleteAllFaces(context),
          ),
          _buildSettingCard(
            icon: Icon(Icons.delete, color: Colors.red),
            title: "حذف حساب المتدرب",
            onTap: () => _showTraineeListDialog(context),
          ),
        ],
      ),
    );
  }
}