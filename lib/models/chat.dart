// lib/models/chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final bool isArchived;
  final DateTime? updatedAt;

  /// آخر رسالة محفوظة داخل حقل lastMessage في وثيقة الشات
  final LastMessage? lastMessage;

  /// عنوان الشات (للمجموعات مثلاً) – ممكن يكون فارغ في الخاص
  final String title;

  Chat({
    required this.id,
    required this.participants,
    required this.isArchived,
    required this.updatedAt,
    required this.lastMessage,
    required this.title,
  });

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // participants
    final parts = List<String>.from(data['participants'] ?? const []);

    // updatedAt
    final tsUpdated = data['updatedAt'] as Timestamp?;
    final updatedAt = tsUpdated?.toDate();

    // lastMessage
    LastMessage? last;
    final lm = data['lastMessage'];
    if (lm is Map) {
      final ts = lm['createdAt'];
      DateTime? created;
      if (ts is Timestamp) {
        created = ts.toDate();
      }
      last = LastMessage(
        id: (lm['id'] ?? '') as String,
        senderId: (lm['senderId'] ?? '') as String,
        text: (lm['text'] ?? '') as String,
        type: (lm['type'] ?? 'text') as String,
        createdAt: created,
      );
    }

    return Chat(
      id: doc.id,
      participants: parts,
      isArchived: (data['isArchived'] as bool?) ?? false,
      updatedAt: updatedAt,
      lastMessage: last,
      // لو ما عندك حقل title في فايرستور، خليها فاضية
      title: (data['title'] as String?) ?? '',
    );
  }
}

class LastMessage {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final DateTime? createdAt;

  LastMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
  });
}