import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/widgets/common/local_image_provider.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 56,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);
    final fg = textColor ?? AppColors.primary;
    final path = user?.profilePhotoPath.trim() ?? '';
    final provider = imageProviderFromPath(path);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      clipBehavior: Clip.antiAlias,
      child: provider == null
          ? Center(
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0] : '?',
                style: GoogleFonts.prompt(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : Image(
              image: provider,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0] : '?',
                  style: GoogleFonts.prompt(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
            ),
    );
  }
}
