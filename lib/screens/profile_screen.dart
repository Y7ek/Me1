// lib/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(uid).withConverter(
              fromFirestore: (snap, _) => AppUser.fromDoc(snap),
              toFirestore: (AppUser user, _) => user.toMap(),
            );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
        ),
        body: StreamBuilder<DocumentSnapshot<AppUser>>(
          stream: userDoc.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snap.hasData || !snap.data!.exists) {
              return const Center(
                child: Text('لم يتم إعداد الملف الشخصي بعد.'),
              );
            }

            final user = snap.data!.data()!;
            final displayName = user.displayName ?? 'مستخدم';
            final username = user.username ?? '';
            final bio = user.bio ?? '';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // لاحقاً: تغيير صورة البروفايل
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تغيير صورة البروفايل سيتم دعمه لاحقاً.'),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: (user.photoUrl != null &&
                                  (user.photoUrl ?? '').isNotEmpty)
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: (user.photoUrl == null ||
                                  (user.photoUrl ?? '').isEmpty)
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // نبذة
                if (bio.isNotEmpty) ...[
                  const Text(
                    'النبذة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // قسم القصص (قائمة قصصي)
                const Text(
                  'قصصي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xfff2f4f9),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'لاحقاً سيتم عرض كل القصص التي نشرتها هنا مع الأرشيف.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('نظام القصص سنفعّله في خطوة لاحقة.'),
                            ),
                          );
                        },
                        child: const Text('إدارة'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // زر تعديل الملف الشخصي
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileSheet(context, user),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل الملف الشخصي'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppUser user) {
    final nameController =
        TextEditingController(text: user.displayName ?? '');
    final usernameController =
        TextEditingController(text: user.username ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل الملف الشخصي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    hintText: 'يمكن أن يكون حتى لو حرف واحد',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'النبذة',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final uid =
                          FirebaseAuth.instance.currentUser!.uid;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                        'displayName': nameController.text.trim(),
                        'username': usernameController.text.trim(),
                        'bio': bioController.text.trim(),
                      });

                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}