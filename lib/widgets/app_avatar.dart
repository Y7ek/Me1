import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_settings.dart';

class AppAvatar extends StatelessWidget {
  final double size;
  final ImageProvider? image;
  final IconData fallbackIcon;

  const AppAvatar({
    super.key,
    required this.size,
    this.image,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final shape = settings.avatarShape;

    Widget content = image != null
        ? Image(
            image: image!,
            fit: BoxFit.cover,
          )
        : Icon(
            fallbackIcon,
            size: size * 0.6,
          );

    switch (shape) {
      case AvatarShape.circle:
        return ClipOval(
          child: Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: content,
          ),
        );
      case AvatarShape.rounded:
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: content,
          ),
        );
      case AvatarShape.square:
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: content,
          ),
        );
    }
  }
}
