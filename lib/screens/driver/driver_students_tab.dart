import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/screens/common/qr_scanner_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/driver/student_pickup_tile.dart';

class DriverStudentsTab extends StatelessWidget {
  final VoidCallback onOpenMessages;

  const DriverStudentsTab({super.key, required this.onOpenMessages});

  Future<void> _scanQr(BuildContext context) async {
    final qrCodeValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (!context.mounted || qrCodeValue == null || qrCodeValue.isEmpty) {
      return;
    }

    final result = await context.read<DriverProvider>().checkInByQr(
      qrCodeValue,
    );
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    switch (result.status) {
      case DriverQrCheckInStatus.success:
        messenger.showSnackBar(
          SnackBar(content: Text('เช็กอิน ${result.child!.name} สำเร็จ')),
        );
        break;
      case DriverQrCheckInStatus.alreadyCheckedIn:
        messenger.showSnackBar(
          SnackBar(content: Text('${result.child!.name} เช็กอินแล้ว')),
        );
        break;
      case DriverQrCheckInStatus.notAssigned:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('QR นี้ไม่ใช่นักเรียนในสายรถที่คุณรับผิดชอบ'),
          ),
        );
        break;
      case DriverQrCheckInStatus.notFound:
        messenger.showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลนักเรียนจาก QR นี้')),
        );
        break;
    }
  }

  Future<void> _toggleBoarding(BuildContext context, Child child) async {
    final result = await context.read<DriverProvider>().toggleBoarding(
      child.id,
    );

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (!result.success || result.child == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ไม่สามารถอัปเดตสถานะขึ้นรถได้')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isBoarded
              ? 'ยืนยัน ${result.child!.name} ขึ้นรถแล้ว'
              : 'ยกเลิกสถานะขึ้นรถของ ${result.child!.name} แล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final children = driverProvider.assignedChildren;
    final boarded = driverProvider.getChildrenBoarded();
    final total = children.length;

    return Column(
      children: [
        SectionHeader(
          title: context.tr(AppStrings.tabStudents),
          hasUnreadNotifications: true,
          onNotificationTap: onOpenMessages,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AppSurfaceCard(
                inner: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    const Icon(
                      HugeIcons.strokeRoundedUserGroup,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$boarded/$total ${context.tr(AppStrings.checkedIn)}',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _scanQr(context),
                icon: const Icon(HugeIcons.strokeRoundedQrCode),
                label: const Text('Scan QR'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Text(
                    context.tr(AppStrings.emptyList),
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
                      key: ValueKey('${child.id}_${child.hasBoarded}'),
                      child: child,
                      onToggleBoarding: () => _toggleBoarding(context, child),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
