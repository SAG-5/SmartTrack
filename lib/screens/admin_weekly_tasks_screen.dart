import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminWeeklyTasksScreen extends StatefulWidget {
  final String academicNumber;
  const AdminWeeklyTasksScreen({super.key, required this.academicNumber});

  @override
  State<AdminWeeklyTasksScreen> createState() => _AdminWeeklyTasksScreenState();
}

class _AdminWeeklyTasksScreenState extends State<AdminWeeklyTasksScreen> {
  bool showAllTasks = false;

  Stream<QuerySnapshot> getSubmittedTasks() {
    return FirebaseFirestore.instance
        .collection('weekly_tasks')
        .where('submitted', isEqualTo: true)
        .where('academicNumber', isEqualTo: widget.academicNumber)
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📋 المهام الأسبوعية المرسلة"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getSubmittedTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل البيانات"));
          }

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return const Center(child: Text("لا توجد مهام مرسلة حالياً"));
          }

          final latestTask = tasks.first;
          final previousTasks = tasks.length > 1 ? tasks.sublist(1) : [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EvaluationCard(
                data: latestTask.data() as Map<String, dynamic>,
                taskId: latestTask.id,
                isLatest: true,
                onEvaluated: () => setState(() => showAllTasks = true),
              ),
              const SizedBox(height: 20),
              if (!showAllTasks && previousTasks.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => showAllTasks = true),
                    icon: const Icon(Icons.history),
                    label: const Text("عرض جميع المهام السابقة"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  ),
                ),
              if (showAllTasks && previousTasks.isNotEmpty) ...[
                const Text("📁 جميع المهام السابقة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...previousTasks.map((doc) => EvaluationCard(
                      data: doc.data() as Map<String, dynamic>,
                      taskId: doc.id,
                    ))
              ]
            ],
          );
        },
      ),
    );
  }
}

class EvaluationCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String taskId;
  final bool isLatest;
  final VoidCallback? onEvaluated;

  const EvaluationCard({
    super.key,
    required this.data,
    required this.taskId,
    this.isLatest = false,
    this.onEvaluated,
  });

  @override
  State<EvaluationCard> createState() => _EvaluationCardState();
}

class _EvaluationCardState extends State<EvaluationCard> {
  late int selectedEvaluation;
  late TextEditingController noteController;
  bool viewed = false;

  @override
  void initState() {
    super.initState();
    selectedEvaluation = widget.data['evaluation'] is int ? widget.data['evaluation'] : 0;
    noteController = TextEditingController(text: widget.data['note']?.toString() ?? '');
    viewed = widget.data['viewed'] == true;

    if (!viewed) {
      FirebaseFirestore.instance.collection("weekly_tasks").doc(widget.taskId).update({"viewed": true});
      viewed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final title = data['title'] ?? 'عنوان غير متوفر';
    final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: !viewed ? Colors.red[50] : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📌 $title", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var sub in submissions) ...[
              if (sub['submittedAt'] != null)
                Text("📅 الإرسال: ${DateFormat('yyyy-MM-dd – hh:mm a').format((sub['submittedAt'] as Timestamp).toDate())}"),
              if (sub['text'] != null) ...[
                const SizedBox(height: 6),
                const Text("📄 الشرح:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(sub['text'], style: const TextStyle(fontSize: 17)),
              ],
              const Divider()
            ],
            const SizedBox(height: 10),
            const Text("📊 اختر التقييم من 1 إلى 5:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Wrap(
              spacing: 10,
              children: List.generate(5, (i) {
                final val = i + 1;
                return ChoiceChip(
                  label: Text('$val'),
                  selected: selectedEvaluation == val,
                  onSelected: (_) => setState(() => selectedEvaluation = val),
                  selectedColor: Colors.indigo,
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "ملاحظة المشرف"),
              style: const TextStyle(fontSize: 12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitEvaluation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text("إرسال التقييم", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _submitEvaluation() async {
    if (selectedEvaluation == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ الرجاء اختيار تقييم أولاً")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('هل أنت متأكد؟'),
        content: const Text('سيتم إرسال التقييم الآن.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("لا")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("نعم")),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection("weekly_tasks").doc(widget.taskId).update({
        "evaluation": selectedEvaluation,
        "note": noteController.text.trim(),
        "viewed": true
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إرسال التقييم بنجاح.")),
      );

      if (widget.onEvaluated != null) widget.onEvaluated!();
    }
  }
}
