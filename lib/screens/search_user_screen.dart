// lib/screens/search_user_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<AppUser> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final users = await ChatService.searchUsers(
        query: text,
        currentUid: currentUid,
      );

      setState(() {
        _results = users;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء البحث، حاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openChatWith(AppUser user) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final chat = await ChatService.ensurePrivateChat(
        currentUid: currentUid,
        peerUid: user.id,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            peerId: user.id,
            peerName: user.displayName ?? user.username ?? 'مستخدم',
            peerPhotoUrl: user.photoUrl,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح المحادثة، حاول مرّة أخرى.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث عن مستخدم'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // شريط البحث المتقدّم
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'ابحث بالاسم، اسم المستخدم أو الإيميل',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _runSearch(),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _results = [];
                            _error = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _runSearch,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'اكتب اسم مستخدم أو إيميل للبحث.\nمثال: user123 أو example@email.com',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final title = user.displayName ??
                          user.username ??
                          'مستخدم بدون اسم';
                      final subtitle = user.username != null &&
                              user.username!.isNotEmpty
                          ? '@${user.username}'
                          : (user.email ?? '');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                          child: (user.photoUrl == null ||
                                  user.photoUrl!.isEmpty)
                              ? Text(
                                  title.isNotEmpty
                                      ? title[0].toUpperCase()
                                      : 'M',
                                )
                              : null,
                        ),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          onPressed: () => _openChatWith(user),
                        ),
                        onTap: () => _openChatWith(user),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}