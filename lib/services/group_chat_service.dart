import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGroupIfNotExists({
    required String organizationName,
    required String currentUserId,
  }) async {
    final sanitizedGroupId = _sanitizeGroupId(organizationName);
    final groupDoc = _firestore.collection("chats").doc(sanitizedGroupId);

    final groupExists = (await groupDoc.get()).exists;

    if (!groupExists) {
      await groupDoc.set({
        "chatId": sanitizedGroupId,
        "chatName": "قروب $organizationName",
        "chatType": "group",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    final membersSnapshot = await _firestore
        .collection("users")
        .where("trainingOrganization", isEqualTo: organizationName)
        .get();

    for (var doc in membersSnapshot.docs) {
      final uid = doc.id;
      await groupDoc.collection("members").doc(uid).set({
        "userId": uid,
        "joinedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> syncUserToGroup({
    required String organizationName,
    required String userId,
  }) async {
    final sanitizedGroupId = _sanitizeGroupId(organizationName);
    final groupDoc = _firestore.collection("chats").doc(sanitizedGroupId);

    await groupDoc.collection("members").doc(userId).set({
      "userId": userId,
      "joinedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _sanitizeGroupId(String orgName) {
    return "group_${orgName.replaceAll(" ", "_")}";
  }
}
