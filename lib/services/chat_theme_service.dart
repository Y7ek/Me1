import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_theme.dart';

class ChatThemeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// نخزن الثيم لكل محادثة ولكل مستخدم:
  /// chats/{chatId}/themes/{uid}
  static Stream<ChatTheme> themeStream({
    required String chatId,
    required String uid,
  }) {
    final docRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('themes')
        .doc(uid);

    return docRef.snapshots().map((snap) {
      if (!snap.exists) {
        return ChatTheme.defaultTheme();
      }
      return ChatTheme.fromDoc(snap);
    });
  }

  static Future<void> saveTheme({
    required String chatId,
    required String uid,
    required ChatTheme theme,
  }) async {
    final docRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('themes')
        .doc(uid);

    await docRef.set(theme.toMap(), SetOptions(merge: true));
  }
}