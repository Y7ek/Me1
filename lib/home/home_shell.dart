import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;

    final pages = [
      const ChatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.75)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(
                    label: "Chats",
                    icon: CupertinoIcons.bubble_left_bubble_right_fill,
                    index: 0,
                  ),
                  _navItem(
                    label: "Settings",
                    icon: CupertinoIcons.gear_solid,
                    index: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final theme = context.watch<ThemeController>();
    final selected = _index == index;

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.accentColor.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? theme.accentColor
                  : (theme.isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? theme.accentColor
                    : (theme.isDark ? Colors.white70 : Colors.black87),
              ),
            )
          ],
        ),
      ),
    );
  }
}