import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/core/utils/navigation_utils.dart';
import 'package:sks/models/school.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/subsection_title.dart';
import 'package:sks/widgets/driver/current_stop_card.dart';
import 'package:sks/widgets/driver/stop_progress_list.dart';
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
  bool _loading = false;
  School? _school;

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    final trip = context.read<DriverProvider>().activeTrip;
    if (trip != null && trip.schoolId.isNotEmpty) {
      final school = await context
          .read<IReferenceDataService>()
          .getSchoolById(trip.schoolId);
      if (mounted) setState(() => _school = school);
    }
  }

  Future<void> _startTrip() async {
    setState(() => _loading = true);
    try {
      await context.read<DriverProvider>().startTrip();
    } catch (e) {
      debugPrint('startTrip error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickUp() async {
    setState(() => _loading = true);
    try {
      await context.read<DriverProvider>().markPickedUp();
    } catch (e) {
      debugPrint('markPickedUp error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _loading = true);
    try {
      await context.read<DriverProvider>().skipCurrentStop();
    } catch (e) {
      debugPrint('skipCurrentStop error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeTripAction() async {
    setState(() => _loading = true);
    try {
      await context.read<DriverProvider>().completeTrip();
    } catch (e) {
      debugPrint('completeTrip error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToStop() {
    final stop = context.read<DriverProvider>().currentStop;
    if (stop != null) {
      openGoogleMapsNavigation(stop.lat, stop.lng);
    }
  }

  void _navigateToSchool() {
    if (_school != null) {
      openGoogleMapsNavigation(_school!.lat, _school!.lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final driverId =
        context.watch<AppStateProvider>().currentUser?.referenceId ?? '';
    final notificationService = context.read<INotificationService>();

    final bus = driverProvider.assignedBus;
    final children = driverProvider.assignedChildren;
    final boarded = driverProvider.getChildrenBoarded();
    final total = children.length;
    final routeNumber = bus?.busNumber ?? '';

    final isTripActive = driverProvider.isTripActive;
    final stops = driverProvider.stops;
    final currentStop = driverProvider.currentStop;
    final allDone = driverProvider.allStopsDone;
    final tripCompleted =
        driverProvider.activeTrip?.status == TripStatus.completed;
    final isToHome =
        driverProvider.activeTrip?.round == TripRound.toHome;

    return StreamBuilder<List<Map<String, String>>>(
      stream: notificationService.watchMessagesForDriver(driverId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const [];

        return SingleChildScrollView(
          key: const PageStorageKey('driver-home-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.tr(AppStrings.tabHome),
                notificationCount: messages.length,
                onNotificationTap: widget.onOpenMessages,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TripInfoCard(
                  busNumber: routeNumber,
                  licensePlate: bus?.licensePlate ?? '',
                ),
              ),
              const SizedBox(height: 16),

              // --------------- Action button ---------------
              if (!tripCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActionButton(
                    context,
                    isTripActive: isTripActive,
                    allDone: allDone,
                    hasStops: stops.isNotEmpty,
                  ),
                ),

              // --------------- Current stop card ---------------
              if (isTripActive && currentStop != null && !allDone) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CurrentStopCard(
                    stop: currentStop,
                    stopNumber: driverProvider.currentStopIndex + 1,
                    totalStops: stops.length,
                    onNavigate: _navigateToStop,
                    onPickedUp: _loading ? () {} : _pickUp,
                    onSkip: _loading ? () {} : _skip,
                    isToHome: isToHome,
                  ),
                ),
              ],

              // --------------- All stops done → go to school ---------------
              if (isTripActive && allDone) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppSurfaceCard(
                    inner: true,
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedTick01,
                          color: AppColors.statusGreen,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isToHome
                              ? 'ส่งนักเรียนครบทุกจุดแล้ว'
                              : 'รับนักเรียนครบทุกจุดแล้ว',
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!isToHome && _school != null)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _navigateToSchool,
                              icon: const Icon(
                                HugeIcons.strokeRoundedNavigation01,
                                size: 18,
                              ),
                              label: Text(
                                'นำทางไปโรงเรียน',
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _completeTripAction,
                            icon: const Icon(
                              HugeIcons.strokeRoundedStop,
                              size: 22,
                            ),
                            label: Text(
                              isToHome
                                  ? 'เสร็จสิ้นการเดินทาง'
                                  : 'ถึงโรงเรียนแล้ว',
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
                      ],
                    ),
                  ),
                ),
              ],

              // --------------- Stop progress timeline ---------------
              if (stops.isNotEmpty) ...[
                SubsectionTitle(
                  title:
                      '${isToHome ? 'จุดส่ง' : 'จุดรับ'} (${driverProvider.completedStopsCount}/${stops.length})',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppSurfaceCard(
                    inner: true,
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(24),
                    child: StopProgressList(
                      stops: stops,
                      currentStopIndex: driverProvider.currentStopIndex,
                      isToHome: isToHome,
                    ),
                  ),
                ),
              ],

              // --------------- Student status summary ---------------
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
                      ...children.take(3).map(
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
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required bool isTripActive,
    required bool allDone,
    required bool hasStops,
  }) {
    if (isTripActive) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
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
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: (_loading || !hasStops) ? null : _startTrip,
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
    );
  }
}
