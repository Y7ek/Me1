import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatTheme {
  final Color backgroundColor;
  final double backgroundBlur;
  final Color myBubbleColor;
  final Color peerBubbleColor;
  final bool useGradient;

  const ChatTheme({
    required this.backgroundColor,
    required this.backgroundBlur,
    required this.myBubbleColor,
    required this.peerBubbleColor,
    required this.useGradient,
  });

  /// ثيم افتراضي قريب من تيليجرام iOS
  factory ChatTheme.defaultTheme() {
    return const ChatTheme(
      backgroundColor: Color(0xfff5f7fb),
      backgroundBlur: 0.0,
      myBubbleColor: Color(0xff2f80ed),
      peerBubbleColor: Colors.white,
      useGradient: false,
    );
  }

  ChatTheme copyWith({
    Color? backgroundColor,
    double? backgroundBlur,
    Color? myBubbleColor,
    Color? peerBubbleColor,
    bool? useGradient,
  }) {
    return ChatTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      myBubbleColor: myBubbleColor ?? this.myBubbleColor,
      peerBubbleColor: peerBubbleColor ?? this.peerBubbleColor,
      useGradient: useGradient ?? this.useGradient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor.value,
      'backgroundBlur': backgroundBlur,
      'myBubbleColor': myBubbleColor.value,
      'peerBubbleColor': peerBubbleColor.value,
      'useGradient': useGradient,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatTheme.fromMap(Map<String, dynamic> map) {
    return ChatTheme(
      backgroundColor: Color((map['backgroundColor'] as int?) ?? 0xfff5f7fb),
      backgroundBlur: (map['backgroundBlur'] as num?)?.toDouble() ?? 0.0,
      myBubbleColor: Color((map['myBubbleColor'] as int?) ?? 0xff2f80ed),
      peerBubbleColor: Color((map['peerBubbleColor'] as int?) ?? 0xffffffff),
      useGradient: (map['useGradient'] as bool?) ?? false,
    );
  }

  factory ChatTheme.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatTheme.fromMap(data);
  }
}