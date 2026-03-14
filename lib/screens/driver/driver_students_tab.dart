import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/widgets/driver/student_pickup_tile.dart';

class DriverStudentsTab extends StatelessWidget {
  const DriverStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final children = driverProvider.assignedChildren;
    final boarded = driverProvider.getChildrenBoarded();
    final total = children.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      HugeIcons.strokeRoundedUserGroup,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$boarded/$total ${AppStrings.checkedIn}',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.emptyList,
                    style: GoogleFonts.prompt(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey('driver-students-list'),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return StudentPickupTile(
                      child: child,
                      onToggle: () => driverProvider.toggleBoarding(child.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
