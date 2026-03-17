import 'package:flutter/material.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/status_badge.dart';

class BusSummaryCard extends StatelessWidget {
  final Bus bus;
  final int totalChildren;
  final VoidCallback onTap;

  const BusSummaryCard({
    super.key,
    required this.bus,
    required this.totalChildren,
    required this.onTap,
  });

  int get boardedCount => bus.childIds.length;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              bus.busNumber.replaceFirst('สาย ', ''),
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          bus.busNumber,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '$boardedCount/$totalChildren คน',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: StatusBadge(status: bus.status, small: true),
      ),
    );
  }
}
