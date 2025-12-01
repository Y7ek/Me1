// lib/services/chat_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat.dart';
import '../models/app_user.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  static CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _db.collection('chats');

  static CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _db.collection('stories');

  // -------------------- Users --------------------

  static Future<AppUser?> getUser(String uid) async {
    final snap = await _usersRef.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  static Future<void> upsertUser(AppUser user) async {
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// فحص هل ملف المستخدم مكتمل أم لا
  ///
  /// نستخدمه في main.dart:
  /// ChatService.isProfileCompleted(user.uid)
  static Future<bool> isProfileCompleted(String uid) async {
    final snap = await _usersRef.doc(uid).get();
    if (!snap.exists) return false;

    final data = snap.data() ?? {};

    // لو حاب تعتمد على فلاغ معيّن:
    final flag = data['profileCompleted'];
    if (flag is bool) return flag;

    // أو تعتمد على وجود الاسم أو اسم المستخدم
    final displayName = (data['displayName'] as String?) ?? '';
    final username = (data['username'] as String?) ?? '';

    return displayName.trim().isNotEmpty || username.trim().isNotEmpty;
  }

  /// رفع صورة البروفايل وإرجاع الرابط
  static Future<String?> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final storage = FirebaseStorage.instance;
    final ref =
        storage.ref().child('users').child(uid).child('profile_avatar.jpg');

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  /// تحديث بيانات المستخدم (الاسم، اليوزر، النبذة، الصورة...)
  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? username,
    String? bio,
    String? photoUrl,
    String? email,
  }) async {
    final Map<String, dynamic> data = {};

    if (displayName != null) data['displayName'] = displayName;
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (email != null) data['email'] = email;

    // نعتبر أن الملف اكتمل عندما يستدعى هذا التحديث من شاشة الإعداد الأولي
    data['profileCompleted'] = true;

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// بحث متقدم عن المستخدمين بالـ username أو الإيميل
  static Future<List<AppUser>> searchUsers({
    required String query,
    required String currentUid,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final usersRef = _usersRef;

    final List<AppUser> results = [];
    final Set<String> addedIds = {};

    // لو فيه @ نرجّح أنه إيميل
    if (q.contains('@')) {
      final emailSnap =
          await usersRef.where('email', isEqualTo: q).limit(10).get();

      for (var doc in emailSnap.docs) {
        if (doc.id == currentUid) continue;
        if (!addedIds.contains(doc.id)) {
          results.add(AppUser.fromDoc(doc));
          addedIds.add(doc.id);
        }
      }
    }

    // بحث باليوزر نيم (اسم المستخدم) - prefix search
    final usernameSnap = await usersRef
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(20)
        .get();

    for (var doc in usernameSnap.docs) {
      if (doc.id == currentUid) continue;
      if (!addedIds.contains(doc.id)) {
        results.add(AppUser.fromDoc(doc));
        addedIds.add(doc.id);
      }
    }

    return results;
  }

  // -------------------- Chats list --------------------

  /// بث قائمة الشات للمستخدم، مرتبة بآخر تحديث
  static Stream<List<Chat>> chatsStream(String uid) {
    return _chatsRef
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Chat.fromDoc(d)).toList());
  }

  // -------------------- Messages --------------------

  static CollectionReference<Map<String, dynamic>> _messagesCol(String chatId) {
    return _chatsRef.doc(chatId).collection('messages');
  }

  /// بث رسائل شات معيّن
  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
      String chatId) {
    return _messagesCol(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// إنشاء شات خاص بين مستخدمين أو إرجاع الموجود
  static Future<Chat> ensurePrivateChat({
    required String currentUid,
    required String peerUid,
  }) async {
    final q = await _chatsRef
        .where('participants', arrayContains: currentUid)
        .get();

    // نبحث عن شات فيه الاثنين نفسهم فقط
    for (final doc in q.docs) {
      final data = doc.data();
      final parts = List<String>.from(data['participants'] ?? const []);
      if (parts.length == 2 &&
          parts.contains(currentUid) &&
          parts.contains(peerUid)) {
        return Chat.fromDoc(doc);
      }
    }

    // لو ما وجدنا → ننشئ واحد جديد
    final newDoc = await _chatsRef.add({
      'participants': [currentUid, peerUid],
      'lastMessage': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'isArchived': false,
    });

    final created = await newDoc.get();
    return Chat.fromDoc(created);
  }

  /// إرسال رسالة نصية عادية
  static Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? replyToMessageId,
    Map<String, dynamic>? extra,
  }) async {
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      'senderId': senderId,
      'text': text,
      'type': 'text',
      'createdAt': now,
      'isDeleted': false,
      'replyToMessageId': replyToMessageId,
      if (extra != null) ...extra,
    };

    final msgRef = _messagesCol(chatId).doc();
    await msgRef.set(data);

    await _chatsRef.doc(chatId).update({
      'lastMessage': {
        'id': msgRef.id,
        'senderId': senderId,
        'text': text,
        'type': 'text',
        'createdAt': now,
      },
      'updatedAt': now,
    });
  }

  /// حذف رسالة (لنستخدمها في bottom sheet - delete for me/all)
  static Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    bool hardDelete = false,
  }) async {
    final doc = _messagesCol(chatId).doc(messageId);
    if (hardDelete) {
      await doc.delete();
    } else {
      await doc.update({
        'isDeleted': true,
        'text': 'تم حذف هذه الرسالة',
        'type': 'deleted',
      });
    }
  }

  // -------------------- Stories: رد على القصص --------------------

  /// إرسال رد على ستوري → يتم حفظه كرسالة نصية في الشات الخاص
  static Future<void> sendStoryReply({
    required String storyId,
    required String fromUid,
    required String toUid,
    required String text,
  }) async {
    // نضمن أن هناك شات خاص بين الطرفين
    final chat = await ensurePrivateChat(
      currentUid: fromUid,
      peerUid: toUid,
    );

    await sendTextMessage(
      chatId: chat.id,
      senderId: fromUid,
      text: text,
      extra: {
        'storyId': storyId,
        'isStoryReply': true,
      },
    );
  }
}