import 'package:flutter/material.dart';
import 'package:sks/core/constants/app_colors.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool inner;
  final Color? color;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.inner = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(inner ? 26 : 30);
    final backgroundColor =
        color ??
        (inner ? Colors.white.withValues(alpha: 0.94) : AppColors.background);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: inner
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.72),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                const BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: Border.all(
            color: inner
                ? const Color(0xFFF2E4DE)
                : Colors.white.withValues(alpha: 0.98),
            width: inner ? 1.2 : 1,
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
