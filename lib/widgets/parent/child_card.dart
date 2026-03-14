import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/child.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onTap;

  const ChildCard({super.key, required this.child, required this.onTap});

  Color _getStatusColor() {
    if (child.hasArrived) return AppColors.statusGreen;
    if (child.hasBoarded) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  String _getStatusText() {
    if (child.hasArrived) return 'ถึงโรงเรียนแล้ว';
    if (child.hasBoarded) return 'ขึ้นรถแล้ว';
    return 'รอรถ';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text(
              child.name.isNotEmpty ? child.name[0] : '?',
              style: GoogleFonts.prompt(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(child.name),
        subtitle: Text('รถ ${child.busId.replaceFirst('bus_', 'สาย ')}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(),
            style: GoogleFonts.prompt(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
