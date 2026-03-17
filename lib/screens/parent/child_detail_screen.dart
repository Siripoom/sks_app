import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/models/child.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/screens/parent/bus_tracking_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';
import 'package:sks/widgets/parent/child_qr_card.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadBusesForSchool('school_01');
  }

  String _getStatusText() {
    if (!widget.child.isAssigned) {
      return 'รอจัดสาย';
    }
    if (widget.child.hasArrived) {
      return 'ถึงโรงเรียนแล้ว';
    }
    if (widget.child.hasBoarded) {
      return 'ขึ้นรถแล้ว';
    }
    return 'รอรถ';
  }

  Color _getStatusColor() {
    if (!widget.child.isAssigned) {
      return AppColors.textSecondary;
    }
    if (widget.child.hasArrived) {
      return AppColors.statusGreen;
    }
    if (widget.child.hasBoarded) {
      return AppColors.statusAmber;
    }
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.childDetail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ChildAvatar(
                child: widget.child,
                size: 100,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                textColor: AppColors.primary,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.child.name,
                style: GoogleFonts.prompt(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.busStatus,
                    style: GoogleFonts.prompt(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: GoogleFonts.prompt(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.busNumber,
                              style: GoogleFonts.prompt(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.child.isAssigned
                                  ? widget.child.busId!.replaceFirst(
                                      'bus_',
                                      'สาย ',
                                    )
                                  : 'ยังไม่มีการกำหนดสาย',
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'จุดรับส่ง',
                              style: GoogleFonts.prompt(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.child.pickupLabel,
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ChildQrCard(child: widget.child),
            const SizedBox(height: 24),
            if (widget.child.isAssigned)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusTrackingScreen(
                          busId: widget.child.busId!,
                          childName: widget.child.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(HugeIcons.strokeRoundedMapPin),
                  label: Text(
                    AppStrings.trackBus,
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              AppSurfaceCard(
                inner: true,
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(20),
                child: const Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedInformationCircle,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ยังไม่สามารถติดตามรถได้จนกว่าจะมีการกำหนดสายรถ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              AppStrings.notificationHistory,
              style: GoogleFonts.prompt(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppSurfaceCard(
                inner: true,
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.isAssigned
                          ? 'ลูกไปถึงโรงเรียนแล้ว เวลา 8:00 น.'
                          : 'รอการกำหนดสายรถจากแอดมิน',
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.child.isAssigned
                          ? 'รถสาย 1 ออกเดินทางแล้ว'
                          : 'เมื่อมีการกำหนดสายแล้ว ระบบจะแจ้งเตือนในหน้านี้',
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
    );
  }
}
