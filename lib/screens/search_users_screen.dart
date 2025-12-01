// lib/screens/search_users_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<AppUser> _results = [];
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    // نستخدم debounce بسيط حتى ما نعمل طلب لكل حرف
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchUsers(value);
    });
  }

  Future<void> _searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final users = await ChatService.searchUsers(
        query: q,
        currentUid: currentUid,
      );

      if (!mounted) return;
      setState(() {
        _results = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء البحث: $e'),
        ),
      );
    }
  }

  Future<void> _openChatWithUser(AppUser user) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      // ننشئ / نضمن وجود شات بيني وبين الشخص
      final chat = await ChatService.ensurePrivateChat(
        currentUid: currentUid,
        peerUid: user.id,
      );

      if (!mounted) return;

      // نجيب نسخة محدثة من الشات (لو حاب تستخدم title)
      Chat chatModel = chat;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chat.id)
            .get();
        if (doc.exists) {
          chatModel = Chat.fromDoc(doc);
        }
      } catch (_) {}

      // نفتح شاشة المحادثة الجديدة
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ChatDetailScreen(chat: chatModel),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح المحادثة: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'ابحث باسم المستخدم أو الإيميل...',
              border: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.xmark_circle_fill),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'اكتب اسم المستخدم أو الإيميل للبحث.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    if (_isLoading && _results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد مستخدمين مطابقين.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _results[index];
        final displayName = (user.displayName ?? '').trim();
        final username = (user.username ?? '').trim();
        final email = (user.email ?? '').trim();

        final initials =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

        return ListTile(
          onTap: () => _openChatWithUser(user),
          leading: CircleAvatar(
            backgroundImage: (user.photoUrl != null &&
                    (user.photoUrl ?? '').isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null ||
                    (user.photoUrl ?? '').isEmpty)
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          title: Text(
            displayName.isNotEmpty ? displayName : 'مستخدم',
            style: const TextStyle(fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (username.isNotEmpty)
                Text(
                  '@$username',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}