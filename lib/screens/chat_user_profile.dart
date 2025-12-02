// lib/screens/chat_user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatUserProfileScreen extends StatelessWidget {
  final String chatId;
  final String chatTitle;

  const ChatUserProfileScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            chatTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
        body: currentUid == null
            ? const Center(
                child: Text(
                  'لم يتم تسجيل الدخول.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .get(),
                builder: (context, chatSnap) {
                  if (chatSnap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (!chatSnap.hasData || !chatSnap.data!.exists) {
                    return const Center(
                      child: Text(
                        'لم يتم العثور على المحادثة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final chatData = chatSnap.data!.data() ?? {};
                  final participants =
                      List<String>.from(chatData['participants'] ?? const []);
                  String? peerUid;
                  for (final p in participants) {
                    if (p != currentUid) {
                      peerUid = p;
                      break;
                    }
                  }
                  if (peerUid == null) {
                    return const Center(
                      child: Text(
                        'لا يمكن تحديد الطرف الآخر في المحادثة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(peerUid)
                        .get(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (!userSnap.hasData || !userSnap.data!.exists) {
                        return const Center(
                          child: Text(
                            'لم يتم العثور على ملف المستخدم.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final data = userSnap.data!.data() ?? {};
                      final username = (data['username'] ?? '') as String;
                      final displayName =
                          (data['displayName'] ?? '') as String;
                      final bio = (data['bio'] ?? '') as String;
                      final photoUrl = data['photoUrl'] as String?;
                      final phone = (data['phone'] ?? '') as String;

                      final shownName = username.isNotEmpty
                          ? '@$username'
                          : (displayName.isNotEmpty
                              ? displayName
                              : 'مستخدم بدون اسم');

                      final shownBio =
                          bio.isNotEmpty ? bio : 'لا توجد نبذة بعد.';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // الصورة
                            CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  Colors.white.withOpacity(0.12),
                              backgroundImage: photoUrl != null &&
                                      photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? Text(
                                      (displayName.isNotEmpty
                                              ? displayName[0]
                                              : 'م')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // الاسم / اليوزر
                            Text(
                              shownName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // النبذة تحت الاسم (مثل تيليجرام)
                            Text(
                              shownBio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // معلومات إضافية بسيطة
                            if (phone.isNotEmpty)
                              _infoRow(
                                icon: CupertinoIcons.phone_fill,
                                label: 'رقم الهاتف',
                                value: phone,
                              ),

                            const SizedBox(height: 16),

                            // أزرار سريعة (لاحقاً يمكن ربطها بميزات)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _actionChip(
                                  icon: CupertinoIcons.chat_bubble_fill,
                                  label: 'بدء محادثة',
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(width: 12),
                                _actionChip(
                                  icon: CupertinoIcons.bell_fill,
                                  label: 'إشعارات',
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'إدارة الإشعارات سيتم دعمها لاحقاً.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.7,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.16),
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
