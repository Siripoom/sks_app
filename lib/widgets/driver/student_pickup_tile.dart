import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/models/child.dart';

class StudentPickupTile extends StatelessWidget {
  final Child child;
  final VoidCallback onToggle;

  const StudentPickupTile({
    super.key,
    required this.child,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isBoarded = child.hasBoarded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBoarded
                  ? AppColors.statusGreen.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                child.name.isNotEmpty ? child.name[0] : '?',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isBoarded ? AppColors.statusGreen : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name),
                Text(
                  'รถ ${child.busId.replaceFirst('bus_', 'สาย ')}',
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          isBoarded
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: AppColors.statusGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.checkedIn,
                        style: GoogleFonts.prompt(
                          color: AppColors.statusGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: onToggle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(AppStrings.pickUpAction),
                ),
        ],
      ),
    );
  }
}
