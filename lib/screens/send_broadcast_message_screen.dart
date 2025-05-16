import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendBroadcastMessageScreen extends StatefulWidget {
  final String supervisorId;

  const SendBroadcastMessageScreen({Key? key, required this.supervisorId}) : super(key: key);

  @override
  _SendBroadcastMessageScreenState createState() => _SendBroadcastMessageScreenState();
}

class _SendBroadcastMessageScreenState extends State<SendBroadcastMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String _selectedGroup = 'الكل';
  List<String> _groups = ['الكل'];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'trainee')
        .get();

    final Set<String> groupSet = {'الكل'};
    for (var doc in snapshot.docs) {
      final group = doc.data()['trainingOrganization'];
      if (group != null && group.toString().trim().isNotEmpty) {
        groupSet.add(group.toString().trim());
      }
    }

    final sortedGroups = groupSet.toList()..sort();

    setState(() {
      _groups = sortedGroups;
    });
  }

  Future<void> _sendBroadcastMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ الرجاء كتابة نص الرسالة")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      var query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainee');

      if (_selectedGroup != 'الكل') {
        query = query.where('trainingOrganization', isEqualTo: _selectedGroup);
      }

      final traineesSnapshot = await query.get();

      for (var doc in traineesSnapshot.docs) {
        final traineeId = doc.id;
        final chatId = _generateChatId(widget.supervisorId, traineeId);

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': widget.supervisorId,
          'receiverId': traineeId,
          'text': messageText,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'text',
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set({
          'lastMessage': messageText,
          'lastTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إرسال الرسالة بنجاح")),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الإرسال: $e")),
      );
    }

    setState(() => _isSending = false);
  }

  String _generateChatId(String id1, String id2) {
    return (id1.compareTo(id2) < 0) ? '$id1\_$id2' : '$id2\_$id1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("رسالة جماعية")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedGroup,
              items: _groups.map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGroup = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: "اختر الجهة",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "اكتب رسالتك هنا...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isSending
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _sendBroadcastMessage,
                    icon: const Icon(Icons.send),
                    label: const Text("إرسال"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
