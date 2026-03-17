import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/local_image_provider.dart';

class ChildAvatar extends StatelessWidget {
  final Child child;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const ChildAvatar({
    super.key,
    required this.child,
    this.size = 48,
    this.backgroundColor = AppColors.surfaceSoft,
    this.textColor = AppColors.primary,
    this.fontSize = 18,
  });

  bool get _hasPhoto => child.photoUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasPhoto ? _buildPhoto() : _buildFallback(),
    );
  }

  Widget _buildPhoto() {
    final provider = imageProviderFromPath(child.photoUrl);
    if (provider == null) {
      return _buildFallback();
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        child.name.isNotEmpty ? child.name[0] : '?',
        style: GoogleFonts.prompt(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
