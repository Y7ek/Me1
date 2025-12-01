// lib/services/story_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';

class StoryService {
  static final CollectionReference<Map<String, dynamic>> _storiesRef =
      FirebaseFirestore.instance.collection('stories');

  /// كل القصص غير المنتهية (بعد وقت الانتهاء)
  static Stream<List<Story>> storiesStream() {
    final now = Timestamp.now();
    return _storiesRef
        .where('expiresAt', isGreaterThan: now)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Story.fromDoc(d)).toList(),
        );
  }

  /// إنشاء قصة نصّية فقط (حالياً بدون صورة/فيديو لتقليل المشاكل)
  static Future<void> createTextStory({
    required String ownerId,
    required String ownerName,
    String? ownerPhotoUrl,
    required String text,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    final expires = now.add(duration);

    await _storiesRef.add({
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'text': text,
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
      'viewers': <String>[],
    });
  }

  /// تسجيل أن المستخدم شاهد القصة
  static Future<void> markViewed({
    required String storyId,
    required String viewerId,
  }) async {
    final doc = _storiesRef.doc(storyId);
    await doc.update({
      'viewers': FieldValue.arrayUnion([viewerId]),
    });
  }
}