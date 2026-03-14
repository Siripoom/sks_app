import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';

class TeacherBusCard extends StatelessWidget {
  final Bus bus;
  final List<Child> children;
  final VoidCallback onTap;

  const TeacherBusCard({
    super.key,
    required this.bus,
    required this.children,
    required this.onTap,
  });

  String _getStatusText() {
    switch (bus.status) {
      case BusStatus.waiting:
        return AppStrings.busWaiting;
      case BusStatus.enRoute:
        return AppStrings.busEnRoute;
      case BusStatus.arrived:
        return AppStrings.busArrived;
    }
  }

  Color _getStatusColor() {
    switch (bus.status) {
      case BusStatus.waiting:
        return AppColors.statusGrey;
      case BusStatus.enRoute:
        return AppColors.statusAmber;
      case BusStatus.arrived:
        return AppColors.statusGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = MockData.drivers.firstWhere(
      (d) => d.id == bus.driverId,
      orElse: () => MockData.drivers.first,
    );
    final licensePlate = MockData.busLicensePlates[bus.id] ?? '';
    final minutesAway = bus.estimatedArrival
        ?.difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'image/school-bus.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รถ ${bus.busNumber}',
                        style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (minutesAway != null && bus.status == BusStatus.enRoute)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$minutesAway ${AppStrings.minuteShort}',
                      style: GoogleFonts.prompt(
                        color: AppColors.statusAmber,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedCreditCard,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  licensePlate,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  HugeIcons.strokeRoundedUser02,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '${AppStrings.driverLabel} ${driver.name}',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: children
                  .map(
                    (child) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: child.hasBoarded
                            ? AppColors.statusGreen.withValues(alpha: 0.06)
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.name,
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: child.hasBoarded
                              ? AppColors.statusGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
