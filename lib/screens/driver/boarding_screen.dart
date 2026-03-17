import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/models/child.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/screens/common/qr_scanner_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/driver/boarding_child_tile.dart';

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key});

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  Future<void> _scanQr() async {
    final qrCodeValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (!mounted || qrCodeValue == null || qrCodeValue.isEmpty) {
      return;
    }

    final result = await context.read<DriverProvider>().checkInByQr(
      qrCodeValue,
    );
    if (!mounted) {
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

  Future<void> _toggleBoarding(Child child) async {
    final result = await context.read<DriverProvider>().toggleBoarding(
      child.id,
    );

    if (!mounted) {
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

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.boardingScreen)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ขึ้นรถแล้ว',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${driverProvider.getChildrenBoarded()}/${driverProvider.assignedChildren.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusGreen,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _scanQr,
                        icon: const Icon(HugeIcons.strokeRoundedQrCode),
                        label: const Text('สแกน QR'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showArrivalDialog,
                        icon: const Icon(HugeIcons.strokeRoundedTick01),
                        label: const Text('ถึงโรงเรียน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: driverProvider.assignedChildren.length,
              itemBuilder: (context, index) {
                final child = driverProvider.assignedChildren[index];
                return BoardingChildTile(
                  key: ValueKey('${child.id}_${child.hasBoarded}'),
                  child: child,
                  onToggleBoarding: () => _toggleBoarding(child),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showArrivalDialog() async {
    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการมาถึง'),
        content: const Text('รถของคุณถึงโรงเรียนแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (shouldConfirm != true || !mounted) {
      return;
    }

    await context.read<DriverProvider>().markArrived();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ทำเครื่องหมายว่าถึงโรงเรียนแล้ว')),
    );
  }
}
