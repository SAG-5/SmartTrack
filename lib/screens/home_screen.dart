import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_screen.dart';
import 'attendance_log_screen.dart';
import 'tasks_screen.dart';
import 'chat_selection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _ensureGroupChatExists();

    _pages = [
      AttendanceScreen(),
      AttendanceLogScreen(),
      TasksScreen(),
      ChatSelectionScreen(),
      SettingsScreen(toggleTheme: widget.toggleTheme),
    ];
  }

  Future<void> _ensureGroupChatExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null || userData["trainingOrganization"] == null) return;

    final trainingOrg = userData["trainingOrganization"];
    final groupChatId = 'group_${trainingOrg.replaceAll(" ", "_")}';

    final groupDoc = await FirebaseFirestore.instance.collection("chats").doc(groupChatId).get();

    if (!groupDoc.exists) {
      await FirebaseFirestore.instance.collection("chats").doc(groupChatId).set({
        "chatId": groupChatId,
        "chatType": "group",
        "groupName": trainingOrg,
        "participants": [user.uid],
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      final participants = List<String>.from(groupDoc.data()?['participants'] ?? []);
      if (!participants.contains(user.uid)) {
        participants.add(user.uid);
        await FirebaseFirestore.instance.collection("chats").doc(groupChatId).update({
          "participants": participants,
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFF0D47A1),
        selectedFontSize: 14,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: "الحضور"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "سجل الحضور"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "المهام"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "الرسائل"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "الإعدادات"),
        ],
      ),
    );
  }
}
