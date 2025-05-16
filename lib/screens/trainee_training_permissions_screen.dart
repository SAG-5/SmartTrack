import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manual_location_picker_screen.dart'; // تأكد من المسار الصحيح للملف

class TraineeTrainingPermissionsScreen extends StatelessWidget {
  Future<void> _setEditPermission(BuildContext context, String traineeId, {required bool forName}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(traineeId).update({
        forName ? 'canEditTrainingOrg' : 'canEditLocation': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(forName ? '✅ تم تفعيل تعديل الاسم للمتدرب' : '✅ تم تفعيل تعديل الموقع للمتدرب')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في التحديث: $e')),
      );
    }
  }

  Future<void> _editOrgNameDialog(BuildContext context, String traineeId, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل اسم جهة التدريب'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'أدخل اسم جديد'),
        ),
        actions: [
          TextButton(child: Text('إلغاء'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(child: Text('حفظ'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );

    if (confirm == true && controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(traineeId).update({
        'trainingOrganization': controller.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم تحديث اسم الجهة')));
    }
  }

  Future<void> _editLocation(BuildContext context, String traineeId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualLocationPickerScreen(
          onLocationSelected: (lat, lon) async {
            await FirebaseFirestore.instance.collection('users').doc(traineeId).update({
              'trainingLocation': {'lat': lat, 'lon': lon},
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم تحديث الموقع')));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditOptions(BuildContext context, String traineeId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('السماح بتعديل اسم جهة التدريب'),
            onTap: () {
              Navigator.pop(ctx);
              _setEditPermission(context, traineeId, forName: true);
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text('السماح بتعديل موقع جهة التدريب'),
            onTap: () {
              Navigator.pop(ctx);
              _setEditPermission(context, traineeId, forName: false);
            },
          ),
          ListTile(
            leading: Icon(Icons.close),
            title: Text('إلغاء'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, String traineeId, String currentName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('تعديل اسم جهة التدريب'),
            onTap: () {
              Navigator.pop(ctx);
              _editOrgNameDialog(context, traineeId, currentName);
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text('تعديل موقع جهة التدريب'),
            onTap: () {
              Navigator.pop(ctx);
              _editLocation(context, traineeId);
            },
          ),
          ListTile(
            leading: Icon(Icons.close),
            title: Text('إلغاء'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('جهات تدريب المتدربين'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'trainee')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا يوجد متدربين'));
          }

          final trainees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trainees.length,
            itemBuilder: (context, index) {
              final trainee = trainees[index];
              final data = trainee.data() as Map<String, dynamic>;
              final fullName = data['fullName'] ?? 'بدون اسم';
              final org = data['trainingOrganization'] ?? 'غير محددة';
              final city = data['trainingCity'] ?? 'غير محددة';


              return ListTile(
                leading: Icon(Icons.person, color: Colors.indigo),
                title: Text(fullName),
                subtitle: Text('جهة التدريب: $org\nالمدينة: $city'),

                trailing: IconButton(
                  icon: Icon(Icons.lock_open, color: Colors.orange),
                  onPressed: () => _showEditOptions(context, trainee.id),
                ),
                onTap: () => _showOptions(context, trainee.id, org),
              );
            },
          );
        },
      ),
    );
  }
}
