import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  final String chatId;
  final String chatType;
  final String chatName;

  const MessagesScreen({
    Key? key,
    required this.chatId,
    required this.chatType,
    required this.chatName,
  }) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with RouteAware {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  String? finalChatId;
  String? senderName;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      finalChatId = widget.chatId.trim();
      _loadUserName();
      markMessagesAsRead();
    }
  }

  void _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        senderName = doc.data()?['fullName'] ?? "المستخدم";
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      markMessagesAsRead();
      return true;
    });
  }

  void markMessagesAsRead() async {
    final user = _auth.currentUser;
    if (user == null || finalChatId == null || widget.chatType == "group") return;

    final snapshot = await _firestore
        .collection("chats")
        .doc(finalChatId)
        .collection("messages")
        .where("receiverId", isEqualTo: user.uid)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      doc.reference.update({"isRead": true});
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || finalChatId == null || senderName == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final chatDoc = _firestore.collection("chats").doc(finalChatId);

    await chatDoc.set({
      "chatId": finalChatId,
      "chatName": widget.chatName,
      "chatType": widget.chatType,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final messageData = {
      "senderId": user.uid,
      "senderName": senderName,
      "message": text,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "type": "text",
    };

    if (widget.chatType == "supervisor") {
      messageData["receiverId"] = getReceiverId(user.uid);
      messageData["isRead"] = false;
    }

    await chatDoc.collection("messages").add(messageData);
    _messageController.clear();
  }

  String getReceiverId(String senderId) {
    final ids = finalChatId!.split("_");
    if (ids.length != 2) return "";
    return ids[0] == senderId ? ids[1] : ids[0];
  }

  @override
  Widget build(BuildContext context) {
    if (finalChatId == null) {
      return Scaffold(
        body: Center(child: Text("🚫 لم يتم تحميل المحادثة")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 15, 66, 176),
        title: Text(widget.chatName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("chats")
                  .doc(finalChatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser!.uid;
                    final time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final timeFormatted = DateFormat('hh:mm a', 'ar').format(time);

                    final text = data['message'] ?? data['text'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(data['senderName'] ?? '',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            Text(text, style: const TextStyle(fontSize: 16)),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                timeFormatted,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "✍️ اكتب رسالتك...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF25D366),
                  child: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
