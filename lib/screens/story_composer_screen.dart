import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/story_service.dart';

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
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
        const SnackBar(content: Text('اكتب شيئاً في القصة أولاً')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أعد تسجيل الدخول ثم جرّب مجدداً')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // نحاول جلب اسم المستخدم من ChatService لو عندك مستخدم مسجّل في Firestore
      final appUser = await ChatService.getUser(user.uid);

      await StoryService.publishTextStory(
        ownerId: user.uid,
        ownerName: appUser?.displayName ?? (user.phoneNumber ?? 'مستخدم'),
        ownerPhotoUrl: appUser?.photoUrl,
        text: text,
        visibleFor: Duration(hours: _selectedHours),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل نشر القصة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff0b0f1a),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('قصة جديدة'),
        ),
        body: Stack(
          children: [
            // خلفية بلور
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff1f2a3c),
                        Color(0xff283445),
                        Color(0xff141925),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'اكتب قصتك هنا…',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 22,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // اختيار مدة القصة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 18, color: Colors.white70),
                          const SizedBox(width: 8),
                          const Text(
                            'مدة ظهور القصة:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          _DurationChip(
                            label: '6 س',
                            hours: 6,
                            value: _selectedHours,
                            onChanged: (h) =>
                                setState(() => _selectedHours = h),
                          ),
                          _DurationChip(
                            label: '12 س',
                            hours: 12,
                            value: _selectedHours,
                            onChanged: (h) =>
                                setState(() => _selectedHours = h),
                          ),
                          _DurationChip(
                            label: '24 س',
                            hours: 24,
                            value: _selectedHours,
                            onChanged: (h) =>
                                setState(() => _selectedHours = h),
                          ),
                          _DurationChip(
                            label: '48 س',
                            hours: 48,
                            value: _selectedHours,
                            onChanged: (h) =>
                                setState(() => _selectedHours = h),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _submit,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? 'جاري النشر…' : 'نشر القصة',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final int hours;
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationChip({
    required this.label,
    required this.hours,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = value == hours;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 11,
          ),
        ),
        selected: selected,
        selectedColor: const Color(0xff2f80ed),
        backgroundColor: Colors.white10,
        onSelected: (_) => onChanged(hours),
      ),
    );
  }
}