import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'attendance_log_screen_for_admin.dart';
import 'admin_messages_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_weekly_tasks_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<QueryDocumentSnapshot> _trainees = [];
  Map<String, int> _traineeUnreadTasks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _loading = true);
    await _fetchTrainees();
    await _fetchUnreadTasks();
    setState(() => _loading = false);
  }

  Future<void> _fetchTrainees() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "trainee")
        .get();
    _trainees = snapshot.docs;
  }

  Future<void> _fetchUnreadTasks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("weekly_tasks")
        .where("submitted", isEqualTo: true)
        .where("viewed", isEqualTo: false)
        .get();

    Map<String, int> taskCounts = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final academicNumber = data['academicNumber'];
      if (academicNumber != null) {
        taskCounts[academicNumber] = (taskCounts[academicNumber] ?? 0) + 1;
      }
    }

    _traineeUnreadTasks = taskCounts;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildAttendancePage(),
      _buildTasksPage(),
      AdminMessagesScreen(),
      AdminSettingsScreen(),
    ];

    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحضور'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'المحادثة'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _buildAttendancePage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("سجل الحضور"),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _trainees.length,
          itemBuilder: (context, index) {
            final data = _trainees[index].data() as Map<String, dynamic>;
            if (!data.containsKey("academicNumber")) return SizedBox.shrink();

            final academicNumber = data["academicNumber"] ?? '';
            final major = data["major"] ?? 'غير محدد';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.indigo),
                title: Text(data["fullName"] ?? "", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الرقم التدريبي: $academicNumber"),
                    Text("التخصص: $major"),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceLogScreenForAdmin(
                        academicNumber: academicNumber,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTasksPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("مهام المتدربين", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _trainees.length,
          itemBuilder: (context, index) {
            final data = _trainees[index].data() as Map<String, dynamic>;
            if (!data.containsKey("academicNumber")) return SizedBox.shrink();

            final academicNumber = data["academicNumber"];
            final major = data["major"] ?? 'غير محدد';
            final unreadCount = _traineeUnreadTasks[academicNumber] ?? 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(data["fullName"] ?? "", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الرقم التدريبي: $academicNumber"),
                    Text("التخصص: $major"),
                  ],
                ),
                trailing: unreadCount > 0
                    ? CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 14,
                        child: Text(
                          "$unreadCount",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminWeeklyTasksScreen(academicNumber: academicNumber),
                    ),
                  );
                  await _fetchUnreadTasks();
                  setState(() {});
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
