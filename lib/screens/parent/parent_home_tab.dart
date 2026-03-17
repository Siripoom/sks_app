import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/parent/bus_tracking_screen.dart';
import 'package:sks/screens/parent/parent_notifications_screen.dart';
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

    final user = appState.currentUser;
    final children = parentProvider.myChildren;
    final assignedChildren = children.where((child) => child.isAssigned).toList();
    final primaryChild = assignedChildren.isNotEmpty ? assignedChildren.first : null;
    final primaryBus = primaryChild?.busId != null
        ? busProvider.getBusById(primaryChild!.busId!)
        : null;
    final primaryDriver = primaryBus != null
        ? _findDriverByBusId(primaryBus.id)
        : null;

    return ParentHomeContent(
      user: user,
      children: children,
      notifications: parentProvider.notifications,
      primaryBus: primaryBus,
      primaryDriver: primaryDriver,
      markers: _buildMarkers(assignedChildren, busProvider),
      hasUnreadNotifications: parentProvider.notifications.isNotEmpty,
      onNotificationTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentNotificationsScreen()),
        );
      },
      onOpenSchedule: onOpenSchedule,
      onMapTap: primaryChild == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusTrackingScreen(
                    busId: primaryChild.busId!,
                    childName: primaryChild.name,
                  ),
                ),
              );
            },
      mapBuilder: mapBuilder,
    );
  }

  Driver? _findDriverByBusId(String busId) {
    try {
      return MockData.drivers.firstWhere((driver) => driver.busId == busId);
    } catch (_) {
      return null;
    }
  }

  Set<Marker> _buildMarkers(List<Child> children, BusProvider busProvider) {
    final markers = <Marker>{};
    for (final child in children) {
      if (child.busId == null) {
        continue;
      }
      final bus = busProvider.getBusById(child.busId!);
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
    }
    markers.add(
      const Marker(
        markerId: MarkerId('school'),
        position: LatLng(13.7563, 100.5018),
      ),
    );
    return markers;
  }
}

class ParentHomeContent extends StatelessWidget {
  final AppUser? user;
  final List<Child> children;
  final List<Map<String, String>> notifications;
  final Bus? primaryBus;
  final Driver? primaryDriver;
  final Set<Marker> markers;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationTap;
  final VoidCallback onOpenSchedule;
  final VoidCallback? onMapTap;
  final Widget Function(BuildContext context, Set<Marker> markers)? mapBuilder;

  const ParentHomeContent({
    super.key,
    required this.user,
    required this.children,
    required this.notifications,
    required this.primaryBus,
    required this.primaryDriver,
    required this.markers,
    required this.hasUnreadNotifications,
    required this.onNotificationTap,
    required this.onOpenSchedule,
    this.onMapTap,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final assignedChildren = children.where((child) => child.isAssigned).toList();
    final schedule = _resolveTodaySchedule();

    return SingleChildScrollView(
      key: const PageStorageKey('parent-home-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr(AppStrings.tabHome),
            hasUnreadNotifications: hasUnreadNotifications,
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
          _buildHistoryCard(context, schedule),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onMapTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: mapBuilder != null
                ? mapBuilder!(context, markers)
                : AbsorbPointer(
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(13.7563, 100.5018),
                        zoom: 12,
                      ),
                      liteModeEnabled: true,
                      markers: markers,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
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
                      MockData.school.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${primaryBus!.busNumber} • ${primaryDriver!.name}',
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
            label: 'Pickup',
            value: '${schedule.morningPickup} น.',
          ),
          const SizedBox(height: 10),
          _buildTripTimeRow(
            context: context,
            icon: Icons.school_outlined,
            iconColor: AppColors.accentBlue,
            label: 'Drop off',
            value: '${schedule.morningDropoff} น.',
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

    return Row(
      children: [
        ChildAvatar(
          child: child,
          size: 46,
          backgroundColor: status.color.withValues(alpha: 0.12),
          textColor: status.color,
          fontSize: 16,
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
                  Text(
                    '${context.tr(AppStrings.boardingTime)} $boardedTime',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, _ResolvedSchedule schedule) {
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
            _buildHistoryItem(context, children[i], schedule),
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

  Widget _buildHistoryItem(
    BuildContext context,
    Child child,
    _ResolvedSchedule schedule,
  ) {
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
                  Text(child.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    child.isAssigned
                        ? 'รถ ${child.busId!.replaceFirst('bus_', 'สาย ')}'
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
            value:
                'รับ ${schedule.morningPickup} น. • ส่ง ${schedule.morningDropoff} น.',
          ),
          const SizedBox(height: 8),
          _buildTripTimeRow(
            context: context,
            icon: Icons.nights_stay_outlined,
            iconColor: AppColors.accentBlue,
            label: context.tr(AppStrings.afternoonRound),
            value:
                'รับ ${schedule.eveningPickup} น. • ส่ง ${schedule.eveningDropoff} น.',
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
        Text(value, style: Theme.of(context).textTheme.bodySmall),
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

  _ResolvedSchedule _resolveTodaySchedule() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return const _ResolvedSchedule.noService();
    }

    String morningPickup = '--:--';
    String morningDropoff = '--:--';
    String eveningPickup = '--:--';
    String eveningDropoff = '--:--';

    for (final schedule in MockData.mockSchedule) {
      if (schedule['period'] == AppStrings.morningRound) {
        morningPickup = schedule['pickup'] ?? morningPickup;
        morningDropoff = schedule['dropoff'] ?? morningDropoff;
      }
      if (schedule['period'] == AppStrings.afternoonRound) {
        eveningPickup = schedule['pickup'] ?? eveningPickup;
        eveningDropoff = schedule['dropoff'] ?? eveningDropoff;
      }
    }

    return _ResolvedSchedule(
      hasService: true,
      morningPickup: morningPickup,
      morningDropoff: morningDropoff,
      eveningPickup: eveningPickup,
      eveningDropoff: eveningDropoff,
    );
  }

  _StudentStatus _resolveStudentStatus(Child child) {
    if (!child.isAssigned) {
      return const _StudentStatus(AppStrings.waitingForRoute, AppColors.textSecondary);
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
    return const _StudentStatus(AppStrings.waitingToBoard, AppColors.statusAmber);
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

  const _ResolvedSchedule.noService()
    : hasService = false,
      morningPickup = '--:--',
      morningDropoff = '--:--',
      eveningPickup = '--:--',
      eveningDropoff = '--:--';
}

class _StudentStatus {
  final String label;
  final Color color;

  const _StudentStatus(this.label, this.color);
}
