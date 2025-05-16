import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TraineeStatisticsScreen extends StatefulWidget {
  @override
  _TraineeStatisticsScreenState createState() => _TraineeStatisticsScreenState();
}

class _TraineeStatisticsScreenState extends State<TraineeStatisticsScreen> {
  int traineeCount = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int ongoingTasks = 0;
  int expiredTasks = 0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'trainee')
        .get();

    final tasksSnapshot = await FirebaseFirestore.instance.collection('tasks').get();

    setState(() {
      traineeCount = usersSnapshot.docs.length;
      totalTasks = tasksSnapshot.docs.length;
      completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'مكتملة')
          .length;
      

      expiredTasks = tasksSnapshot.docs.where((doc) {
        final data = doc.data();
        final dueDate = (data['reopenedUntil'] ?? data['dueDate']) as Timestamp?;
        final submitted = data['submitted'] ?? false;
        if (dueDate == null) return false;
        return dueDate.toDate().isBefore(DateTime.now()) && !submitted;
      }).length;
    });
  }

  Widget buildStatCard(String label, int count, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("$count", style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إحصائيات المتدربين"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildStatCard("عدد المتدربين", traineeCount, Colors.indigo),
            buildStatCard("عدد جميع المهام", totalTasks, Colors.blue),
            buildStatCard("عدد المهام المكتملة", completedTasks, Colors.green),

          ],
        ),
      ),
    );
  }
}
