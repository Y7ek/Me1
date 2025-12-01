import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  File? _selectedImage;
  String? _photoUrl;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _selectedImage = File(path);
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    if (name.isEmpty) {
      _showError('اكتب اسم العرض');
      return;
    }
    if (username.isEmpty) {
      _showError('اكتب "اسم المستخدم" (حتى لو حرف واحد)');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _photoUrl;

      if (_selectedImage != null) {
        photoUrl = await ChatService.uploadProfileImage(
          uid: widget.uid,
          file: _selectedImage!,
        );
      }

      await ChatService.updateUserProfile(
        uid: widget.uid,
        displayName: name,
        username: username,
        bio: bio,
        phoneNumber: widget.phoneNumber,
        photoUrl: photoUrl,
      );
    } catch (e) {
      _showError('تعذّر حفظ المعلومات');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعداد الملف الشخصي'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.camera_alt_rounded, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              if (user?.phoneNumber != null &&
                  user!.phoneNumber!.isNotEmpty)
                Text(
                  'رقمك: ${user.phoneNumber}',
                  style: const TextStyle(fontSize: 13),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  hintText: 'مثال: mm أو m أو mem1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'النبذة الشخصية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('حفظ والمتابعة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}