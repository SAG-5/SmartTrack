import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_log_screen_for_admin.dart';
import 'admin_weekly_tasks_screen.dart';

class ManageTraineesScreen extends StatefulWidget {
  @override
  _ManageTraineesScreenState createState() => _ManageTraineesScreenState();
}

class _ManageTraineesScreenState extends State<ManageTraineesScreen> {
  String searchQuery = "";
  String selectedOrg = 'الكل';
  List<String> allOrganizations = ['الكل'];

  @override
  void initState() {
    super.initState();
    _loadTrainingOrganizations();
  }

  Future<void> _loadTrainingOrganizations() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'trainee')
      .get();

  final Set<String> orgs = {'الكل'};
  for (var doc in snapshot.docs) {
    final org = doc.data()['trainingOrganization'];
    if (org != null && org.toString().trim().isNotEmpty) {
      orgs.add(org.toString().trim());
    }
  }

  setState(() {
    allOrganizations = orgs.toList()..sort();
    selectedOrg = allOrganizations.first;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("إدارة المتدربين"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "ابحث باسم المتدرب أو الرقم الأكاديمي...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("جهة التدريب:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedOrg,
                        items: allOrganizations.map((org) {
                          return DropdownMenuItem(value: org, child: Text(org));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedOrg = value;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'trainee')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final trainees = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['fullName'] ?? '').toString().toLowerCase();
                      final academicNumber = (data['academicNumber'] ?? '').toString();
                      final trainingOrg = (data['trainingOrganization'] ?? '').toString();

                      final matchesSearch = name.contains(searchQuery) ||
                          academicNumber.contains(searchQuery);
                      final matchesOrg = selectedOrg == 'الكل' || trainingOrg == selectedOrg;

                      return matchesSearch && matchesOrg;
                    }).toList() ?? [];

                if (trainees.isEmpty) {
                  return Center(child: Text("لا يوجد متدربين مطابقين للبحث."));
                }

                return ListView.separated(
                  itemCount: trainees.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final data = trainees[index].data() as Map<String, dynamic>;
                    final name = data['fullName'] ?? '-';
                    final academicNumber = data['academicNumber'] ?? '';
                    final trainingOrg = data['trainingOrganization'] ?? 'غير محددة';
                    final phone = data['phone'] ?? 'غير متوفر';
                    final major = data['major'] ?? 'غير محدد';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Icon(Icons.person, color: Colors.indigo),
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("الرقم الأكاديمي: $academicNumber"),
                              Text("جهة التدريب: $trainingOrg"),
                              Text("رقم الجوال: $phone"),
                              Text("التخصص: $major"),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'tasks') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminWeeklyTasksScreen(
                                      academicNumber: academicNumber),
                                ),
                              );
                            } else if (value == 'attendance') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceLogScreenForAdmin(
                                    academicNumber: academicNumber,
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'tasks', child: Text("عرض المهام")),
                            PopupMenuItem(value: 'attendance', child: Text("عرض الحضور")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
