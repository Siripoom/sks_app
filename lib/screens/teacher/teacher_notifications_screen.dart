import 'package:flutter/material.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/widgets/common/empty_state_widget.dart';
import 'package:sks/widgets/parent/notification_tile.dart';

class TeacherNotificationsScreen extends StatelessWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = MockData.notificationHistory;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.notifications))),
      body: notifications.isEmpty
          ? EmptyStateWidget(
              message: context.tr(AppStrings.emptyList),
            )
          : ListView.builder(
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
            ),
    );
  }
}
