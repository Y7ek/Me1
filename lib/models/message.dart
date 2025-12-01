// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String type; // text, audio, image, deleted, story_reply...
  final String text;
  final String? storyId;
  final Timestamp createdAt;

  // حقول إضافية للميزات المتقدمة:
  final String? replyToMessageId;
  final bool isDeleted;
  final bool isStoryReply;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationMs;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.storyId,
    required this.createdAt,
    this.replyToMessageId,
    this.isDeleted = false,
    this.isStoryReply = false,
    this.imageUrl,
    this.audioUrl,
    this.audioDurationMs,
  });

  factory Message.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    bool _bool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      return defaultValue;
    }

    String? _string(dynamic v) {
      if (v is String) return v;
      return null;
    }

    int? _int(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw
        : Timestamp.now();

    return Message(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      text: data['text'] as String? ?? '',
      storyId: _string(data['storyId']),
      createdAt: createdAt,
      replyToMessageId: _string(data['replyToMessageId']),
      isDeleted: _bool(data['isDeleted'], defaultValue: false),
      isStoryReply: _bool(data['isStoryReply'], defaultValue: false),
      imageUrl: _string(data['imageUrl']),
      audioUrl: _string(data['audioUrl']),
      audioDurationMs: _int(data['audioDurationMs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'type': type,
      'text': text,
      'storyId': storyId,
      'createdAt': createdAt,
      'replyToMessageId': replyToMessageId,
      'isDeleted': isDeleted,
      'isStoryReply': isStoryReply,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'audioDurationMs': audioDurationMs,
    }..removeWhere((key, value) => value == null);
  }
}