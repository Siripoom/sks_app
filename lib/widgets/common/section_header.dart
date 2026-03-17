import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: BorderRadius.circular(28),
      color: AppColors.primaryDark,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onNotificationTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      HugeIcons.strokeRoundedNotification01,
                      color: AppColors.textOnPrimary,
                      size: 22,
                    ),
                  ),
                  if (hasUnreadNotifications)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.statusRed,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.textOnPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
