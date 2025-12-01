// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String? displayName;  // الاسم اللي يظهر في الشات
  final String? username;     // اسم المستخدم (يقبل حتى لو حرف واحد)
  final String? photoUrl;     // صورة البروفايل
  final String? bio;          // النبذة
  final String? phoneNumber;
  final String? email;
  final Timestamp? lastSeen;
  final bool isOnline;

  AppUser({
    required this.id,
    this.displayName,
    this.username,
    this.photoUrl,
    this.bio,
    this.phoneNumber,
    this.email,
    this.lastSeen,
    this.isOnline = false,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      displayName: data['displayName'] as String?,
      username: data['username'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      lastSeen: data['lastSeen'] as Timestamp?,
      isOnline: (data['isOnline'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'email': email,
      'lastSeen': lastSeen ?? FieldValue.serverTimestamp(),
      'isOnline': isOnline,
    };
  }
}