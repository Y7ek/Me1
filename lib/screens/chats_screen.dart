// lib/screens/chats_screen.dart
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'search_users_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;
    final gradient = theme.currentGradient;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتدرجة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // طبقة ضباب
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                const SizedBox(height: 8),
                _buildSearchBar(context, isDark),
                const SizedBox(height: 8),
                Expanded(
                  child: uid == null
                      ? const Center(
                          child: Text(
                            'الرجاء تسجيل الدخول أولاً.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : StreamBuilder<List<Chat>>(
                          stream: ChatService.chatsStream(uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }

                            final chats = snapshot.data ?? [];

                            if (chats.isEmpty) {
                              return const Center(
                                child: Text(
                                  'لا توجد محادثات بعد',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  12, 4, 12, 12),
                              itemCount: chats.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                return _buildChatTile(
                                    context, chat, isDark);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            'Mem',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // ممكن لاحقاً تضيف إعدادات عامة هنا
            },
            icon: Icon(
              CupertinoIcons.ellipsis_circle,
              size: 24,
              color: isDark ? Colors.white : Colors.black87,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SearchUsersScreen(),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(
      BuildContext context, Chat chat, bool isDark) {
    final last = chat.lastMessage;
    final lastText = (last?['text'] as String?) ?? '';
    final createdRaw = last?['createdAt'];
    DateTime? createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    }

    String timeLabel = '';
    if (createdAt != null) {
      final now = DateTime.now();
      final diff = now.difference(createdAt);
      if (diff.inDays == 0) {
        final hh = createdAt.hour.toString().padLeft(2, '0');
        final mm = createdAt.minute.toString().padLeft(2, '0');
        timeLabel = '$hh:$mm';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        timeLabel = days[createdAt.weekday - 1];
      } else {
        timeLabel = '${createdAt.day}/${createdAt.month}';
      }
    }

    const title = 'محادثة'; // لاحقاً نجيب اسم الطرف الثاني من AppUser

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chat: chat),
          ),
        );
      },
      onLongPress: () {
        // خيارات عند الضغط المطوّل
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.78),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.delete_simple,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            'حذف المحادثة (لاحقاً)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.12),
              child: Text(
                title[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastText.isEmpty
                        ? 'لا توجد رسائل بعد'
                        : lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}