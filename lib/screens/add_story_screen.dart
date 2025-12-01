import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _captionController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  int _hoursVisible = 24; // مدة ظهور القصة

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final res = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (res != null) {
      setState(() {
        _selectedImage = File(res.path);
      });
    }
  }

  Future<void> _submitStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رجاءً اختر صورة أولاً')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser!;
      final uid = user.uid;

      // رفع الصورة إلى Storage
      final fileName =
          'story_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child(uid)
          .child(fileName);

      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();

      final now = DateTime.now().toUtc();
      final expiresAt = now.add(Duration(hours: _hoursVisible));

      // جلب اسم المستخدم من Firestore إن وجد
      String displayName = user.phoneNumber ?? user.email ?? 'مستخدم';
      String? photoUrl = user.photoURL;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        displayName = data['displayName'] ?? displayName;
        photoUrl = data['photoUrl'] ?? photoUrl;
      }

      // حفظ القصة
      await FirebaseFirestore.instance.collection('stories').add({
        'ownerId': uid,
        'ownerName': displayName,
        'ownerPhotoUrl': photoUrl,
        'mediaUrl': url,
        'caption': _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        'createdAt': now,
        'expiresAt': expiresAt,
        'viewers': <String>[],
      });

      if (mounted) {
        Navigator.pop(context, true); // نرجع لقائمة المحادثات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ القصة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة قصة'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade200,
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded, size: 40),
                            SizedBox(height: 8),
                            Text('اضغط لاختيار صورة من المعرض'),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'نص قصير (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'مدة ظهور القصة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _hoursVisible,
                    items: const [
                      DropdownMenuItem(
                        value: 6,
                        child: Text('6 ساعات'),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child: Text('12 ساعة'),
                      ),
                      DropdownMenuItem(
                        value: 24,
                        child: Text('24 ساعة'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _hoursVisible = v);
                    },
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitStory,
                  child: _isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('نشر القصة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}