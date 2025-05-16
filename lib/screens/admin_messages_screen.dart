import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messages_screen.dart';
import 'send_broadcast_message_screen.dart';

class AdminMessagesScreen extends StatefulWidget {
  @override
  _AdminMessagesScreenState createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool showGroups = false;

  String generateChatId(String uid1, String uid2) {
    final ids = [uid1.trim(), uid2.trim()];
    ids.sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    final admin = _auth.currentUser;
    if (admin == null) {
      return Scaffold(body: Center(child: Text("🚫 يجب تسجيل الدخول")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(showGroups ? "قروبات التدريب" : "المتدربين"),
        backgroundColor: Color.fromARGB(255, 55, 9, 194),
        actions: [
          TextButton(
            onPressed: () => setState(() => showGroups = false),
            child: Text("المتدربين", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => setState(() => showGroups = true),
            child: Text("القروبات", style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: Icon(Icons.campaign, color: Colors.white),
            tooltip: "إرسال رسالة جماعية",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendBroadcastMessageScreen(supervisorId: admin.uid),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("users").where("role", isEqualTo: "trainee").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          final trainees = docs
              .map((d) => d.data())
              .where((data) => data != null)
              .map((data) => data as Map<String, dynamic>)
              .where((data) => data.containsKey("uid"))
              .toList();

          final Map<String, List<Map<String, dynamic>>> groups = {};
          for (var trainee in trainees) {
            final org = trainee['trainingOrganization'] ?? "غير معروفة";
            groups.putIfAbsent(org, () => []).add(trainee);
          }

          final items = <Widget>[];

          if (showGroups) {
            groups.forEach((org, members) {
              if (members.isNotEmpty) {
                final chatId = "group_${org.replaceAll(' ', '_')}";
                items.add(
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.group, size: 30, color: Colors.indigo),
                      title: Text("قروب - $org", style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagesScreen(
                              chatId: chatId,
                              chatType: "group",
                              chatName: "قروب $org",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            });
          } else {
            for (var member in trainees) {
              final traineeUid = member['uid'];
              final traineeName = member['fullName'] ?? 'بدون اسم';
              final traineeEmail = member['email'] ?? '';
              final chatId = generateChatId(admin.uid, traineeUid);

              items.add(
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection("chats")
                      .doc(chatId)
                      .collection("messages")
                      .where("receiverId", isEqualTo: admin.uid)
                      .where("isRead", isEqualTo: false)
                      .snapshots(),
                  builder: (context, unreadSnapshot) {
                    final unreadCount = unreadSnapshot.data?.docs.length ?? 0;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: Stack(
                          children: [
                            Icon(Icons.person, size: 30, color: Colors.indigo),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 10,
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(traineeName, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("📧 $traineeEmail"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MessagesScreen(
                                chatId: chatId,
                                chatType: "supervisor",
                                chatName: traineeName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }
          }

          if (items.isEmpty) {
            return Center(child: Text("لا توجد ${showGroups ? 'قروبات' : 'محادثات'} متاحة حالياً"));
          }

          return ListView(children: items);
        },
      ),
    );
  }
}
