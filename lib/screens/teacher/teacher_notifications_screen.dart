import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/widgets/common/empty_state_widget.dart';
import 'package:sks/widgets/parent/notification_tile.dart';

class TeacherNotificationsScreen extends StatelessWidget {
  const TeacherNotificationsScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<INotificationService>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.notifications))),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: notificationService.watchNotificationsForSchool(schoolId),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const [];

          if (notifications.isEmpty) {
            return EmptyStateWidget(message: context.tr(AppStrings.emptyList));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                type: notification['type'] ?? '',
                message: notification['message'] ?? '',
                time: notification['time'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}
