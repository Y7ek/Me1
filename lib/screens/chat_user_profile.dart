// lib/screens/chat_user_profile.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'add_contact_screen.dart';

class ChatUserProfileScreen extends StatelessWidget {
  final String chatId;
  final String? chatTitle;

  const ChatUserProfileScreen({
    super.key,
    required this.chatId,
    this.chatTitle,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // خلفية متدرجة بسيطة
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF050608), Color(0xFF151515)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(color: Colors.black.withOpacity(0.12)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  // نجيب وثيقة الشات أولاً عشان نطلع participants → الطرف الآخر
                  Expanded(
                    child: StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .snapshots(),
                      builder: (context, chatSnap) {
                        if (chatSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        if (!chatSnap.hasData ||
                            !chatSnap.data!.exists) {
                          return const Center(
                            child: Text(
                              'المحادثة غير موجودة.',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        final data = chatSnap.data!.data() ?? {};
                        final partsRaw =
                            data['participants'] as List<dynamic>? ??
                                const [];
                        final parts = partsRaw
                            .whereType<String>()
                            .toList();

                        // نحدد UID الطرف الآخر
                        String? peerUid;
                        if (parts.length == 1) {
                          peerUid = parts.first;
                        } else if (parts.length >= 2) {
                          peerUid = parts
                              .firstWhere(
                                (p) => p != currentUid,
                                orElse: () => parts.first,
                              );
                        }

                        if (peerUid == null || peerUid.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا يمكن تحديد المستخدم الآخر.',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        final userDoc = FirebaseFirestore.instance
                            .collection('users')
                            .doc(peerUid)
                            .withConverter<AppUser>(
                              fromFirestore: (snap, _) =>
                                  AppUser.fromDoc(snap),
                              toFirestore: (AppUser user, _) =>
                                  user.toMap(),
                            );

                        return StreamBuilder<
                            DocumentSnapshot<AppUser>>(
                          stream: userDoc.snapshots(),
                          builder: (context, userSnap) {
                            if (userSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            if (!userSnap.hasData ||
                                !userSnap.data!.exists) {
                              return const Center(
                                child: Text(
                                  'لم يتم إعداد ملف هذا المستخدم بعد.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            }

                            final user = userSnap.data!.data()!;
                            return _buildBody(context, user, peerUid);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppUser user, String peerUid) {
    final displayName = user.displayName?.trim();
    final username = user.username?.trim() ?? '';
    final bio = user.bio?.trim() ?? '';

    final initials = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : 'M';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // الصورة + الاسم + اليوزر + النبذة
          Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage: (user.photoUrl != null &&
                        (user.photoUrl ?? '').isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                backgroundColor: Colors.white.withOpacity(0.08),
                child: (user.photoUrl == null ||
                        (user.photoUrl ?? '').isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                displayName?.isNotEmpty == true
                    ? displayName!
                    : 'مستخدم',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (username.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 22),

          // أزرار (رسالة - كتم - QR)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _profileAction(
                icon: CupertinoIcons.chat_bubble_2_fill,
                label: 'رسالة',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _profileAction(
                icon: CupertinoIcons.bell_slash_fill,
                label: 'كتم الصوت',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الكتم سيتم تفعيله من إعدادات الشات لاحقاً.'),
                    ),
                  );
                },
              ),
              if (username.isNotEmpty)
                _profileAction(
                  icon: CupertinoIcons.qrcode,
                  label: 'رمز QR',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('عرض رمز QR لاسم المستخدم سنضيفه كميزة لاحقاً.'),
                      ),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // القصص - مربعات فقط بدون أسماء وتظهر فقط إذا لديه قصص
          _buildStoriesSection(peerUid),

          const SizedBox(height: 24),

          // قائمة الخيارات (إضافة إلى جهات الاتصال، حظر، بلاغ)
          _buildOptionsList(context, user, peerUid),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _profileAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.08),
              border:
                  Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(
              icon,
              color: Colors.lightBlueAccent,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection(String peerUid) {
    final storiesQuery = FirebaseFirestore.instance
        .collection('stories')
        .where('ownerId', isEqualTo: peerUid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: storiesQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          // لا يوجد قصص → لا نعرض شيء
          return const SizedBox.shrink();
        }

        final docs = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'القصص',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      // بدون إطار وبدون اسم، فقط مربع
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF6B6B),
                          Color(0xFFFFD93D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionsList(
    BuildContext context,
    AppUser user,
    String peerUid,
  ) {
    return Column(
      children: [
        _optionTile(
          icon: CupertinoIcons.person_badge_plus,
          label: 'إضافة إلى جهات الاتصال',
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => AddContactScreen(user: user),
              ),
            );
          },
        ),
        _optionTile(
          icon: CupertinoIcons.hand_raised_fill,
          label: 'حظر',
          isDestructive: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('نظام الحظر سيتم إضافته كجزء من إعدادات الخصوصية.'),
              ),
            );
          },
        ),
        _optionTile(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          label: 'تبليغ',
          isDestructive: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('نظام التبليغ سيتم ربطه بلوحة تحكم المشرف لاحقاً.'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.redAccent
            : Colors.lightBlueAccent,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}