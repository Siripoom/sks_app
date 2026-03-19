import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class ChildQrCard extends StatelessWidget {
  final Child child;

  const ChildQrCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(AppStrings.qrForBoarding),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            child.name,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: child.qrCodeValue,
                  version: QrVersions.auto,
                  size: 180,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              child.qrCodeValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
