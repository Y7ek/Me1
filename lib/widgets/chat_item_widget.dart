import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';

class ChatItemData {
  final String name;
  final String message;
  final String time;
  final int unread;

  ChatItemData({
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
  });
}

class ChatItemWidget extends StatelessWidget {
  final ChatItemData data;
  final VoidCallback onLongPress;

  const ChatItemWidget({
    super.key,
    required this.data,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.accentColor,
                    child: Text(
                      data.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: theme.isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              data.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.message,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),

                            if (data.unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${data.unread}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}