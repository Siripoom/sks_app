import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/teacher/bus_detail_screen.dart';
import 'package:sks/screens/teacher/teacher_notifications_screen.dart';
import 'package:sks/screens/teacher/teacher_settings_screen.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadBusesForSchool('school_01');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final busProvider = context.watch<BusProvider>();
    final teacherName = appState.currentUser?.name ?? '';
    final buses = busProvider.buses;
    final totalStudents = MockData.children.length;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: context.tr(AppStrings.teacherDashboard),
              hasUnreadNotifications: MockData.notificationHistory.isNotEmpty,
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherNotificationsScreen(),
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
                          builder: (_) => const TeacherSettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(context.tr(AppStrings.tabSettings)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AppStateProvider>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                      side: const BorderSide(color: AppColors.statusRed),
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
                        color: AppColors.accentBlue.withValues(alpha: 0.08),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            MockData.school.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${buses.length} ${context.tr(AppStrings.busCount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SubsectionTitle(title: context.tr(AppStrings.pickupStatus)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppSurfaceCard(
                inner: true,
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(24),
                child: Text(
                  '${buses.length} ${context.tr(AppStrings.buses)} • $totalStudents ${context.tr(AppStrings.students)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...buses.map((bus) {
              final busChildren = MockData.children
                  .where((child) => child.busId == bus.id)
                  .toList();
              return TeacherBusCard(
                bus: bus,
                children: busChildren,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusDetailScreen(bus: bus),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
