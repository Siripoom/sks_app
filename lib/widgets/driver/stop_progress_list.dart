import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/trip_stop.dart';

class StopProgressList extends StatelessWidget {
  final List<TripStop> stops;
  final int currentStopIndex;
  final bool isToHome;

  const StopProgressList({
    super.key,
    required this.stops,
    required this.currentStopIndex,
    this.isToHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++) _buildStopTile(context, i),
      ],
    );
  }

  Widget _buildStopTile(BuildContext context, int index) {
    final stop = stops[index];
    final isCurrent = index == currentStopIndex;
    final isLast = index == stops.length - 1;

    final Color circleColor;
    final IconData circleIcon;

    switch (stop.status) {
      case TripStopStatus.pickedUp:
        circleColor = AppColors.statusGreen;
        circleIcon = Icons.check;
      case TripStopStatus.skipped:
        circleColor = AppColors.statusRed;
        circleIcon = Icons.close;
      case TripStopStatus.approaching:
      case TripStopStatus.arrived:
        circleColor = AppColors.primary;
        circleIcon = Icons.directions_bus;
      case TripStopStatus.pending:
        if (isCurrent) {
          circleColor = AppColors.primary;
          circleIcon = Icons.directions_bus;
        } else {
          circleColor = AppColors.statusGrey;
          circleIcon = Icons.circle_outlined;
        }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor.withValues(alpha: isCurrent ? 0.2 : 0.1),
                    border: isCurrent
                        ? Border.all(color: circleColor, width: 2)
                        : null,
                  ),
                  child: Icon(circleIcon, size: 14, color: circleColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: stop.isDone
                          ? AppColors.statusGreen.withValues(alpha: 0.3)
                          : AppColors.statusGrey.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.childName,
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: isCurrent
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (stop.pickupLabel.isNotEmpty)
                    Text(
                      stop.pickupLabel,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (stop.isDone)
                    Text(
                      stop.status == TripStopStatus.pickedUp
                          ? (isToHome ? 'ส่งแล้ว' : 'รับแล้ว')
                          : 'ข้าม',
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: stop.status == TripStopStatus.pickedUp
                            ? AppColors.statusGreen
                            : AppColors.statusRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Sequence badge
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
