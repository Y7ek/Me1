// lib/screens/story_editor_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/story_service.dart';

class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({super.key});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final _textController = TextEditingController();
  int _selectedHours = 24;
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب نص القصة أولاً')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};

      final ownerName = (data['displayName'] as String?)?.trim();
      final ownerPhotoUrl = data['photoUrl'] as String?;

      await StoryService.createTextStory(
        ownerId: uid,
        ownerName: ownerName != null && ownerName.isNotEmpty
            ? ownerName
            : 'مستخدم',
        ownerPhotoUrl: ownerPhotoUrl,
        text: text,
        duration: Duration(hours: _selectedHours),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر القصة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل نشر القصة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'نص القصة',
                  hintText: 'اكتب ما تريد نشره كقصة…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مدة ظهور القصة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _DurationChip(
                    label: '6 ساعات',
                    hours: 6,
                    selected: _selectedHours == 6,
                    onTap: () => setState(() => _selectedHours = 6),
                  ),
                  _DurationChip(
                    label: '12 ساعة',
                    hours: 12,
                    selected: _selectedHours == 12,
                    onTap: () => setState(() => _selectedHours = 12),
                  ),
                  _DurationChip(
                    label: '24 ساعة',
                    hours: 24,
                    selected: _selectedHours == 24,
                    onTap: () => setState(() => _selectedHours = 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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

class _DurationChip extends StatelessWidget {
  final String label;
  final int hours;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.hours,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}