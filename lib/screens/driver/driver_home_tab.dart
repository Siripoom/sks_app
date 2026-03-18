import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/subsection_title.dart';
import 'package:sks/widgets/driver/trip_info_card.dart';

class DriverHomeTab extends StatefulWidget {
  final VoidCallback onSeeAllStudents;
  final VoidCallback onOpenMessages;

  const DriverHomeTab({
    super.key,
    required this.onSeeAllStudents,
    required this.onOpenMessages,
  });

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  bool _tripStarted = false;

  void _startTrip() => setState(() => _tripStarted = true);

  void _endTrip() {
    context.read<DriverProvider>().markArrived();
    setState(() => _tripStarted = false);
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final bus = driverProvider.assignedBus;
    final children = driverProvider.assignedChildren;
    final boarded = driverProvider.getChildrenBoarded();
    final total = children.length;
    final licensePlate = bus != null
        ? MockData.busLicensePlates[bus.id] ?? ''
        : '';
    final routeNumber = bus?.busNumber ?? '';

    return SingleChildScrollView(
      key: const PageStorageKey('driver-home-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr(AppStrings.tabHome),
            notificationCount: MockData.mockMessages.length,
            onNotificationTap: widget.onOpenMessages,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TripInfoCard(
              busNumber: routeNumber,
              licensePlate: licensePlate,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: _tripStarted
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      label: Text(
                        context.tr(AppStrings.inTransit),
                        style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusGreen,
                        disabledBackgroundColor: AppColors.statusGreen,
                        disabledForegroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startTrip,
                      icon: const Icon(HugeIcons.strokeRoundedPlay, size: 22),
                      label: Text(
                        context.tr(AppStrings.startTrip),
                        style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ),
          SubsectionTitle(title: context.tr(AppStrings.studentStatus)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        HugeIcons.strokeRoundedUserGroup,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$boarded/$total ${context.tr(AppStrings.checkedIn)}',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...children
                      .take(3)
                      .map(
                        (child) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: child.hasBoarded
                                  ? AppColors.statusGreen.withValues(
                                      alpha: 0.08,
                                    )
                                  : AppColors.statusGrey.withValues(
                                      alpha: 0.08,
                                    ),
                            ),
                            child: Icon(
                              child.hasBoarded
                                  ? HugeIcons.strokeRoundedTick01
                                  : HugeIcons.strokeRoundedUser02,
                              size: 16,
                              color: child.hasBoarded
                                  ? AppColors.statusGreen
                                  : AppColors.statusGrey,
                            ),
                          ),
                          title: Text(child.name),
                          dense: true,
                        ),
                      ),
                  if (children.length > 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onSeeAllStudents,
                        child: Text(context.tr(AppStrings.seeAll)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_tripStarted) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _endTrip,
                  icon: const Icon(HugeIcons.strokeRoundedStop, size: 22),
                  label: Text(
                    context.tr(AppStrings.endTrip),
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
