import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/story.dart';
import '../screens/add_story_screen.dart';
import '../screens/story_viewer_screen.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SizedBox(
      height: 104,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where(
              'expiresAt',
              isGreaterThan: DateTime.now().toUtc(),
            )
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final stories = docs.map((d) => Story.fromDoc(d)).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // عنصر إضافة قصة (قصتي)
                return _AddStoryItem(
                  onAdd: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddStoryScreen(),
                      ),
                    );
                    if (created == true) {
                      // ممكن نظهر SnackBar نجاح
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نشر القصة')),
                      );
                    }
                  },
                );
              }

              final story = stories[index - 1];
              final isMine = uid != null && story.ownerId == uid;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(story: story),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isMine
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xff4facfe),
                                    Color(0xff00f2fe),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xfff09433),
                                    Color(0xffe6683c),
                                    Color(0xffdc2743),
                                    Color(0xffcc2366),
                                    Color(0xffbc1888),
                                  ],
                                ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              image: story.ownerPhotoUrl != null &&
                                      story.ownerPhotoUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image:
                                          NetworkImage(story.ownerPhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (story.ownerPhotoUrl == null ||
                                    story.ownerPhotoUrl!.isEmpty)
                                ? Center(
                                    child: Text(
                                      story.ownerName.isNotEmpty
                                          ? story.ownerName[0].toUpperCase()
                                          : 'M',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          isMine ? 'قصتي' : story.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddStoryItem extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddStoryItem({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onAdd,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                  child: const Icon(Icons.person_rounded, size: 32),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 70,
              child: Text(
                'إضافة قصة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}