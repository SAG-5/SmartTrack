import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import 'register_face_screen.dart';
import 'complete_training_info_screen.dart';
import 'edit_final_report_info_screen.dart';
import 'account_management_utils.dart';
import 'trainee_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const SettingsScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String userName = "ايميل المتدرب";
  String userEmail = "";
  String traineePhone = "";
  String traineeAcademicNumber = "";
  String traineeMajor = "";
  bool notificationsEnabled = true;
  bool lowDataMode = false;
  String? trainingCity; // تم إضافة المتغير المطلوب هنا

  bool canEditName = false;
  bool canEditLocation = false;

  String? trainingOrgName;
  String? supervisorName;
  String? supervisorPhone;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "لا يوجد بريد";
      });

      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final canEditMap = data["canEditTrainingOrg"];
        final canEditLoc = data["canEditLocation"];

        setState(() {
          userName = data["fullName"] ?? "المتدرب";
          traineePhone = data["phone"] ?? "";
          traineeAcademicNumber = data["academicNumber"] ?? "";
          traineeMajor = data["major"] ?? "";
          trainingOrgName = data["trainingOrganization"];
          trainingCity = data["trainingCity"]; // تم تحميل المدينة من قاعدة البيانات
          
          supervisorName = data["supervisorName"];
          supervisorPhone = data["supervisorPhone"];
          
          canEditName = canEditMap == true ||
              (canEditMap is Map && canEditMap["name"] == true);
          canEditLocation = canEditLoc == true ||
              (canEditMap is Map && canEditMap["location"] == true);
        });
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool("isDarkMode") ?? false;
      notificationsEnabled = prefs.getBool("notifications") ?? true;
      lowDataMode = prefs.getBool("lowData") ?? false;
    });
  }

  void _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications", value);
    setState(() {
      notificationsEnabled = value;
    });
  }

  void _toggleLowDataMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("lowData", value);
    setState(() {
      lowDataMode = value;
    });
  }

  void _changePassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("✅ تم إرسال رابط تغيير كلمة المرور إلى بريدك الإلكتروني")),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => LoginScreen(toggleTheme: widget.toggleTheme)),
      (route) => false,
    );
  }

  void _contactSupport() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text("البريد الإلكتروني"),
                subtitle: Text("sa3edks1@gmail.com"),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'sa3edks1@gmail.com',
                    query: 'subject=دعم فني&body=مرحباً، احتاج إلى مساعدة.',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.message, color: Colors.green),
                title: Text("واتساب"),
                subtitle: Text("0502292630"),
                onTap: () async {
                  final Uri whatsappUri =
                      Uri.parse("https://wa.me/966502292630");
                  if (await canLaunchUrl(whatsappUri)) {
                    await launchUrl(whatsappUri);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تحذير"),
        content: Text("هل أنت متأكد أنك تريد حذف حسابك نهائيًا؟"),
        actions: [
          TextButton(
              child: Text("إلغاء"),
              onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
              child: Text("نعم"), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      await deleteAccount(context);
    }
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: child,
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildCard(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontSize: 12))
            : null,
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return _buildCard(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontSize: 12))
            : null,
        trailing:
            onTap != null ? Icon(Icons.arrow_forward_ios, size: 16) : null,
        enabled: enabled,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الإعدادات")),
      body: ListView(
        padding: EdgeInsets.only(top: 12, bottom: 24),
        children: [
          _buildSettingCard(
            icon: Icons.person,
            color: Colors.blue,
            title: userName,
            subtitle: "عرض الملف الشخصي",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TraineeProfileScreen(
                    fullName: userName,
                    email: userEmail,
                    phone: traineePhone,
                    academicNumber: traineeAcademicNumber,
                    major: traineeMajor,
                    trainingOrgName: trainingOrgName ?? '',
                    trainingCity: trainingCity ?? '',
                      supervisorName: supervisorName ?? 'غير محدد', // ✅ أضف هذا السطر

                  ),
                ),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.location_on,
            color: Colors.deepPurple,
            title: canEditName && canEditLocation
                ? "تعديل جهة التدريب"
                : canEditName
                    ? "تعديل اسم جهة التدريب"
                    : canEditLocation
                        ? "تعديل موقع جهة التدريب"
                        : "تعديل جهة التدريب",
            subtitle: !canEditName && !canEditLocation
                ? "🔒 لا يمكنك التعديل إلا بموافقة المشرف"
                : "✅ لديك صلاحية تعديل ${canEditName && canEditLocation ? "الاسم والموقع" : canEditName ? "الاسم فقط" : "الموقع فقط"}\nالجهة الحالية: ${trainingOrgName ?? ""}",
            onTap: () async {
              if (canEditName || canEditLocation) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteTrainingInfoScreen(
                      toggleTheme: widget.toggleTheme,
                      allowNameEdit: canEditName,
                      allowLocationEdit: canEditLocation,
                    ),
                  ),
                );
                if (result == true) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final updates = <String, dynamic>{};
                    if (canEditName) updates['canEditTrainingOrg'] = false;
                    if (canEditLocation) updates['canEditLocation'] = false;
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .update(updates);
                  }
                  _loadUserData();
                }

                setState(() {
                  canEditName = false;
                  canEditLocation = false;
                });
              }
            },
            enabled: canEditName || canEditLocation,
          ),
          _buildSettingCard(
            icon: Icons.picture_as_pdf,
            color: Colors.brown,
            title: "بحث التدريب",
            subtitle: "تقرير ختامي لجهة التدريب",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditFinalReportInfoScreen()),
              );
            },
          ),
          _buildSwitchCard(
            icon: Icons.dark_mode,
            color: Colors.black45,
            title: "الوضع الداكن",
            value: isDarkMode,
            onChanged: (value) {
              widget.toggleTheme();
              SharedPreferences.getInstance().then((prefs) {
                prefs.setBool("isDarkMode", value);
              });
              setState(() {
                isDarkMode = value;
              });
            },
          ),
          _buildSwitchCard(
            icon: Icons.notifications,
            color: Colors.green,
            title: "الإشعارات",
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          _buildSwitchCard(
            icon: Icons.data_saver_on,
            color: Colors.blueGrey,
            title: "الوضع الاقتصادي",
            subtitle: "تقليل استهلاك البيانات",
            value: lowDataMode,
            onChanged: _toggleLowDataMode,
          ),
          _buildSettingCard(
            icon: Icons.face_retouching_natural,
            color: Colors.deepOrange,
            title: "تسجيل بصمة الوجه",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        RegisterFaceScreen(toggleTheme: widget.toggleTheme)),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.lock,
            color: Colors.red,
            title: "تغيير كلمة المرور",
            onTap: _changePassword,
          ),
          _buildSettingCard(
            icon: Icons.exit_to_app,
            color: Colors.red,
            title: "تسجيل الخروج",
            onTap: _logout,
          ),
          _buildSettingCard(
            icon: Icons.delete_forever,
            color: Colors.red,
            title: "حذف الحساب نهائيًا",
            onTap: () => _deleteAccount(context),
          ),
          _buildSettingCard(
            icon: Icons.support_agent,
            color: Colors.blue,
            title: "الدعم الفني",
            subtitle: "تواصل معنا عبر البريد أو الواتساب",
            onTap: _contactSupport,
          ),
          _buildSettingCard(
            icon: Icons.info_outline,
            color: Colors.indigo,
            title: "عن التطبيق",
            subtitle: "معلومات سريعة عن SmartTrack والإصدار",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "SmartTrack",
                applicationVersion: "v1.0.0",
                applicationIcon: Icon(Icons.verified_user),
                children: [
                  Text(
                      "SmartTrack هو نظام إلكتروني ذكي صُمّم لإدارة التدريب الميداني بكفاءة، من خلال تتبع الحضور، تسليم المهام، وتوليد تقارير شاملة تدعم المشرف والمتدرب في تحقيق الأهداف التدريبية.")
                ],
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.privacy_tip,
            color: Colors.deepPurple,
            title: "سياسة الخصوصية",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("سياسة الخصوصية"),
                  content: Text(
                      "خصوصيتك أولوية. لا تتم مشاركة أي بيانات شخصية مع جهات خارجية، ويتم تخزين المعلومات بأمان داخل خوادم Firebase وفق أعلى معايير الحماية."),
                  actions: [
                    TextButton(
                        child: Text("موافق"),
                        onPressed: () => Navigator.pop(context))
                  ],
                ),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.star_rate,
            color: Colors.amber,
            title: "تقييم التطبيق",
            onTap: () {
              int selectedRating = 0;
              TextEditingController notesController = TextEditingController();

              showDialog(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: Text("تقييم التطبيق"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("كيف تقيم تجربتك؟",
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });
                              },
                              child: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "هل لديك ملاحظات؟ (اختياري)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text("إلغاء"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("✅ شكرًا! تقييمك: $selectedRating نجوم"),
                            ),
                          );
                        },
                        child: Text("إرسال"),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.share,
            color: Colors.teal,
            title: "مشاركة التطبيق",
            onTap: () async {
              final shareUri = Uri.parse("https://example.com/app-download");
              await launchUrl(shareUri);
            },
          ),
        ],
      ),
    );
  }
}