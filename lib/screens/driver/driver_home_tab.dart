import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/warm_background.dart';
import 'package:sks/widgets/driver/trip_info_card.dart';

class DriverHomeTab extends StatefulWidget {
  final VoidCallback onSeeAllStudents;

  const DriverHomeTab({super.key, required this.onSeeAllStudents});

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
          WarmBackground(
            title:
                '${AppStrings.morningTrip} • ${AppStrings.routeNumber} ${routeNumber.replaceFirst('สาย ', '')}',
            subtitle: AppStrings.goodMorning,
            trailing: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset('image/school-bus.png', fit: BoxFit.contain),
              ),
            ),
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

          // Start/End trip
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
                        AppStrings.inTransit,
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
                        AppStrings.startTrip,
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
          const SizedBox(height: 16),

          // Check-in counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  HugeIcons.strokeRoundedUserGroup,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$boarded/$total ${AppStrings.checkedIn}',
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Student mini-list
          ...children
              .take(3)
              .map(
                (child) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: child.hasBoarded
                          ? AppColors.statusGreen.withValues(alpha: 0.08)
                          : AppColors.statusGrey.withValues(alpha: 0.08),
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
            SectionHeader(
              title: '',
              actionText: AppStrings.seeAll,
              onAction: widget.onSeeAllStudents,
            ),

          const SizedBox(height: 16),

          if (_tripStarted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _endTrip,
                  icon: const Icon(HugeIcons.strokeRoundedStop, size: 22),
                  label: Text(
                    AppStrings.endTrip,
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

          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
