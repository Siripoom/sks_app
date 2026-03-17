import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/child.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';
import 'package:sks/widgets/common/section_header.dart';

class ParentScheduleTab extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const ParentScheduleTab({super.key, this.onNotificationTap});

  @override
  State<ParentScheduleTab> createState() => _ParentScheduleTabState();
}

class _ParentScheduleTabState extends State<ParentScheduleTab> {
  late DateTime _selectedDate;

  static const _thaiMonths = <String>[
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  static const _thaiWeekdays = <String>[
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final parentProvider = context.watch<ParentProvider>();
    final children = parentProvider.myChildren;
    final schedule = _resolveSchedule(_selectedDate);

    return SingleChildScrollView(
      key: const PageStorageKey('parent-schedule-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr(AppStrings.tabSchedule),
            hasUnreadNotifications: parentProvider.notifications.isNotEmpty,
            onNotificationTap: widget.onNotificationTap,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSurfaceCard(
              inner: true,
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.all(14),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                currentDate: _dateOnly(DateTime.now()),
                onDateChanged: (date) {
                  setState(() => _selectedDate = _dateOnly(date));
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSurfaceCard(
              inner: true,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      HugeIcons.strokeRoundedCalendar03,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isToday(_selectedDate)
                              ? 'ตารางเวลาวันนี้'
                              : 'ตารางเวลาวันที่เลือก',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(_selectedDate, context),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: schedule.hasService
                          ? AppColors.statusGreen.withValues(alpha: 0.1)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      schedule.hasService
                          ? 'มีรถรับส่ง'
                          : context.tr(AppStrings.noServiceToday),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: schedule.hasService
                            ? AppColors.statusGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...children.map((child) => _buildScheduleCard(context, child, schedule)),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    Child child,
    _ResolvedSchedule schedule,
  ) {
    return AppSurfaceCard(
      inner: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChildAvatar(
                child: child,
                size: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                textColor: AppColors.primary,
                fontSize: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name),
                    Text(
                      child.isAssigned
                          ? 'รถ ${child.busId!.replaceFirst('bus_', 'สาย ')}'
                          : context.tr(AppStrings.waitingForRoute),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          if (!child.isAssigned) ...[
            Text(
              '${context.tr(AppStrings.pickupLocation)}: ${child.pickupLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (!schedule.hasService) ...[
            Text(
              context.tr(AppStrings.noServiceToday),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            _buildScheduleRow(
              context,
              icon: HugeIcons.strokeRoundedSun01,
              iconColor: AppColors.statusAmber,
              label: context.tr(AppStrings.morningRound),
              time: schedule.morningPickup,
            ),
            const SizedBox(height: 10),
            _buildScheduleRow(
              context,
              icon: HugeIcons.strokeRoundedMoon01,
              iconColor: AppColors.accentBlue,
              label: context.tr(AppStrings.afternoonRound),
              time: schedule.eveningPickup,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String time,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(label),
        const Spacer(),
        Text(
          'มารับ $time น.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  _ResolvedSchedule _resolveSchedule(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return const _ResolvedSchedule.noService();
    }

    String morningPickup = '--:--';
    String eveningPickup = '--:--';

    for (final schedule in MockData.mockSchedule) {
      if (schedule['period'] == AppStrings.morningRound) {
        morningPickup = schedule['pickup'] ?? morningPickup;
      }
      if (schedule['period'] == AppStrings.afternoonRound) {
        eveningPickup = schedule['pickup'] ?? eveningPickup;
      }
    }

    return _ResolvedSchedule(
      hasService: true,
      morningPickup: morningPickup,
      eveningPickup: eveningPickup,
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isToday(DateTime value) {
    final today = _dateOnly(DateTime.now());
    return value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;
  }

  String _formatDate(DateTime value, BuildContext context) {
    if (context.l10n.isEnglish) {
      return '${value.day}/${value.month}/${value.year}';
    }
    final weekday = _thaiWeekdays[value.weekday - 1];
    final month = _thaiMonths[value.month - 1];
    return 'วัน$weekday ${value.day} $month ${value.year + 543}';
  }
}

class _ResolvedSchedule {
  final bool hasService;
  final String morningPickup;
  final String eveningPickup;

  const _ResolvedSchedule({
    required this.hasService,
    required this.morningPickup,
    required this.eveningPickup,
  });

  const _ResolvedSchedule.noService()
    : hasService = false,
      morningPickup = '',
      eveningPickup = '';
}
