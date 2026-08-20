import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class ChildQrCard extends StatefulWidget {
  final Child child;

  const ChildQrCard({super.key, required this.child});

  @override
  State<ChildQrCard> createState() => _ChildQrCardState();
}

class _ChildQrCardState extends State<ChildQrCard> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _downloadQr() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _qrBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) {
        if (!mounted) return;
        _showSnackBar(
          context.tr(AppStrings.qrSavePermissionDenied),
          isError: true,
        );
        return;
      }

      await Gal.putImageBytes(bytes, name: 'sks_qr_${widget.child.id}');
      if (!mounted) return;
      _showSnackBar(context.tr(AppStrings.qrSavedSuccess));
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(context.tr(AppStrings.qrSaveFailed), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.statusRed : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      inner: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(AppStrings.qrForBoarding),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSaving ? null : _downloadQr,
                tooltip: context.tr(AppStrings.downloadQr),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
              ),
            ],
          ),
          Text(
            widget.child.name,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RepaintBoundary(
              key: _qrBoundaryKey,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: widget.child.qrCodeValue,
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
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              widget.child.qrCodeValue,
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
