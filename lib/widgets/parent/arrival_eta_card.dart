import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class ArrivalEtaCard extends StatelessWidget {
  final int minutesAway;
  final String childName;

  const ArrivalEtaCard({
    super.key,
    required this.minutesAway,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset('image/school-bus.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    childName,
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.arrivingIn} $minutesAway ${AppStrings.minutes}',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$minutesAway ${AppStrings.minuteShort}',
                style: GoogleFonts.prompt(
                  color: AppColors.statusAmber,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
