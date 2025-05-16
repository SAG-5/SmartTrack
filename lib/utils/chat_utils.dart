String generateChatId(String uid1, String uid2) {
  List<String> ids = [uid1.trim(), uid2.trim()];
  ids.sort(); // ترتيب أبجدي لضمان نفس chatId دائمًا
  return ids.join("_");
}
