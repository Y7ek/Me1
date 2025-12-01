import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _initialUsername; // علشان نعرف إذا غير اليوزر ولا لا

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = (data['displayName'] ?? '') as String;
        _usernameController.text = (data['username'] ?? '') as String;
        _bioController.text = (data['bio'] ?? '') as String;
        _initialUsername = _usernameController.text.trim();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل البيانات')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    // لو النتيجة لنفس المستخدم → مو مشكلة
    if (query.docs.first.id == uid) return false;

    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    setState(() => _isSaving = true);

    try {
      // لو غير اسم المستخدم → تأكد انه غير مستخدم
      if (username != _initialUsername && username.isNotEmpty) {
        final taken = await _isUsernameTaken(username);
        if (taken) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('اسم المستخدم مستخدم من حساب آخر'),
              ),
            );
          }
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'displayName': name,
          'username': username,
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        Navigator.pop(context); // رجوع لصفحة البروفايل
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات')),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ التعديلات')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fb),
        appBar: AppBar(
          backgroundColor: const Color(0xfff8f9fc),
          elevation: 0.6,
          centerTitle: true,
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // كرت التعديل
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('الاسم', style: titleStyle),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'اكتب اسمك',
                                filled: true,
                                fillColor: const Color(0xfff5f7fd),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'الاسم لا يمكن أن يكون فارغاً';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('اسم المستخدم', style: titleStyle),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'مثال: mem',
                                prefixText: '@',
                                filled: true,
                                fillColor: const Color(0xfff5f7fd),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'اسم المستخدم لا يمكن أن يكون فارغاً';
                                }
                                if (v.length > 32) {
                                  return 'اسم المستخدم طويل جداً';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_.]+$')
                                    .hasMatch(v)) {
                                  return 'يسمح فقط بالحروف الإنجليزية والأرقام والنقطة والشرطة السفلية';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('النبذة الشخصية', style: titleStyle),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'اكتب شيئاً عن نفسك…',
                                filled: true,
                                fillColor: const Color(0xfff5f7fd),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // كرت ملاحظات بسيطة/مستقبلية
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffecf1fb),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'لاحقاً نقدر نضيف من هنا:\n'
                          '• تغيير صورة البروفايل (ثابتة أو متحركة)\n'
                          '• إعدادات شكل صورة المحادثة لكل جهة اتصال\n'
                          '• إعدادات الخصوصية للقصص والملف الشخصي',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                          ),
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