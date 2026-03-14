import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/widgets/common/section_header.dart';

class ParentScheduleTab extends StatelessWidget {
  const ParentScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final parentProvider = context.watch<ParentProvider>();
    final children = parentProvider.myChildren;

    return SingleChildScrollView(
      key: const PageStorageKey('parent-schedule-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SectionHeader(title: AppStrings.busSchedule),
          ...children.map(
            (child) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        child: Center(
                          child: Text(
                            child.name.isNotEmpty ? child.name[0] : '?',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.name),
                            Text(
                              'รถ ${child.busId.replaceFirst('bus_', 'สาย ')}',
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
                  const SizedBox(height: 14),
                  Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  ...MockData.mockSchedule.map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            schedule['period'] == AppStrings.morningRound
                                ? HugeIcons.strokeRoundedSun01
                                : HugeIcons.strokeRoundedMoon01,
                            color: schedule['period'] == AppStrings.morningRound
                                ? AppColors.statusAmber
                                : AppColors.accentBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(schedule['period']!),
                          const Spacer(),
                          Text(
                            '${schedule['pickup']} - ${schedule['dropoff']}',
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
  }
}
