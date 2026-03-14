import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/models/bus.dart';

class BusDetailScreen extends StatefulWidget {
  final Bus bus;

  const BusDetailScreen({super.key, required this.bus});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bus.busNumber)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลขรถ',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.bus.busNumber,
                        style: GoogleFonts.prompt(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${AppStrings.childrenOnBus} (${widget.bus.childIds.length} คน)',
              style: GoogleFonts.prompt(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.bus.childIds.length,
              itemBuilder: (context, index) {
                final childId = widget.bus.childIds[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
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
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Text(
                          childId.replaceFirst('child_', ''),
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'เด็ก $childId',
                      style: GoogleFonts.prompt(fontSize: 14),
                    ),
                    trailing: const Icon(
                      HugeIcons.strokeRoundedCheckmarkCircle01,
                      color: AppColors.statusGreen,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (widget.bus.status) {
      case BusStatus.waiting:
        return AppStrings.busWaiting;
      case BusStatus.enRoute:
        return AppStrings.busEnRoute;
      case BusStatus.arrived:
        return AppStrings.busArrived;
    }
  }

  Color _getStatusColor() {
    switch (widget.bus.status) {
      case BusStatus.waiting:
        return AppColors.statusGrey;
      case BusStatus.enRoute:
        return AppColors.statusAmber;
      case BusStatus.arrived:
        return AppColors.statusGreen;
    }
  }
}
