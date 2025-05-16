import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatWithTraineeScreen extends StatefulWidget {
  final String traineeId;
  final String traineeName;

  ChatWithTraineeScreen({required this.traineeId, required this.traineeName});

  @override
  _ChatWithTraineeScreenState createState() => _ChatWithTraineeScreenState();
}

class _ChatWithTraineeScreenState extends State<ChatWithTraineeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _adminId;
  late String _chatId;
  String _adminName = '';

  @override
  void initState() {
    super.initState();
    _adminId = _auth.currentUser!.uid;

    // توليد chatId بناءً على UID للمشرف والمتدرب
    _chatId = _adminId.hashCode <= widget.traineeId.hashCode
        ? '$_adminId-${widget.traineeId}'
        : '${widget.traineeId}-$_adminId';

    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final doc = await _firestore.collection('users').doc(_adminId).get();
    setState(() {
      _adminName = doc.data()?['fullName'] ?? 'المشرف';
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': _adminId,
      'senderName': _adminName,
      'receiverId': widget.traineeId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [_adminId],
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محادثة مع: ${widget.traineeName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == _adminId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['senderName'] ?? 'غير معروف',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              msg['message'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
