import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';

class BoardingChildTile extends StatelessWidget {
  final Child child;
  final VoidCallback onToggleBoarding;

  const BoardingChildTile({
    super.key,
    required this.child,
    required this.onToggleBoarding,
  });

  @override
  Widget build(BuildContext context) {
    final isBoarded = child.hasBoarded;

    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBoarded
                      ? AppColors.statusGreen
                      : AppColors.statusGrey,
                ),
                child: ChildAvatar(
                  child: child,
                  size: 48,
                  backgroundColor: isBoarded
                      ? AppColors.statusGreen
                      : AppColors.statusGrey,
                  textColor: AppColors.textOnPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      child.homeAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isBoarded
                      ? AppColors.statusGreen
                      : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBoarded
                      ? HugeIcons.strokeRoundedTick01
                      : HugeIcons.strokeRoundedQrCode,
                  color: isBoarded
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (isBoarded
                          ? AppColors.statusGreen
                          : AppColors.surfaceSoft)
                      .withValues(alpha: isBoarded ? 0.08 : 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBoarded
                      ? context.tr(AppStrings.checkedInAlready)
                      : context.tr(AppStrings.notBoarded),
                  style: GoogleFonts.prompt(
                    color: isBoarded
                        ? AppColors.statusGreen
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onToggleBoarding,
                icon: Icon(
                  isBoarded
                      ? HugeIcons.strokeRoundedUndo02
                      : HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 18,
                ),
                label: Text(
                  isBoarded
                      ? context.tr(AppStrings.cancelBoarding)
                      : context.tr(AppStrings.confirmBoarding),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isBoarded
                      ? AppColors.textSecondary
                      : AppColors.statusGreen,
                  side: BorderSide(
                    color: isBoarded
                        ? AppColors.divider
                        : AppColors.statusGreen.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
