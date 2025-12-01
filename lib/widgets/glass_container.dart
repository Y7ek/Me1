// lib/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.7,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tintColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseTint = tintColor ?? Colors.white;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseTint.withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}