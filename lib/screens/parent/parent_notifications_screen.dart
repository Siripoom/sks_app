import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/widgets/common/warm_background.dart';
import 'package:sks/widgets/parent/notification_tile.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<ParentProvider>().notifications;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.notificationHistory))),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIcons.strokeRoundedNotificationOff01,
                    size: 56,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(AppStrings.noNotifications),
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const WarmBackground(
                  title: AppStrings.notificationHistory,
                  subtitle: AppStrings.smartKidsShuttle,
                  trailing: Icon(
                    HugeIcons.strokeRoundedNotification01,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return NotificationTile(
                        type: notif['type'] ?? '',
                        message: notif['message'] ?? '',
                        time: notif['time'] ?? '',
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
