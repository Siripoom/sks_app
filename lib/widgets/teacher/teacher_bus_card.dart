import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class TeacherBusCard extends StatelessWidget {
  final Trip trip;
  final Bus? bus;
  final List<Child> children;
  final String driverName;
  final String schoolName;
  final VoidCallback onTap;

  const TeacherBusCard({
    super.key,
    required this.trip,
    required this.bus,
    required this.children,
    required this.driverName,
    required this.schoolName,
    required this.onTap,
  });

  String _getStatusText(BuildContext context) {
    switch (trip.status) {
      case TripStatus.draft:
        return context.tr(AppStrings.busWaiting);
      case TripStatus.active:
        return context.tr(AppStrings.busEnRoute);
      case TripStatus.completed:
        return context.tr(AppStrings.busArrived);
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.draft:
        return AppColors.statusGrey;
      case TripStatus.active:
        return AppColors.statusAmber;
      case TripStatus.completed:
        return AppColors.statusGreen;
      case TripStatus.cancelled:
        return AppColors.statusRed;
    }
  }

  String _roundLabel(BuildContext context) {
    return trip.round == TripRound.toSchool
        ? context.tr(AppStrings.morningRound)
        : context.tr(AppStrings.afternoonRound);
  }

  String _scheduledTime() {
    final scheduled = trip.scheduledStartAt;
    if (scheduled == null) {
      return '--:--';
    }
    final hour = scheduled.hour.toString().padLeft(2, '0');
    final minute = scheduled.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final minutesAway = bus?.estimatedArrival
        ?.difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        inner: true,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'image/school-bus.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bus?.busNumber ?? context.tr(AppStrings.unassignedLabel)} - ${_roundLabel(context)}',
                        style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schoolName,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (minutesAway != null && trip.status == TripStatus.active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$minutesAway ${context.tr(AppStrings.minuteShort)}',
                      style: GoogleFonts.prompt(
                        color: AppColors.statusAmber,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: _scheduledTime(),
                ),
                _MetaChip(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  label: bus?.licensePlate.isNotEmpty == true
                      ? bus!.licensePlate
                      : context.tr(AppStrings.unassignedBus),
                ),
                _MetaChip(
                  icon: HugeIcons.strokeRoundedUser02,
                  label: driverName.isNotEmpty
                      ? '${context.tr(AppStrings.driverLabel)} $driverName'
                      : context.tr(AppStrings.unassignedDriver),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getStatusText(context),
                style: GoogleFonts.prompt(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: children
                  .map(
                    (child) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: child.hasBoarded
                            ? AppColors.statusGreen.withValues(alpha: 0.06)
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.name,
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: child.hasBoarded
                              ? AppColors.statusGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
