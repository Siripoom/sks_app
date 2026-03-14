import 'package:flutter/material.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/models/bus.dart';

class StatusBadge extends StatelessWidget {
  final BusStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  String _getStatusText() {
    switch (status) {
      case BusStatus.waiting:
        return AppStrings.busWaiting;
      case BusStatus.enRoute:
        return AppStrings.busEnRoute;
      case BusStatus.arrived:
        return AppStrings.busArrived;
    }
  }

  Color _getStatusColor() {
    switch (status) {
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
          fontSize: small ? 12 : 14,
        ),
      ),
    );
  }
}
