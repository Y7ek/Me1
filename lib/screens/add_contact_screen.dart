// lib/screens/add_contact_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';

class AddContactScreen extends StatefulWidget {
  final AppUser user;

  const AddContactScreen({super.key, required this.user});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final peerUid = widget.user.id;

    final name = _nameController.text.trim();
    final note = _noteController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم لجهة الاتصال.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // نحفظ جهة الاتصال تحت:
      // users/{currentUid}/contacts/{peerUid}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('contacts')
          .doc(peerUid)
          .set({
        'uid': peerUid,
        'displayName': name,
        'username': widget.user.username ?? '',
        'photoUrl': widget.user.photoUrl ?? '',
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ جهة الاتصال بنجاح.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (widget.user.displayName != null &&
            (widget.user.displayName ?? '').isNotEmpty)
        ? widget.user.displayName![0].toUpperCase()
        : 'M';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة إلى جهات الاتصال'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (widget.user.photoUrl != null &&
                        (widget.user.photoUrl ?? '').isNotEmpty)
                    ? NetworkImage(widget.user.photoUrl!)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: (widget.user.photoUrl == null ||
                        (widget.user.photoUrl ?? '').isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم في جهات الاتصال',
              ),
            ),
            const SizedBox(height: 12),
            if ((widget.user.username ?? '').isNotEmpty) ...[
              Text(
                'اسم المستخدم: @${widget.user.username}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                hintText: 'مثال: صديق من العمل',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveContact,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}