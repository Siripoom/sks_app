import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/widgets/driver/boarding_child_tile.dart';

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key});

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.boardingScreen)),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
              ),
            ),
          ),
          // Children List
          Expanded(
            child: ListView.builder(
              itemCount: driverProvider.assignedChildren.length,
              itemBuilder: (context, index) {
                final child = driverProvider.assignedChildren[index];
                return BoardingChildTile(
                  child: child,
                  onToggle: () {
                    driverProvider.toggleBoarding(child.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showArrivalDialog() {
    final driverProvider = context.read<DriverProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการมาถึง'),
        content: const Text('รถของคุณถึงโรงเรียนแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              await driverProvider.markArrived();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ทำเครื่องหมายว่าถึงโรงเรียนแล้ว'),
                  ),
                );
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }
}
