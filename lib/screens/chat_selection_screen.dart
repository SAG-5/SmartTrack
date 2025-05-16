import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messages_screen.dart';

class ChatSelectionScreen extends StatelessWidget {
  const ChatSelectionScreen({Key? key}) : super(key: key);

  String generateChatId(String uid1, String uid2) {
    List<String> ids = [uid1.trim(), uid2.trim()];
    ids.sort();
    return ids.join("_");
  }

  Future<int> getUnreadCount(String chatId, String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("receiverId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<String> getSupervisorName() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc("AuUE3E5QZShyRGZTmmJdpVTtRBu1")
        .get();
    return doc.data()?['fullName'] ?? "المشرف";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("🚫 يجب تسجيل الدخول أولًا")),
      );
    }

    const supervisorUid = "AuUE3E5QZShyRGZTmmJdpVTtRBu1";
    final chatId = generateChatId(user.uid, supervisorUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("اختر المحادثة", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 17, 112, 196),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("chats")
                .where("chatType", isEqualTo: "group")
                .where("participants", arrayContains: user.uid)
                .snapshots(),
            builder: (context, groupSnapshot) {
              if (!groupSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final groupChats = groupSnapshot.data!.docs;

              return ListView(
                padding: EdgeInsets.all(12),
                children: [
                  FutureBuilder<int>(
                    future: getUnreadCount(chatId, user.uid),
                    builder: (context, countSnapshot) {
                      final unread = countSnapshot.data ?? 0;
                      return FutureBuilder<String>(
                        future: getSupervisorName(),
                        builder: (context, nameSnapshot) {
                          final supervisorName = nameSnapshot.data ?? "المشرف";
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: Text(supervisorName, style: TextStyle(fontWeight: FontWeight.bold)),
                              trailing: unread > 0
                                  ? CircleAvatar(
                                      backgroundColor: Colors.red,
                                      radius: 12,
                                      child: Text(
                                        unread.toString(),
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MessagesScreen(
                                      chatId: chatId,
                                      chatType: "supervisor",
                                      chatName: supervisorName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (groupChats.isNotEmpty)
                    ...groupChats.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final chatId = doc.id;

                      String groupName;
                      if (data["chatName"] != null && data["chatName"].toString().trim().isNotEmpty) {
                        groupName = data["chatName"];
                      } else if (chatId.startsWith("group_")) {
                        final orgName = chatId.replaceFirst("group_", "").replaceAll("_", " ");
                        groupName = "قروب $orgName";
                      } else {
                        groupName = "قروب جهة التدريب";
                      }

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.group, color: Colors.green),
                          title: Text(groupName, style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessagesScreen(
                                  chatId: chatId,
                                  chatType: "group",
                                  chatName: groupName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList()
                  else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text("لا يوجد قروبات متاحة حالياً")),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
