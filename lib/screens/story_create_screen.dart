import 'package:flutter/material.dart';

import '../services/story_service.dart';

class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final _textController = TextEditingController();
  Duration _selectedDuration = const Duration(hours: 24);
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      _showError('اكتب شيئاً في القصة أولاً');
      return;
    }

    setState(() => _isSending = true);

    try {
      await StoryService.createStory(
        text: text,
        imageUrl: null, // نضيف الصور لاحقاً إذا حبيت
        duration: _selectedDuration,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // نرجع للدردشات بعد إنشاء القصة
    } catch (e) {
      _showError('فشل إنشاء القصة، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قصة جديدة'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نص القصة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'اكتب شيئاً ليظهر في القصة…',
                  filled: true,
                  fillColor: const Color(0xfff5f7fd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'مدة ظهور القصة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _DurationChip(
                    label: '6 ساعات',
                    duration: const Duration(hours: 6),
                    selected: _selectedDuration.inHours == 6,
                    onTap: () {
                      setState(() {
                        _selectedDuration = const Duration(hours: 6);
                      });
                    },
                  ),
                  _DurationChip(
                    label: '12 ساعة',
                    duration: const Duration(hours: 12),
                    selected: _selectedDuration.inHours == 12,
                    onTap: () {
                      setState(() {
                        _selectedDuration = const Duration(hours: 12);
                      });
                    },
                  ),
                  _DurationChip(
                    label: '24 ساعة',
                    duration: const Duration(hours: 24),
                    selected: _selectedDuration.inHours == 24,
                    onTap: () {
                      setState(() {
                        _selectedDuration = const Duration(hours: 24);
                      });
                    },
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSending
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

class _DurationChip extends StatelessWidget {
  final String label;
  final Duration duration;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xff2f80ed);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xffeef2fb),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}