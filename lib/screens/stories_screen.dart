// lib/screens/stories_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';
import 'story_viewer_screen.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('القصص'),
        ),
        body: StreamBuilder<List<Story>>(
          stream: StoryService.activeStoriesStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stories = snap.data ?? [];

            if (stories.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد قصص بعد.\nاضغط الزر العائم لإضافة قصة جديدة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                  ),
                ),
              );
            }

            // ترتيب بحيث قصتك (إن وجدت) تكون في الأعلى
            stories.sort((a, b) {
              if (uid != null) {
                if (a.ownerId == uid && b.ownerId != uid) return -1;
                if (b.ownerId == uid && a.ownerId != uid) return 1;
              }
              return b.createdAt.compareTo(a.createdAt);
            });

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                final isMine = story.ownerId == uid;
                final viewed =
                    story.viewers.contains(uid ?? '__none__');

                return ListTile(
                  leading: _StoryAvatar(
                    name: story.ownerName,
                    photoUrl: story.ownerPhotoUrl,
                    viewed: viewed,
                  ),
                  title: Text(
                    isMine
                        ? '${story.ownerName} (قصتي)'
                        : story.ownerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    story.text.isEmpty
                        ? 'قصة بدون نص'
                        : story.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: stories,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _openCreateStorySheet(context);
          },
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('قصة جديدة'),
        ),
      ),
    );
  }

  void _openCreateStorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const _CreateStorySheet();
      },
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool viewed;

  const _StoryAvatar({
    required this.name,
    required this.photoUrl,
    required this.viewed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = viewed
        ? Colors.grey
        : const Color(0xff2f80ed); // أزرق لو جديد

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: viewed
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xff2f80ed),
                  Color(0xff9b51e0),
                ],
              ),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                )
              : Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// شيت إنشاء قصة نصية + اختيار مدة الظهور
class _CreateStorySheet extends StatefulWidget {
  const _CreateStorySheet();

  @override
  State<_CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<_CreateStorySheet> {
  final _textController = TextEditingController();
  double _hours = 24;

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

    setState(() => _isSending = true);

    try {
      await StoryService.publishTextStory(
        text: text,
        durationHours: _hours.round(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر نشر القصة، حاول مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'إضافة قصة جديدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب النص الذي تريد نشره في القصة...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('مدة ظهور القصة'),
                const SizedBox(width: 8),
                Text('${_hours.round()} ساعة'),
              ],
            ),
            Slider(
              value: _hours,
              min: 6,
              max: 72,
              divisions: 11,
              label: '${_hours.round()} ساعة',
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('نشر القصة'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}