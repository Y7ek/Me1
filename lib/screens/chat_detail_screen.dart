// lib/screens/chat_detail_screen.dart
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../models/chat.dart';
import '../models/message.dart';

import 'chat_user_profile.dart';

class ChatDetailScreen extends StatelessWidget {
  final Chat chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(chat: chat),
      child: const _ChatDetailView(),
    );
  }
}

class _ChatDetailView extends StatefulWidget {
  const _ChatDetailView();

  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // للإزاحة عند السحب (للرد)
  final Map<String, double> _swipeOffsets = {};

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, child) {
        final bg = _resolveBackground(controller.backgroundKey);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // الخلفية المتدرجة
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bg.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // الضباب العام
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(color: Colors.black.withOpacity(0.15)),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, controller),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _buildMessagesList(controller),
                      ),
                      if (controller.replyToMessage != null)
                        _buildReplyPreview(controller),
                      _buildInputBar(controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //────────────────────────────────────────────
  // Header
  //────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ChatController controller) {
    final chat = controller.chat;
    final title = chat.title.isNotEmpty ? chat.title : 'محادثة';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          // زر رجوع
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 6),

          // الصورة + الاسم → تفتح صفحة البروفايل
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => ChatUserProfileScreen(
                    chatId: chat.id,
                    chatTitle: title,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: Text(
                    title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '؟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'متصل الآن',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // زر المزيد (...)
          GestureDetector(
            onTap: () => _openTopMenu(context, controller),
            child: const Icon(
              CupertinoIcons.ellipsis,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  //────────────────────────────────────────────
  // قائمة الخيارات العلوية
  //────────────────────────────────────────────

  void _openTopMenu(BuildContext context, ChatController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _glassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                label: 'تغيير خلفية المحادثة',
                onTap: () {
                  Navigator.pop(ctx);
                  _openBackgroundPicker(context, controller);
                },
              ),
              _sheetTile(
                icon: CupertinoIcons.bell_slash_fill,
                label: 'كتم الإشعارات (لاحقاً)',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سندعم كتم الإشعارات في خطوة لاحقة.'),
                    ),
                  );
                },
              ),
              _sheetTile(
                icon: CupertinoIcons.delete_solid,
                label: 'حذف كل الرسائل (لاحقاً)',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'حذف المحادثة بالكامل سنضيفه في خطوة لاحقة.',
                      ),
                    ),
                  );
                },
              ),
              _sheetCancel(context),
            ],
          ),
        );
      },
    );
  }

  void _openBackgroundPicker(
    BuildContext context,
    ChatController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentKey = controller.backgroundKey ?? 'default';

        final presets = <_ChatBackground>[
          const _ChatBackground(
            key: 'default',
            name: 'افتراضي',
            colors: [
              Color(0xFF050608),
              Color(0xFF151515),
            ],
          ),
          const _ChatBackground(
            key: 'blue',
            name: 'أزرق',
            colors: [
              Color(0xFF020617),
              Color(0xFF0F172A),
            ],
          ),
          const _ChatBackground(
            key: 'purple',
            name: 'بنفسجي',
            colors: [
              Color(0xFF1E293B),
              Color(0xFF020617),
            ],
          ),
        ];

        return _glassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'اختر خلفية المحادثة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: presets.length,
                  itemBuilder: (_, i) {
                    final bg = presets[i];
                    final selected = bg.key == currentKey;
                    return GestureDetector(
                      onTap: () async {
                        await controller.setChatBackground(bg.key);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: bg.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white24,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            bg.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                ),
              ),
              const SizedBox(height: 12),
              _sheetCancel(context),
            ],
          ),
        );
      },
    );
  }

  //────────────────────────────────────────────
  // Messages list
  //────────────────────────────────────────────

  Widget _buildMessagesList(ChatController controller) {
    final messages = controller.messages;

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'ابدأ المحادثة الآن ✨',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 4),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageWrapper(context, controller, msg);
      },
    );
  }

  Widget _buildMessageWrapper(
    BuildContext context,
    ChatController controller,
    Message msg,
  ) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final current = _swipeOffsets[msg.id] ?? 0.0;
          final updated = (current + details.delta.dx).clamp(-40.0, 40.0);
          _swipeOffsets[msg.id] = updated;
        });
      },
      onHorizontalDragEnd: (_) {
        final offset = _swipeOffsets[msg.id] ?? 0.0;
        if (offset.abs() > 25) {
          controller.startReply(msg);
        }
        setState(() {
          _swipeOffsets[msg.id] = 0.0;
        });
      },
      onLongPress: () => _openMessageMenu(context, controller, msg),
      child: _buildBubble(controller, msg),
    );
  }

  void _openMessageMenu(
    BuildContext context,
    ChatController controller,
    Message msg,
  ) {
    final isMe = msg.senderId == controller.currentUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _glassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                icon: CupertinoIcons.reply,
                label: 'رد',
                onTap: () {
                  Navigator.pop(ctx);
                  controller.startReply(msg);
                },
              ),
              if (!msg.isDeleted && msg.text.isNotEmpty)
                _sheetTile(
                  icon: CupertinoIcons.doc_on_doc,
                  label: 'نسخ',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    Navigator.pop(ctx);
                  },
                ),
              _sheetTile(
                icon: CupertinoIcons.arrow_turn_up_right,
                label: 'تحويل (لاحقاً)',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('ميزة إعادة التوجيه سيتم إضافتها لاحقاً.'),
                    ),
                  );
                },
              ),
              _sheetTile(
                icon: CupertinoIcons.delete_solid,
                label: isMe ? 'حذف الرسالة' : 'حذف (لديك فقط)',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  await controller.deleteMessage(msg);
                },
              ),
              _sheetCancel(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(ChatController controller, Message msg) {
    final isMe = msg.senderId == controller.currentUid;
    final alignment = isMe ? Alignment.centerLeft : Alignment.centerRight; // RTL

    final bubbleColor = msg.isDeleted
        ? Colors.white.withOpacity(0.05)
        : (isMe
            ? const Color(0xFF0EA5E9)
            : Colors.white.withOpacity(0.08));

    final radius = BorderRadius.only(
      topRight: const Radius.circular(18),
      topLeft: const Radius.circular(18),
      bottomRight: Radius.circular(isMe ? 4 : 18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
    );

    // رسالة يتم الرد عليها داخل الفقاعة
    Message? replied;
    if (msg.replyToMessageId != null) {
      try {
        replied = controller.messages.firstWhere(
          (m) => m.id == msg.replyToMessageId,
        );
      } catch (_) {
        replied = null;
      }
    }

    Widget content;

    if (msg.isDeleted || msg.type == 'deleted') {
      content = const Text(
        'تم حذف هذه الرسالة',
        style: TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      Widget mainText = Text(
        msg.text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.white.withOpacity(0.95),
          fontSize: 14,
        ),
      );

      if (replied != null) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                replied.text.isNotEmpty ? replied.text : 'رسالة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
            mainText,
          ],
        );
      } else {
        content = mainText;
      }
    }

    final offset = _swipeOffsets[msg.id] ?? 0.0;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.7,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  //────────────────────────────────────────────
  // Reply preview
  //────────────────────────────────────────────

  Widget _buildReplyPreview(ChatController controller) {
    final msg = controller.replyToMessage!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.reply,
            color: Colors.lightBlueAccent,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg.text.isEmpty ? 'رسالة' : msg.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.clearReply,
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Colors.white54,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  //────────────────────────────────────────────
  // Input bar – زر + والمايك فقط وشريط زجاجي
  //────────────────────────────────────────────

  Widget _buildInputBar(ChatController controller) {
    final isSending = controller.isSending;
    final canSend =
        _inputController.text.trim().isNotEmpty && !isSending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          // زر +
          GestureDetector(
            onTap: () => _openPlusMenu(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.15),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // حقل الكتابة (زجاجي)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _inputController,
                    onChanged: (_) => setState(() {}),
                    maxLines: null,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'رسالتك...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // زر مايك أو إرسال
          GestureDetector(
            onTap: canSend
                ? () async {
                    final text = _inputController.text.trim();
                    if (text.isEmpty) return;

                    await controller.sendText(text);
                    _inputController.clear();
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 50));
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent + 80,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canSend
                    ? const Color(0xFF0EA5E9)
                    : Colors.white.withOpacity(0.16),
              ),
              child: Icon(
                canSend ? CupertinoIcons.arrow_up : CupertinoIcons.mic_fill,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _glassSheet(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickAction(
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'المعرض',
                onTap: () {
                  Navigator.pop(ctx);
                  // لاحقاً: فتح المعرض
                },
              ),
              _quickAction(
                icon: CupertinoIcons.camera_fill,
                label: 'الكاميرا',
                onTap: () {
                  Navigator.pop(ctx);
                  // لاحقاً: فتح الكاميرا
                },
              ),
              _quickAction(
                icon: CupertinoIcons.paperclip,
                label: 'ملف',
                onTap: () {
                  Navigator.pop(ctx);
                  // لاحقاً: اختيار ملف
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  //────────────────────────────────────────────
  // Helpers: الشيت الزجاجي + البلاطات
  //────────────────────────────────────────────

  Widget _glassSheet({required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _sheetCancel(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        'إلغاء',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  //────────────────────────────────────────────
  // Background model + resolver
  //────────────────────────────────────────────

  _ChatBackground _resolveBackground(String? key) {
    switch (key) {
      case 'blue':
        return const _ChatBackground(
          key: 'blue',
          name: 'أزرق',
          colors: [
            Color(0xFF020617),
            Color(0xFF0F172A),
          ],
        );
      case 'purple':
        return const _ChatBackground(
          key: 'purple',
          name: 'بنفسجي',
          colors: [
            Color(0xFF1E293B),
            Color(0xFF020617),
          ],
        );
      case 'default':
      default:
        return const _ChatBackground(
          key: 'default',
          name: 'افتراضي',
          colors: [
            Color(0xFF050608),
            Color(0xFF151515),
          ],
        );
    }
  }
}

class _ChatBackground {
  final String key;
  final String name;
  final List<Color> colors;

  const _ChatBackground({
    required this.key,
    required this.name,
    required this.colors,
  });
}
