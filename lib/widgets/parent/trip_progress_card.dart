import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class TripProgressCard extends StatelessWidget {
  final String currentlyPickingUpName;
  final int stopsRemaining;
  final int estimatedMinutes;
  final TripStopStatus? myChildStatus;
  final String? myChildName;
  final int currentStopNumber;
  final int totalStops;
  final bool isToHome;

  const TripProgressCard({
    super.key,
    required this.currentlyPickingUpName,
    required this.stopsRemaining,
    required this.estimatedMinutes,
    this.myChildStatus,
    this.myChildName,
    required this.currentStopNumber,
    required this.totalStops,
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
          // Currently picking up
          if (currentlyPickingUpName.isNotEmpty) ...[
            _buildRow(
              icon: Icons.directions_bus,
              iconColor: AppColors.primary,
              label: context.tr(isToHome
                  ? AppStrings.currentlyDroppingOff
                  : AppStrings.currentlyPickingUp),
              value: '$currentlyPickingUpName (${context.trArgs(AppStrings.stopProgress, {
                    'current': currentStopNumber.toString(),
                    'total': totalStops.toString(),
                  })})',
            ),
            const SizedBox(height: 12),
          ],

          // Stops remaining
          if (stopsRemaining > 0) ...[
            _buildRow(
              icon: Icons.pin_drop_outlined,
              iconColor: AppColors.statusAmber,
              label: context.tr(isToHome
                  ? AppStrings.stopsBeforeDropOff
                  : AppStrings.stopsBeforeYou),
              value: context.trArgs(AppStrings.stopsRemaining, {
                'count': stopsRemaining.toString(),
              }),
            ),
            const SizedBox(height: 12),
          ],

          // ETA
          if (estimatedMinutes >= 0) ...[
            _buildRow(
              icon: Icons.access_time,
              iconColor: AppColors.accentBlue,
              label: context.tr(AppStrings.etaApprox),
              value: context.trArgs(AppStrings.etaMinutes, {
                'minutes': estimatedMinutes.toString(),
              }),
            ),
            const SizedBox(height: 12),
          ],

          // Child status
          if (myChildStatus != null && myChildName != null)
            _buildStatusBadge(context),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.prompt(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (labelKey, color) = switch (myChildStatus!) {
      TripStopStatus.pending => (isToHome ? AppStrings.waitingToDropOff : AppStrings.waitingToPickup, AppColors.statusAmber),
      TripStopStatus.approaching => (AppStrings.busComingStatus, AppColors.primary),
      TripStopStatus.arrived => (AppStrings.stopStatusArrived, AppColors.accentBlue),
      TripStopStatus.pickedUp => (isToHome ? AppStrings.droppedOffStatus : AppStrings.stopStatusPickedUp, AppColors.statusGreen),
      TripStopStatus.skipped => (isToHome ? AppStrings.skippedDropOff : AppStrings.stopStatusSkipped, AppColors.statusRed),
    };

    return Row(
      children: [
        const Icon(Icons.child_care, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(
          '$myChildName: ',
          style: GoogleFonts.prompt(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.tr(labelKey),
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
