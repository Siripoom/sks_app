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

class BusDetailScreen extends StatelessWidget {
  final Trip trip;
  final Bus? bus;
  final String schoolName;
  final String driverName;
  final List<Child> children;

  const BusDetailScreen({
    super.key,
    required this.trip,
    required this.bus,
    required this.schoolName,
    required this.driverName,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bus?.busNumber ?? context.tr(AppStrings.tripLabel)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _detailRow(
                    label: context.tr(AppStrings.tripLabel),
                    value: _tripLabel(context),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: context.tr(AppStrings.schoolLabel),
                    value: schoolName,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: context.tr(AppStrings.busLabel),
                    value: bus?.busNumber ?? context.tr(AppStrings.notAssigned),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: context.tr(AppStrings.plateLabel),
                    value: bus?.licensePlate ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: context.tr(AppStrings.driverLabel),
                    value: driverName.isNotEmpty ? driverName : '-',
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: context.tr(AppStrings.busStatus),
                    value: _statusText(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${context.tr(AppStrings.childrenOnBus)} (${children.length})',
              style: GoogleFonts.prompt(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              AppSurfaceCard(
                inner: true,
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(24),
                child: Text(
                  context.tr(AppStrings.noAssignedStudentsYet),
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...children.map(
                (child) => AppSurfaceCard(
                  inner: true,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(24),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: child.hasBoarded
                            ? AppColors.statusGreen.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        child.hasBoarded
                            ? HugeIcons.strokeRoundedCheckmarkCircle01
                            : HugeIcons.strokeRoundedUser02,
                        color: child.hasBoarded
                            ? AppColors.statusGreen
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      child.name,
                      style: GoogleFonts.prompt(fontSize: 14),
                    ),
                    subtitle: Text(
                      child.pickupLabel,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _tripLabel(BuildContext context) {
    final roundLabel = trip.round == TripRound.toSchool
        ? context.tr(AppStrings.morningRound)
        : context.tr(AppStrings.afternoonRound);
    final date = trip.serviceDate;
    final time = trip.scheduledStartAt == null
        ? '--:--'
        : '${trip.scheduledStartAt!.hour.toString().padLeft(2, '0')}:${trip.scheduledStartAt!.minute.toString().padLeft(2, '0')}';
    return '$roundLabel - ${date.day}/${date.month}/${date.year} - $time';
  }

  String _statusText(BuildContext context) {
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
}
