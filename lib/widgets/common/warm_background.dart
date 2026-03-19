import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class WarmBackground extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double height;

  const WarmBackground({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: double.infinity,
          height: height - 24,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.tr(AppStrings.smartKidsShuttle),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr(title),
                      style: GoogleFonts.prompt(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.tr(subtitle!),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                AppSurfaceCard(
                  inner: true,
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(22),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
