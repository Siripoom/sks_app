import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/teacher/bus_detail_screen.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/warm_background.dart';
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
      appBar: AppBar(
        title: const Text(AppStrings.teacherDashboard),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedLogout01),
            onPressed: () {
              context.read<AppStateProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WarmBackground(
              title: AppStrings.teacherDashboard,
              subtitle: teacherName,
              trailing: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  HugeIcons.strokeRoundedSchool01,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: AppStrings.pickupStatus),

            // School info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
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
                      HugeIcons.strokeRoundedSchool01,
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
                          MockData.school.name,
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${buses.length} ${AppStrings.buses} • $totalStudents ${AppStrings.students}',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ...buses.map((bus) {
              final busChildren = MockData.children
                  .where((c) => c.busId == bus.id)
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
