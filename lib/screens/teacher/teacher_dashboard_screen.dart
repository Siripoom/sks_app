import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/school.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/teacher/bus_detail_screen.dart';
import 'package:sks/screens/teacher/teacher_notifications_screen.dart';
import 'package:sks/screens/teacher/teacher_settings_screen.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/subsection_title.dart';
import 'package:sks/widgets/teacher/teacher_bus_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late final Future<void> _bootstrapFuture;
  String _schoolId = '';
  School? _school;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    final appState = context.read<AppStateProvider>();
    final referenceDataService = context.read<IReferenceDataService>();
    final busProvider = context.read<BusProvider>();
    final tripProvider = context.read<TripProvider>();
    final teacherId = appState.currentUser?.referenceId;
    if (teacherId != null) {
      final teacher = await referenceDataService.getTeacherById(teacherId);
      _schoolId = teacher?.schoolId ?? '';
    }

    _school = _schoolId.isEmpty
        ? null
        : await referenceDataService.getSchoolById(_schoolId);
    if (!mounted) {
      return;
    }

    await busProvider.loadAllBuses();
    if (!mounted) {
      return;
    }
    if (_schoolId.isNotEmpty) {
      await tripProvider.loadTripsForSchool(_schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final busProvider = context.watch<BusProvider>();
    final tripProvider = context.watch<TripProvider>();
    final teacherName = appState.currentUser?.name ?? '';
    final busesById = {
      for (final bus in busProvider.buses) bus.id: bus,
    };

    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final notificationService = context.read<INotificationService>();
        final childService = context.read<IChildService>();
        final referenceDataService = context.read<IReferenceDataService>();

        return StreamBuilder<List<Map<String, String>>>(
          stream: notificationService.watchNotificationsForSchool(_schoolId),
          builder: (context, notificationsSnapshot) {
            final notifications = notificationsSnapshot.data ?? const [];

            return StreamBuilder<List<Child>>(
              stream: childService.watchAllChildren(),
              builder: (context, childrenSnapshot) {
                final allChildren = childrenSnapshot.data ?? const <Child>[];
                final trips = tripProvider.trips
                    .where((trip) => trip.schoolId == _schoolId)
                    .toList();

                return FutureBuilder<List<Driver>>(
                  future: referenceDataService.getDriversByIds(
                    trips
                        .map((trip) => busesById[trip.busId]?.driverId ?? '')
                        .where((driverId) => driverId.isNotEmpty),
                  ),
                  builder: (context, driversSnapshot) {
                    final drivers = {
                      for (final driver in driversSnapshot.data ?? const <Driver>[])
                        driver.id: driver,
                    };
                    final assignedStudentCount = trips.fold<int>(
                      0,
                      (sum, trip) => sum + trip.childIds.length,
                    );

                    return Scaffold(
                      body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: context.tr(AppStrings.teacherDashboard),
                              notificationCount: notifications.length,
                              onNotificationTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherNotificationsScreen(
                                      schoolId: _schoolId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TeacherSettingsScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      context.tr(AppStrings.tabSettings),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await context
                                          .read<AppStateProvider>()
                                          .logout();
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.logout,
                                      color: AppColors.statusRed,
                                      size: 18,
                                    ),
                                    label: Text(
                                      context.tr(AppStrings.logout),
                                      style: const TextStyle(
                                        color: AppColors.statusRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.statusRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: AppSurfaceCard(
                                inner: true,
                                padding: const EdgeInsets.all(16),
                                borderRadius: BorderRadius.circular(24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentBlue.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.school_outlined,
                                        color: AppColors.accentBlue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teacherName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _school?.name ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${trips.length} ${context.tr(AppStrings.tripLabel)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SubsectionTitle(
                              title: context.tr(AppStrings.pickupStatus),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: AppSurfaceCard(
                                inner: true,
                                padding: const EdgeInsets.all(16),
                                borderRadius: BorderRadius.circular(24),
                                child: Text(
                                  '${trips.length} ${context.tr(AppStrings.tripLabel)} - $assignedStudentCount ${context.tr(AppStrings.students)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...trips.map((trip) {
                              final bus = busesById[trip.busId];
                              final busChildren = allChildren
                                  .where((child) => trip.childIds.contains(child.id))
                                  .toList();
                              final driver = bus == null
                                  ? null
                                  : drivers[bus.driverId];

                              return TeacherBusCard(
                                trip: trip,
                                bus: bus,
                                driverName: driver?.name ?? '',
                                schoolName: _school?.name ?? '',
                                children: busChildren,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BusDetailScreen(
                                        trip: trip,
                                        bus: bus,
                                        schoolName: _school?.name ?? '',
                                        driverName: driver?.name ?? '',
                                        children: busChildren,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            if (trips.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: AppSurfaceCard(
                                  inner: true,
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Text(
                                    context.tr(AppStrings.noTripToday),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
