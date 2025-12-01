// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأصدقاء'),
        ),
        body: const Center(
          child: Text(
            'لاحقاً نضيف هنا قائمة الأصدقاء،\nوالبحث عن الأشخاص باليوزر نيم والرقم.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}