// lib/screens/story_viewer_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final Story story;

  const StoryViewerScreen({super.key, required this.story});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  @override
  void initState() {
    super.initState();
    _markViewed();
  }

  Future<void> _markViewed() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await StoryService.markViewed(
        storyId: widget.story.id,
        viewerId: uid,
      );
    } catch (_) {
      // نتجاهل الخطأ هنا حتى لا ينهار التطبيق
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final created =
        DateTime.fromMillisecondsSinceEpoch(story.createdAt.millisecondsSinceEpoch);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // الخلفية
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.blueGrey],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // المحتوى
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (story.ownerPhotoUrl != null &&
                                  (story.ownerPhotoUrl ?? '').isNotEmpty)
                              ? NetworkImage(story.ownerPhotoUrl!)
                              : null,
                          child: (story.ownerPhotoUrl == null ||
                                  (story.ownerPhotoUrl ?? '').isEmpty)
                              ? Text(
                                  story.ownerName.isNotEmpty
                                      ? story.ownerName[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.ownerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      story.text ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'المشاهدات: ${story.viewers.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}