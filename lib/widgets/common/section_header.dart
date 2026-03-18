import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.notificationCount = 0,
    this.onNotificationTap,
  });

  String get _badgeLabel {
    if (notificationCount > 99) {
      return '99+';
    }
    return notificationCount.toString();
  }

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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.statusAmber.withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusAmber.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.statusAmber,
                      size: 24,
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.statusRed,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.textOnPrimary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _badgeLabel,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnPrimary,
                            height: 1,
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
