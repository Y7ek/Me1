// lib/models/story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String? text;
  final String? imageUrl;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final List<String> viewers;

  Story({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    required this.expiresAt,
    this.ownerPhotoUrl,
    this.text,
    this.imageUrl,
    this.viewers = const [],
  });

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Story(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'مستخدم',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: data['expiresAt'] as Timestamp? ??
          Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24)),
          ),
      viewers: (data['viewers'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'viewers': viewers,
    };
  }
}