import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';

class NotificationTile extends StatelessWidget {
  final String type;
  final String message;
  final String time;

  const NotificationTile({
    super.key,
    required this.type,
    required this.message,
    required this.time,
  });

  IconData _getIcon() {
    switch (type) {
      case 'arrived':
        return HugeIcons.strokeRoundedSchool01;
      case 'boarded':
        return HugeIcons.strokeRoundedBus01;
      case 'departed':
        return HugeIcons.strokeRoundedRoute01;
      case 'system':
        return HugeIcons.strokeRoundedInformationCircle;
      default:
        return HugeIcons.strokeRoundedNotification01;
    }
  }

  Color _getColor() {
    switch (type) {
      case 'arrived':
        return AppColors.statusGreen;
      case 'boarded':
        return AppColors.primary;
      case 'departed':
        return AppColors.accentBlue;
      case 'system':
        return AppColors.statusGrey;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
            ),
            child: Icon(_getIcon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.prompt(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
