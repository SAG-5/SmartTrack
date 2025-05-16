import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TraineeProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String academicNumber;
  final String major;
  final String trainingOrgName;
  final String trainingCity;
  final String supervisorName;

  const TraineeProfileScreen({
    Key? key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.academicNumber,
    required this.major,
    required this.trainingOrgName,
    required this.trainingCity,
    required this.supervisorName,
  }) : super(key: key);

  @override
  State<TraineeProfileScreen> createState() => _TraineeProfileScreenState();
}

class _TraineeProfileScreenState extends State<TraineeProfileScreen> {
  String updatedPhone = "";
  String? _supervisorName; // جعلها nullable للتعامل مع القيم الفارغة

  @override
  void initState() {
    super.initState();
    updatedPhone = widget.phone;
    _supervisorName = widget.supervisorName;
    
    // طباعة القيم للتحقق منها
    print('''
    === بيانات المشرف ===
    القيمة المرسلة: ${widget.supervisorName}
    القيمة المخزنة: $_supervisorName
    === نهاية التحقق ===
    ''');
  }

  Future<void> _editPhoneDialog() async {
    TextEditingController controller = TextEditingController(text: updatedPhone);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تعديل رقم الجوال"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: "أدخل رقم الجوال الجديد",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("حفظ"),
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .update({"phone": newPhone});
                setState(() {
                  updatedPhone = newPhone;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ تم تحديث رقم الجوال")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(IconData icon, String label, String value, {VoidCallback? onEdit}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isNotEmpty ? value : "غير متوفر"),
        trailing: onEdit != null 
            ? IconButton(icon: const Icon(Icons.edit), onPressed: onEdit) 
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(Icons.person, "الاسم الكامل", widget.fullName),
            _buildProfileCard(Icons.email, "البريد الإلكتروني", widget.email),
            _buildProfileCard(Icons.phone, "رقم الجوال", updatedPhone, onEdit: _editPhoneDialog),
            _buildProfileCard(Icons.badge, "الرقم التدريبي", widget.academicNumber),
            _buildProfileCard(Icons.school, "التخصص", widget.major),
            _buildProfileCard(Icons.business, "جهة التدريب", widget.trainingOrgName),
            _buildProfileCard(Icons.location_city, "مدينة التدريب", widget.trainingCity),
            _buildProfileCard(
              Icons.supervisor_account, 
              "المشرف المسؤول", 
              _supervisorName ?? "لم يتم تحديده بعد", // عرض "غير معين" إذا كانت القيمة فارغة
            ),
          ],
        ),
      ),
    );
  }
}