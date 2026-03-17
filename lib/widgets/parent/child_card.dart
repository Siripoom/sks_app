import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onTap;

  const ChildCard({super.key, required this.child, required this.onTap});

  Color _getStatusColor() {
    if (!child.isAssigned) {
      return AppColors.textSecondary;
    }
    if (child.hasArrived) {
      return AppColors.statusGreen;
    }
    if (child.hasBoarded) {
      return AppColors.statusAmber;
    }
    return AppColors.statusRed;
  }

  String _getStatusText() {
    if (!child.isAssigned) {
      return 'รอจัดสาย';
    }
    if (child.hasArrived) {
      return 'ถึงโรงเรียนแล้ว';
    }
    if (child.hasBoarded) {
      return 'ขึ้นรถแล้ว';
    }
    return 'รอรถ';
  }

  String _getSubtitle() {
    if (!child.isAssigned) {
      return child.pickupLabel;
    }
    return 'รถ ${child.busId!.replaceFirst('bus_', 'สาย ')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
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
          child: ChildAvatar(
            child: child,
            size: 48,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            textColor: AppColors.primary,
          ),
        ),
        title: Text(child.name),
        subtitle: Text(
          _getSubtitle(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
