import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class CurrentStopCard extends StatelessWidget {
  final TripStop stop;
  final int stopNumber;
  final int totalStops;
  final VoidCallback onNavigate;
  final VoidCallback onPickedUp;
  final VoidCallback onSkip;
  final bool isToHome;

  const CurrentStopCard({
    super.key,
    required this.stop,
    required this.stopNumber,
    required this.totalStops,
    required this.onNavigate,
    required this.onPickedUp,
    required this.onSkip,
    this.isToHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    '$stopNumber',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.childName,
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (stop.pickupLabel.isNotEmpty)
                      Text(
                        stop.pickupLabel,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$stopNumber/$totalStops',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Navigate button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(HugeIcons.strokeRoundedNavigation01, size: 18),
              label: Text(
                isToHome ? 'นำทางไปจุดส่ง' : 'นำทางไปจุดรับ',
                style: GoogleFonts.prompt(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Picked Up button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onPickedUp,
                    icon: const Icon(HugeIcons.strokeRoundedTick01, size: 18),
                    label: Text(
                      isToHome ? 'ส่งแล้ว' : 'รับแล้ว',
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Skip button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusRed,
                      side: const BorderSide(color: AppColors.statusRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'ข้าม',
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w500),
                    ),
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
