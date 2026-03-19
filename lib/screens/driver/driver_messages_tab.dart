import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';

class DriverMessagesTab extends StatelessWidget {
  final VoidCallback onOpenMessages;

  const DriverMessagesTab({super.key, required this.onOpenMessages});

  @override
  Widget build(BuildContext context) {
    final driverId =
        context.watch<AppStateProvider>().currentUser?.referenceId ?? '';
    final notificationService = context.read<INotificationService>();

    return StreamBuilder<List<Map<String, String>>>(
      stream: notificationService.watchMessagesForDriver(driverId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: context.tr(AppStrings.tabMessages),
              notificationCount: messages.length,
              onNotificationTap: onOpenMessages,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                key: const PageStorageKey('driver-messages-list'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isSystem = (msg['sender'] ?? '') == 'ระบบ';
                  return AppSurfaceCard(
                    inner: true,
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSystem
                                ? AppColors.accentBlue.withValues(alpha: 0.08)
                                : AppColors.primary.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            isSystem
                                ? HugeIcons.strokeRoundedInformationCircle
                                : HugeIcons.strokeRoundedUser02,
                            color: isSystem
                                ? AppColors.accentBlue
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    msg['sender'] ?? '',
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isSystem
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    msg['time'] ?? '',
                                    style: GoogleFonts.prompt(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['message'] ?? '',
                                style: GoogleFonts.prompt(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
