import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
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
          SnackBar(
            content: Text(
              context.trArgs(AppStrings.checkedInSuccess, {
                'name': result.child!.name,
              }),
            ),
          ),
        );
        break;
      case DriverQrCheckInStatus.alreadyCheckedIn:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.trArgs(AppStrings.alreadyCheckedIn, {
                'name': result.child!.name,
              }),
            ),
          ),
        );
        break;
      case DriverQrCheckInStatus.notAssigned:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(AppStrings.qrNotAssignedMessage))),
        );
        break;
      case DriverQrCheckInStatus.notFound:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(AppStrings.qrStudentNotFound))),
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
        SnackBar(content: Text(context.tr(AppStrings.unableUpdateBoarding))),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isBoarded
              ? context.trArgs(AppStrings.boardingConfirmed, {
                  'name': result.child!.name,
                })
              : context.trArgs(AppStrings.boardingCanceled, {
                  'name': result.child!.name,
                }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.boardingScreen))),
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
                      Text(
                        context.tr(AppStrings.checkedInAlready),
                        style: const TextStyle(
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
                        label: Text(context.tr(AppStrings.scanQrCode)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showArrivalDialog,
                        icon: const Icon(HugeIcons.strokeRoundedTick01),
                        label: Text(context.tr(AppStrings.markArrived)),
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
        title: Text(context.tr(AppStrings.confirmArrivalTitle)),
        content: Text(context.tr(AppStrings.confirmArrivalMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr(AppStrings.cancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr(AppStrings.confirmBoarding)),
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
      SnackBar(content: Text(context.tr(AppStrings.arrivalMarked))),
    );
  }
}
