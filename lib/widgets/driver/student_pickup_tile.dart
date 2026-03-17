import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';

class StudentPickupTile extends StatelessWidget {
  final Child child;
  final VoidCallback onToggleBoarding;

  const StudentPickupTile({
    super.key,
    required this.child,
    required this.onToggleBoarding,
  });

  @override
  Widget build(BuildContext context) {
    final isBoarded = child.hasBoarded;

    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBoarded
                      ? AppColors.statusGreen.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.08),
                ),
                child: ChildAvatar(
                  child: child,
                  size: 42,
                  backgroundColor: isBoarded
                      ? AppColors.statusGreen.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.08),
                  textColor: isBoarded
                      ? AppColors.statusGreen
                      : AppColors.primary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name),
                    Text(
                      child.busId != null
                          ? 'รถ ${child.busId!.replaceFirst('bus_', 'สาย ')}'
                          : child.pickupLabel,
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      (isBoarded ? AppColors.statusGreen : AppColors.surfaceSoft)
                          .withValues(alpha: isBoarded ? 0.08 : 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBoarded
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedQrCode,
                      color: isBoarded
                          ? AppColors.statusGreen
                          : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBoarded ? 'เช็กอินแล้ว' : 'รอสแกน QR',
                      style: GoogleFonts.prompt(
                        color: isBoarded
                            ? AppColors.statusGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onToggleBoarding,
              icon: Icon(
                isBoarded
                    ? HugeIcons.strokeRoundedUndo02
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 18,
              ),
              label: Text(isBoarded ? 'ยกเลิกขึ้นรถ' : 'ยืนยันขึ้นรถ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isBoarded
                    ? AppColors.textSecondary
                    : AppColors.statusGreen,
                side: BorderSide(
                  color: isBoarded
                      ? AppColors.divider
                      : AppColors.statusGreen.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
