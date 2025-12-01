import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_service.dart';
import '../models/chat.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _selectedSegment = 0; // 0 = All Chats, 1 = Contacts
  int _selectedTab = 1; // 0 = Contacts, 1 = Chats, 2 = Settings

  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF6F6F6);
    final appBarColor = isDark ? const Color(0xFF000000) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(appBarColor, isDark),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<Chat>>(
                stream: _chatService.watchChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final chats = snapshot.data ?? [];

                  // حالياً تبويب All Chats / Contacts لا يغير الفلترة،
                  // بإمكانك لاحقاً تمييز الشات إذا كان من جهات اتصال فقط.
                  final chatsToShow = chats;

                  if (chatsToShow.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد محادثات بعد',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: chatsToShow.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 72,
                      color: dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final chat = chatsToShow[index];
                      return _buildChatRow(context, chat, isDark);
                    },
                  );
                },
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  // ----------------- Header -----------------

  Widget _buildHeader(Color appBarColor, bool isDark) {
    return Container(
      color: appBarColor,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          // السطر الأول: Edit - Mem - (بحث + ثيم)
          Row(
            children: [
              const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Text(
                'Mem',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Search',
                onPressed: () {
                  // TODO: شاشة البحث لاحقاً
                },
                icon: const Icon(
                  Icons.search,
                  size: 22,
                  color: Color(0xFF007AFF),
                ),
              ),
              IconButton(
                tooltip: 'Theme',
                onPressed: () {
                  // تفعيل تغيير الثيم إذا عندك ThemeController في الأعلى
                  // ممكن تستبدل هذا الكود بـ:
                  // context.read<ThemeController>().toggleTheme();
                },
                icon: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // التبويب العلوي All Chats / Contacts
          Container(
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  label: 'All Chats',
                  index: 0,
                  isDark: isDark,
                ),
                _buildSegmentButton(
                  label: 'Contacts', // بدل Friends إلى Contacts
                  index: 1,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final bool isSelected = _selectedSegment == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedSegment = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF007AFF)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------- Chat row -----------------

  Widget _buildChatRow(BuildContext context, Chat chat, bool isDark) {
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final timeColor = isDark ? Colors.white60 : Colors.grey.shade600;

    final title = chat.title.isNotEmpty ? chat.title : 'Unnamed chat';
    final avatarLabel =
        title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?';

    final lastMsgText = chat.lastMessage?.text ?? '';
    final lastMsgTime = chat.lastMessage?.createdAt ?? chat.updatedAt;

    final timeLabel =
        lastMsgTime != null ? _formatTimeLabel(lastMsgTime) : '';

    return InkWell(
      onTap: () {
        // TODO: افتح شاشة تفاصيل المحادثة
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => ChatDetailScreen(chat: chat),
        // ));
      },
      child: Container(
        color: isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Colors.blueAccent.withOpacity(0.85), // تقدر تغيّر اللون
              child: Text(
                avatarLabel,
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
                  // العنوان
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMsgText.isEmpty
                        ? 'لا توجد رسائل بعد'
                        : lastMsgText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeLabel.isNotEmpty)
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                // بإمكانك لاحقاً إضافة علامة قراءة أو عدد رسائل غير مقروءة
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // نفس اليوم → نعرض الوقت فقط HH:mm
      final hh = dateTime.hour.toString().padLeft(2, '0');
      final mm = dateTime.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } else if (difference.inDays < 7) {
      // آخر أسبوع → اسم اليوم (بالعربي بشكل مبسّط)
      const days = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      return days[dateTime.weekday - 1];
    } else {
      // أقدم من أسبوع → تاريخ مختصر
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // ----------------- Bottom bar -----------------

  Widget _buildBottomBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF111111) : Colors.white;
    final iconInactive = isDark ? Colors.white70 : Colors.grey.shade600;
    const iconActive = Color(0xFF007AFF);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomItem(
                icon: CupertinoIcons.person_crop_circle,
                label: 'Contacts',
                index: 0,
                isActive: _selectedTab == 0,
                activeColor: iconActive,
                inactiveColor: iconInactive,
              ),
              _buildBottomItem(
                icon: CupertinoIcons.chat_bubble_2_fill,
                label: 'Chats',
                index: 1,
                isActive: _selectedTab == 1,
                activeColor: iconActive,
                inactiveColor: iconInactive,
              ),
              _buildBottomItem(
                icon: CupertinoIcons.gear, // أيقونة إعدادات أفضل
                label: 'Settings',
                index: 2,
                isActive: _selectedTab == 2,
                activeColor: iconActive,
                inactiveColor: iconInactive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        // هنا ممكن لاحقاً تبدّل الشاشة حسب التاب
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}