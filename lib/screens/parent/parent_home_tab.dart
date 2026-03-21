import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/utils/geo_utils.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/parent/bus_tracking_screen.dart';
import 'package:sks/screens/parent/parent_notifications_screen.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/subsection_title.dart';
import 'package:sks/widgets/common/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentHomeTab extends StatelessWidget {
  final VoidCallback onOpenSchedule;
  final Widget Function(BuildContext context, Set<Marker> markers)? mapBuilder;

  const ParentHomeTab({
    super.key,
    required this.onOpenSchedule,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final parentProvider = context.watch<ParentProvider>();
    final busProvider = context.watch<BusProvider>();
    final tripProvider = context.watch<TripProvider>();
    final referenceDataService = context.read<IReferenceDataService>();

    final user = appState.currentUser;
    final children = parentProvider.myChildren;
    final assignedChildren = children.where((child) => child.isAssigned).toList();
    final primaryChild = assignedChildren.isNotEmpty ? assignedChildren.first : null;
    final primaryTrip = tripProvider.getTripById(primaryChild?.tripId);
    final primaryBus = _resolveBus(
      busProvider: busProvider,
      trip: primaryTrip,
      child: primaryChild,
    );

    return FutureBuilder<List<School>>(
      future: referenceDataService.getSchools(),
      builder: (context, schoolSnapshot) {
        final schoolsById = {
          for (final school in schoolSnapshot.data ?? const <School>[])
            school.id: school,
        };
        final primarySchool = primaryChild == null
            ? null
            : schoolsById[primaryChild.schoolId];

        return FutureBuilder<Driver?>(
          future: primaryBus == null
              ? Future<Driver?>.value(null)
              : referenceDataService.getDriverById(primaryBus.driverId),
          builder: (context, driverSnapshot) {
            return ParentHomeContent(
              user: user,
              primarySchool: primarySchool,
              children: children,
              notifications: parentProvider.notifications,
              tripsById: {
                for (final trip in tripProvider.trips) trip.id: trip,
              },
              schoolsById: schoolsById,
              busesById: {
                for (final bus in busProvider.buses) bus.id: bus,
              },
              primaryTrip: primaryTrip,
              primaryBus: primaryBus,
              primaryDriver: driverSnapshot.data,
              markers: _buildMarkers(
                children: assignedChildren,
                busProvider: busProvider,
                tripProvider: tripProvider,
                schoolsById: schoolsById,
              ),
              notificationCount: parentProvider.notifications.length,
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParentNotificationsScreen(),
                  ),
                );
              },
              onOpenSchedule: onOpenSchedule,
              onMapTap: primaryChild == null || primaryBus == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusTrackingScreen(
                            busId: primaryBus.id,
                            childName: primaryChild.name,
                            childId: primaryChild.id,
                            schoolId: primaryChild.schoolId,
                            tripId: primaryChild.tripId,
                          ),
                        ),
                      );
                    },
              mapBuilder: mapBuilder,
            );
          },
        );
      },
    );
  }

  static Bus? _resolveBus({
    required BusProvider busProvider,
    required Trip? trip,
    required Child? child,
  }) {
    final busId = trip?.busId ?? child?.busId;
    if (busId == null || busId.isEmpty) {
      return null;
    }
    return busProvider.getBusById(busId);
  }

  Set<Marker> _buildMarkers({
    required List<Child> children,
    required BusProvider busProvider,
    required TripProvider tripProvider,
    required Map<String, School> schoolsById,
  }) {
    final markers = <Marker>{};
    final seenSchools = <String>{};

    for (final child in children) {
      final trip = tripProvider.getTripById(child.tripId);
      final bus = _resolveBus(
        busProvider: busProvider,
        trip: trip,
        child: child,
      );
      if (bus != null) {
        markers.add(
          Marker(
            markerId: MarkerId(bus.id),
            position: LatLng(bus.currentLat, bus.currentLng),
            infoWindow: InfoWindow(title: bus.busNumber),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        );
      }

      final school = schoolsById[child.schoolId];
      if (school != null && seenSchools.add(school.id)) {
        markers.add(
          Marker(
            markerId: MarkerId('school-${school.id}'),
            position: LatLng(school.lat, school.lng),
            infoWindow: InfoWindow(title: school.name),
          ),
        );
      }
    }

    return markers;
  }
}

class ParentHomeContent extends StatelessWidget {
  final AppUser? user;
  final School? primarySchool;
  final List<Child> children;
  final List<Map<String, String>> notifications;
  final Map<String, Trip> tripsById;
  final Map<String, School> schoolsById;
  final Map<String, Bus> busesById;
  final Trip? primaryTrip;
  final Bus? primaryBus;
  final Driver? primaryDriver;
  final Set<Marker> markers;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onOpenSchedule;
  final VoidCallback? onMapTap;
  final Widget Function(BuildContext context, Set<Marker> markers)? mapBuilder;

