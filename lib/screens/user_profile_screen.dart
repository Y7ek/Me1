import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff05060a),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snap.data?.data() ?? <String, dynamic>{};

              String _getString(String key) {
                final v = data[key];
                return v is String ? v : '';
              }

              final displayName = _getString('displayName');
              final username = _getString('username');
              final bio = _getString('bio');
              final phone = _getString('phoneNumber');
              final photoUrl = _getString('photoUrl');

              String lastSeenText = '';
              final lastSeen = data['lastSeen'];
              if (lastSeen is Timestamp) {
                final dt = lastSeen.toDate();
                lastSeenText =
                    'آخر ظهور ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              final isMe =
                  FirebaseAuth.instance.currentUser?.uid == userId;

              return Column(
                children: [
                  // شريط رجوع بسيط
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMe ? 'الملف الشخصي' : 'الملف الشخصي',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الهيدر الكبير (الصورة + الاسم + آخر ظهور)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: const Color(0xff202229),
                                    child: Center(
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'M',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName.isEmpty ? 'بدون اسم' : displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastSeenText.isEmpty
                              ? (isMe ? '' : 'متصل/غير متصل')
                              : lastSeenText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // أزرار (مكالمة - كتم - بحث - المزيد)
                        Row(
                          children: [
                            _ProfileActionButton(
                              icon: Icons.call_rounded,
                              label: 'مكالمة',
                              onTap: () {
                                // هنا لاحقاً نضيف مكالمة حقيقية أو رابط
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ميزة المكالمة قيد التطوير'),
                                  ),
                                );
                              },
                            ),
                            _ProfileActionButton(
                              icon: Icons.notifications_off_rounded,
                              label: 'كتم',
                              onTap: () {
                                // كتم المحادثة (لاحقاً نربطها بـ Firestore)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('سيتم إضافة كتم الدردشة لاحقاً'),
                                  ),
                                );
                              },
                            ),
                            _ProfileActionButton(
                              icon: Icons.search_rounded,
                              label: 'بحث',
                              onTap: () {
                                // فتح بحث في الدردشة
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('بحث داخل المحادثة قريباً 👀'),
                                  ),
                                );
                              },
                            ),
                            _ProfileActionButton(
                              icon: Icons.more_horiz_rounded,
                              label: 'المزيد',
                              onTap: () {
                                _showMoreSheet(context, isMe);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // بقية المعلومات في ListView
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff05060a),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          const SizedBox(height: 8),
                          _ProfileInfoTile(
                            title: 'الجوال',
                            value: phone.isEmpty ? 'غير مضاف' : phone,
                            icon: Icons.phone_iphone_rounded,
                          ),
                          _ProfileInfoTile(
                            title: 'اسم المستخدم',
                            value: username.isEmpty
                                ? 'غير مضاف'
                                : '@$username',
                            icon: Icons.alternate_email_rounded,
                          ),
                          _ProfileInfoTile(
                            title: 'النبذة',
                            value:
                                bio.isEmpty ? 'لا توجد نبذة بعد.' : bio,
                            icon: Icons.info_outline_rounded,
                          ),
                          const SizedBox(height: 24),

                          if (!isMe)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xff0e66ff),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                // إضافة لجهات الاتصال (لاحقاً نربطها بجهات الاتصال)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'إضافة لجهات الاتصال قيد التطوير'),
                                  ),
                                );
                              },
                              child: const Text(
                                'إضافة لجهات الاتصال',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isMe) const SizedBox(height: 8),
                          if (!isMe)
                            TextButton(
                              onPressed: () {
                                // حظر المستخدم (لاحقاً نربطها بقاعدة البيانات)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('حظر المستخدم قيد الإضافة'),
                                  ),
                                );
                              },
                              child: const Text(
                                'حظر المستخدم',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isMe) const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff101218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded,
                      color: Colors.white),
                  title: Text(
                    isMe ? 'تغيير صورة الملف الشخصي' : 'عرض صورة الملف الشخصي',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // لاحقاً: فتح شاشة التحرير / العرض
                  },
                ),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.edit_rounded,
                        color: Colors.white),
                    title: const Text(
                      'تعديل الاسم والنبذة',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // لاحقاً: نفتح شاشة تعديل البروفايل
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xff11131a),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff101218),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}