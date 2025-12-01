import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useSystemTheme = false;
  bool _notifications = true;

  String _username = 'Mem User';
  String _handle = '@mem_user';
  String _email = 'user@example.com';

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  Future<void> _editText({
    required String title,
    required String initial,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      onSaved(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;

    final bgGradients =
        isDark ? theme.darkGradients : theme.lightGradients;
    final bgColors = bgGradients[theme.gradientIndex];

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتدرجة من الكنترولر
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // بلور عام
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, theme),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    children: [
                      _buildProfileCard(isDark, theme),
                      const SizedBox(height: 20),

                      _buildSectionTitle('ACCOUNT', isDark),
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _settingItem(
                              isDark: isDark,
                              icon: CupertinoIcons.person_fill,
                              color: Colors.blue,
                              title: 'Username',
                              subtitle: _handle,
                              onTap: () => _editText(
                                title: 'اسم المستخدم',
                                initial: _handle,
                                onSaved: (v) => _handle = v,
                              ),
                            ),
                            _divider(isDark),
                            _settingItem(
                              isDark: isDark,
                              icon: CupertinoIcons.mail_solid,
                              color: Colors.orange,
                              title: 'Email',
                              subtitle: _email,
                              onTap: () => _editText(
                                title: 'البريد الإلكتروني',
                                initial: _email,
                                onSaved: (v) => _email = v,
                              ),
                            ),
                            _divider(isDark),
                            _settingItem(
                              isDark: isDark,
                              icon: CupertinoIcons.lock_fill,
                              color: Colors.pinkAccent,
                              title: 'Password',
                              subtitle: 'Change your password',
                              onTap: () => _showSnack(
                                'تغيير كلمة المرور (نفّذه لاحقاً مع Firebase)',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionTitle('PREFERENCES', isDark),
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              value: _useSystemTheme,
                              onChanged: (v) {
                                setState(() => _useSystemTheme = v);
                                _showSnack(
                                    'Use system theme: $v (واجهة فقط حالياً)');
                              },
                              title: const Text('Use system theme'),
                              subtitle: const Text(
                                'Sync with device appearance',
                              ),
                              secondary: Icon(
                                CupertinoIcons.device_phone_portrait,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                            _divider(isDark),
                            SwitchListTile.adaptive(
                              value: _notifications,
                              onChanged: (v) {
                                setState(() => _notifications = v);
                                _showSnack(
                                    'Notifications: $v (واجهة فقط حالياً)');
                              },
                              title: const Text('Notifications'),
                              subtitle: const Text(
                                'Sounds, vibrations, previews',
                              ),
                              secondary: Icon(
                                CupertinoIcons.bell_solid,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionTitle('THEME COLORS', isDark),
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accent color',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _accentDot(isDark, theme, const Color(0xFF007AFF)),
                                _accentDot(isDark, theme, const Color(0xFF6366F1)),
                                _accentDot(isDark, theme, const Color(0xFFE11D48)),
                                _accentDot(isDark, theme, const Color(0xFF0EA5E9)),
                                _accentDot(isDark, theme, const Color(0xFF22C55E)),
                                _accentDot(isDark, theme, const Color(0xFFF97316)),
                                _accentDot(isDark, theme, const Color(0xFFFACC15)),
                                _accentDot(isDark, theme, const Color(0xFFEC4899)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Background gradient',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(
                                (isDark
                                        ? theme.darkGradients.length
                                        : theme.lightGradients.length)
                                    .clamp(0, 4),
                                (index) {
                                  final colors = isDark
                                      ? theme.darkGradients[index]
                                      : theme.lightGradients[index];
                                  return _gradientPreview(
                                    isDark,
                                    theme,
                                    index,
                                    colors,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionTitle('ABOUT', isDark),
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _settingItem(
                              isDark: isDark,
                              icon: CupertinoIcons.info_circle_fill,
                              color: Colors.blueGrey,
                              title: 'About Mem',
                              subtitle: 'Version 1.0.0',
                              onTap: () =>
                                  _showSnack('حول التطبيق (نفّذه لاحقاً)'),
                            ),
                            _divider(isDark),
                            _settingItem(
                              isDark: isDark,
                              icon: CupertinoIcons.question_circle_fill,
                              color: Colors.cyan,
                              title: 'Help & FAQ',
                              onTap: () =>
                                  _showSnack('مركز المساعدة (نفّذه لاحقاً)'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            _showSnack('تسجيل الخروج (اربطه لاحقاً بـ FirebaseAuth)');
                          },
                          icon: const Icon(
                            CupertinoIcons.square_arrow_right_fill,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Log out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── HEADER ─────────

  Widget _buildHeader(bool isDark, ThemeController theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: theme.toggleTheme,
            icon: Icon(
              isDark ? Icons.sunny : Icons.nights_stay,
              color: theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── PROFILE CARD ─────────

  Widget _buildProfileCard(bool isDark, ThemeController theme) {
    return _glassCard(
      isDark: isDark,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.accentColor,
            child: Text(
              _username.isNotEmpty
                  ? _username[0].toUpperCase()
                  : 'M',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _handle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── HELPERS ─────────

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _glassCard({
    required bool isDark,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 8,
      color: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.08),
    );
  }

  Widget _settingItem({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        size: 18,
        color: isDark ? Colors.white54 : Colors.grey,
      ),
    );
  }

  // دائرة لون Accent
  Widget _accentDot(
      bool isDark, ThemeController theme, Color color) {
    final bool selected = theme.accentColor.value == color.value;
    return GestureDetector(
      onTap: () => theme.setAccentColor(color),
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? color
                : (isDark ? Colors.white54 : Colors.black26),
            width: selected ? 2.2 : 1,
          ),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: color,
        ),
      ),
    );
  }

  // معاينة تدرج الخلفية
  Widget _gradientPreview(
    bool isDark,
    ThemeController theme,
    int index,
    List<Color> colors,
  ) {
    final bool selected = theme.gradientIndex == index;

    return GestureDetector(
      onTap: () => theme.setGradientIndex(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 60,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.accentColor
                : (isDark ? Colors.white30 : Colors.black26),
            width: selected ? 2 : 1,
          ),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}