  const ParentHomeContent({
    super.key,
    required this.user,
    required this.primarySchool,
    required this.children,
    required this.notifications,
    required this.tripsById,
    required this.schoolsById,
    required this.busesById,
    required this.primaryTrip,
    required this.primaryBus,
    required this.primaryDriver,
    required this.markers,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onOpenSchedule,
    this.onMapTap,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final assignedChildren = children.where((child) => child.isAssigned).toList();
    final schedule = _resolveSchedule(
      date: DateTime.now(),
      school: primarySchool,
      trip: primaryTrip,
    );

    return SingleChildScrollView(
      key: const PageStorageKey('parent-home-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr(AppStrings.tabHome),
            notificationCount: notificationCount,
            onNotificationTap: onNotificationTap,
          ),
          const SizedBox(height: 16),
          _buildGreetingCard(context),
          SubsectionTitle(title: context.tr(AppStrings.mapSection)),
          _buildMapSection(context, assignedChildren),
          SubsectionTitle(title: context.tr(AppStrings.todayTrip)),
          _buildTodayTripCard(context: context, schedule: schedule),
          SubsectionTitle(title: context.tr(AppStrings.studentStatus)),
          _buildStudentStatusCard(context),
          SubsectionTitle(
            title: context.tr(AppStrings.todayPickupHistory),
            trailing: IconButton(
              onPressed: onOpenSchedule,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
              ),
              tooltip: context.tr(AppStrings.busSchedule),
            ),
          ),
          _buildHistoryCard(context),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(28),
      child: Row(
        children: [
          UserAvatar(user: user, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr(AppStrings.welcomeGreeting)} ${user?.name ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(AppStrings.readyTrackToday),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, List<Child> assignedChildren) {
    if (assignedChildren.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2E4DE), width: 1.2),
          ),
          child: Text(
            context.tr(AppStrings.noMapToday),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final schoolLatLng = LatLng(
      primarySchool?.lat ?? 13.7563,
      primarySchool?.lng ?? 100.5018,
    );

    final isTripActive = primaryTrip?.status == TripStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onMapTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: mapBuilder != null
                      ? mapBuilder!(context, markers)
                      : AbsorbPointer(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: schoolLatLng,
                              zoom: 12,
                            ),
                            liteModeEnabled: true,
                            markers: markers,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                ),
                // Live tracking overlay banner
                if (isTripActive && onMapTap != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr(AppStrings.busOnTheWay),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            context.tr(AppStrings.tripActiveTracking),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTripCard({
    required BuildContext context,
    required _ResolvedSchedule schedule,
  }) {
    if (primaryBus == null || primaryDriver == null) {
      return _buildInfoCard(context, AppStrings.noTripToday);
    }

    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.directions_bus_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primarySchool?.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${primaryBus!.busNumber} - ${primaryDriver!.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTripTimeRow(
            context: context,
            icon: Icons.pin_drop_outlined,
            iconColor: AppColors.statusAmber,
            label: context.tr(AppStrings.pickupLabel),
            value: context.trArgs(AppStrings.pickupTime, {
              'time': schedule.morningPickup,
            }),
          ),
          const SizedBox(height: 10),
          _buildTripTimeRow(
            context: context,
            icon: Icons.school_outlined,
            iconColor: AppColors.accentBlue,
            label: context.tr(AppStrings.dropOffLabel),
            value: context.trArgs(AppStrings.pickupTime, {
              'time': schedule.morningDropoff,
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callDriver(context, primaryDriver!.phone),
              icon: const Icon(Icons.call_outlined),
              label: Text(context.tr(AppStrings.callDriver)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatusCard(BuildContext context) {
    if (children.isEmpty) {
      return _buildInfoCard(context, AppStrings.noStudentData);
    }

    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            _buildStudentStatusRow(context, children[i]),
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentStatusRow(BuildContext context, Child child) {
    final status = _resolveStudentStatus(child);
    final boardedTime = _findBoardingTime(child.name);

    // Show ETA info when trip is active and child hasn't boarded yet
    final isTripActive = primaryTrip?.status == TripStatus.active;
    final busLat = primaryBus?.currentLat ?? 0.0;
    final busLng = primaryBus?.currentLng ?? 0.0;
    int? etaMinutes;
    if (isTripActive && !child.hasBoarded && !child.hasArrived &&
        child.pickupLat != null && child.pickupLng != null &&
        busLat != 0 && busLng != 0) {
      etaMinutes = estimateMinutesBetween(
        busLat, busLng, child.pickupLat!, child.pickupLng!,
      );
    }
    final hasEta = etaMinutes != null;

    return Row(
      children: [
        // Avatar with ETA badge overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            ChildAvatar(
              child: child,
              size: 46,
              backgroundColor: status.color.withValues(alpha: 0.12),
              textColor: status.color,
              fontSize: 16,
            ),
            if (hasEta)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${etaMinutes}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.tr(status.label),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasEta
                          ? context.trArgs(AppStrings.busArrivingSoon, {
                              'minutes': etaMinutes.toString(),
                            })
                          : '${context.tr(AppStrings.boardingTime)} $boardedTime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasEta ? AppColors.primary : null,
                        fontWeight: hasEta ? FontWeight.w500 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    if (children.isEmpty) {
      return _buildInfoCard(context, AppStrings.noHistoryToday);
    }

    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            _buildHistoryItem(context, children[i]),
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Child child) {
    final trip = tripsById[child.tripId];
    final school = schoolsById[child.schoolId];
    final bus = busesById[trip?.busId ?? child.busId];
    final schedule = _resolveSchedule(
      date: DateTime.now(),
      school: school,
      trip: trip,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChildAvatar(
              child: child,
              size: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              textColor: AppColors.primary,
              fontSize: 15,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.isAssigned
                        ? '${bus?.busNumber ?? context.tr(AppStrings.notAssigned)} - ${school?.name ?? child.schoolName}'
                        : context.tr(AppStrings.waitingForRoute),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!child.isAssigned)
          Text(
            '${context.tr(AppStrings.pickupLocation)}: ${child.pickupLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (!schedule.hasService)
          Text(
            context.tr(AppStrings.noServiceToday),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          _buildTripTimeRow(
            context: context,
            icon: Icons.wb_sunny_outlined,
            iconColor: AppColors.statusAmber,
            label: context.tr(AppStrings.morningRound),
            value: context.trArgs(AppStrings.scheduleTimeRange, {
              'pickup': schedule.morningPickup,
              'dropoff': schedule.morningDropoff,
            }),
          ),
          const SizedBox(height: 8),
          _buildTripTimeRow(
            context: context,
            icon: Icons.nights_stay_outlined,
            iconColor: AppColors.accentBlue,
            label: context.tr(AppStrings.afternoonRound),
            value: context.trArgs(AppStrings.scheduleTimeRange, {
              'pickup': schedule.eveningPickup,
              'dropoff': schedule.eveningDropoff,
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildTripTimeRow({
    required BuildContext context,
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
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String key) {
    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Text(
        context.tr(key),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  _ResolvedSchedule _resolveSchedule({
    required DateTime date,
    required School? school,
    required Trip? trip,
  }) {
    final sameDay = _isSameDay(trip?.serviceDate, date);
    final weekdayHasService =
        date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;

    var morningPickup = school?.morningPickup.isNotEmpty == true
        ? school!.morningPickup
        : '--:--';
    var morningDropoff = school?.morningDropoff.isNotEmpty == true
        ? school!.morningDropoff
        : '--:--';
    var eveningPickup = school?.eveningPickup.isNotEmpty == true
        ? school!.eveningPickup
        : '--:--';
    var eveningDropoff = school?.eveningDropoff.isNotEmpty == true
        ? school!.eveningDropoff
        : '--:--';

    if (sameDay && trip?.scheduledStartAt != null) {
      final tripTime = _formatTime(trip!.scheduledStartAt!);
      if (trip.round == TripRound.toSchool) {
        morningPickup = tripTime;
      } else {
        eveningPickup = tripTime;
      }
    }

    return _ResolvedSchedule(
      hasService: sameDay || weekdayHasService,
      morningPickup: morningPickup,
      morningDropoff: morningDropoff,
      eveningPickup: eveningPickup,
      eveningDropoff: eveningDropoff,
    );
  }

  _StudentStatus _resolveStudentStatus(Child child) {
    if (!child.isAssigned) {
      return const _StudentStatus(
        AppStrings.waitingForRoute,
        AppColors.textSecondary,
      );
    }
    if (child.hasArrived) {
      return const _StudentStatus(
        AppStrings.arrivedAtSchoolStatus,
        AppColors.statusGreen,
      );
    }
    if (child.hasBoarded) {
      return const _StudentStatus(AppStrings.boardedStatus, AppColors.primary);
    }
    return const _StudentStatus(
      AppStrings.waitingToBoard,
      AppColors.statusAmber,
    );
  }

  String _findBoardingTime(String childName) {
    for (final entry in notifications) {
      final message = entry['message'] ?? '';
      final time = entry['time'] ?? '--:--';
      if (message.contains(childName) && message.contains('ขึ้นรถ')) {
        return time;
      }
    }
    return '--:--';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDay(DateTime? left, DateTime right) {
    if (left == null) {
      return false;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<void> _callDriver(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri) && await launchUrl(uri)) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final message = context
        .tr(AppStrings.driverPhoneFallback)
        .replaceAll('{phone}', phone);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }
}

class _ResolvedSchedule {
  final bool hasService;
  final String morningPickup;
  final String morningDropoff;
  final String eveningPickup;
  final String eveningDropoff;

  const _ResolvedSchedule({
    required this.hasService,
    required this.morningPickup,
    required this.morningDropoff,
    required this.eveningPickup,
    required this.eveningDropoff,
  });
}

class _StudentStatus {
  final String label;
  final Color color;

  const _StudentStatus(this.label, this.color);
}
