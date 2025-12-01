// lib/controllers/chat_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {
  final Chat chat;
  final String currentUid;

  ChatController({
    required this.chat,
    String? currentUidOverride,
  }) : currentUid =
            currentUidOverride ?? FirebaseAuth.instance.currentUser!.uid {
    _listenToMessages();
  }

  // قائمة الرسائل
  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  // حالة الإرسال
  bool _isSending = false;
  bool get isSending => _isSending;

  // الرد على رسالة
  String? _replyToMessageId;
  Message? _replyToMessage;
  Message? get replyToMessage => _replyToMessage;

  // خلفية الشات (مفتاح داخل doc الشات)
  String? _backgroundKey;
  String? get backgroundKey => _backgroundKey;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;

  void _listenToMessages() {
    // استماع للرسائل
    _messagesSub = ChatService.messagesStream(chat.id).listen((query) {
      final list = query.docs
          .map((d) => Message.fromDoc(d))
          .toList();

      _messages
        ..clear()
        ..addAll(list);

      _rebuildReplyTarget();
      notifyListeners();
    });

    // استماع لوثيقة الشات (للخلفية + أي شيء تضيفه لاحقاً)
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(chat.id)
        .snapshots()
        .listen((doc) {
      final data = doc.data() ?? {};
      final key = data['backgroundKey'];
      if (key is String) {
        _backgroundKey = key;
      } else {
        _backgroundKey = null;
      }
      notifyListeners();
    });
  }

  void _rebuildReplyTarget() {
    if (_replyToMessageId == null) {
      _replyToMessage = null;
      return;
    }
    _replyToMessage = _messages
        .where((m) => m.id == _replyToMessageId)
        .cast<Message?>()
        .firstWhere((m) => m != null, orElse: () => null);
  }

  /// بدء الرد على رسالة
  void startReply(Message msg) {
    _replyToMessageId = msg.id;
    _replyToMessage = msg;
    notifyListeners();
  }

  /// إلغاء الرد
  void clearReply() {
    _replyToMessageId = null;
    _replyToMessage = null;
    notifyListeners();
  }

  /// إرسال رسالة نصية
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      await ChatService.sendTextMessage(
        chatId: chat.id,
        senderId: currentUid,
        text: trimmed,
        replyToMessageId: _replyToMessageId,
      );

      _replyToMessageId = null;
      _replyToMessage = null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// حذف رسالة (soft delete افتراضياً)
  Future<void> deleteMessage(
    Message msg, {
    bool hardDelete = false,
  }) async {
    await ChatService.deleteMessage(
      chatId: chat.id,
      messageId: msg.id,
      hardDelete: hardDelete,
    );
  }

  /// تغيير خلفية المحادثة – يتم حفظها داخل وثيقة الشات
  Future<void> setChatBackground(String key) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chat.id)
        .update({'backgroundKey': key});
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}