import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'final_report_screen.dart';

class EditFinalReportInfoScreen extends StatefulWidget {
  @override
  _EditFinalReportInfoScreenState createState() => _EditFinalReportInfoScreenState();
}

class _EditFinalReportInfoScreenState extends State<EditFinalReportInfoScreen> {
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController challengesController = TextEditingController();
  bool _isLoading = false;

  String traineeName = "";
  String traineePhone = "";
  String supervisorName = "";

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          skillsController.text = data['finalSkills'] ?? '';
          challengesController.text = data['finalChallenges'] ?? '';
          traineeName = data['fullName'] ?? 'اسم المتدرب غير متوفر';
          traineePhone = data['phone'] ?? 'غير متوفر';
          supervisorName = data['supervisorName'] ?? 'اسم المشرف غير متوفر';
        });
      }
    }
  }

  void _saveAndContinue() async {
    final skills = skillsController.text.trim();
    final challenges = challengesController.text.trim();

    if (skills.isEmpty || challenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ الرجاء تعبئة المهارات والتحديات بشكل كامل")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("المستخدم غير مسجل الدخول");

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "finalSkills": skills,
        "finalChallenges": challenges,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => FinalReportScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الحفظ: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إعداد بحث التدريب")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.indigo.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.indigo),
                  title: Text("المتدرب: $traineeName"),
                  subtitle: Text("رقم الجوال: $traineePhone"),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🧠 المهارات المكتسبة خلال التدريب:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: skillsController,
                        maxLines: 5,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: "مثال: تطوير مواقع، تحسين مهارات التواصل، استخدام برامج... إلخ",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("⚠️ التحديات والصعوبات التي واجهتك:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: challengesController,
                        maxLines: 5,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: "مثال: ضعف التوجيه، قلة الأدوات، ضغط المهام، وغيرها...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveAndContinue,
                      icon: Icon(Icons.save_alt),
                      label: Text("💾 حفظ وطباعة التقرير", style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
