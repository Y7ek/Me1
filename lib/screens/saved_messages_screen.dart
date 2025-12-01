// lib/screens/saved_messages_screen.dart
import 'package:flutter/material.dart';

class SavedMessagesScreen extends StatelessWidget {
  const SavedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرسائل المحفوظة'),
        ),
        body: const Center(
          child: Text(
            'لاحقاً يمكن ربط هذه الشاشة برسائل محفوظة مثل تيليجرام.\nحالياً فقط واجهة حقيقية بدون أزرار وهمية.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}