import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/parent/bus_tracking_screen.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/child_avatar.dart';
import 'package:sks/widgets/parent/child_qr_card.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late final Future<School?> _schoolFuture;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadAllBuses();
    _schoolFuture = context
        .read<IReferenceDataService>()
        .getSchoolById(widget.child.schoolId);
  }

  String _getStatusText(BuildContext context) {
    if (!widget.child.isAssigned) {
      return context.tr(AppStrings.waitingForRoute);
    }
    if (widget.child.hasArrived) {
      return context.tr(AppStrings.arrivedAtSchoolStatus);
    }
    if (widget.child.hasBoarded) {
      return context.tr(AppStrings.boardedStatus);
    }
    return context.tr(AppStrings.waitingToBoard);
  }

  Color _getStatusColor() {
    if (!widget.child.isAssigned) {
      return AppColors.textSecondary;
    }
    if (widget.child.hasArrived) {
      return AppColors.statusGreen;
    }
    if (widget.child.hasBoarded) {
      return AppColors.statusAmber;
    }
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final busProvider = context.watch<BusProvider>();
    final trip = tripProvider.getTripById(widget.child.tripId);
    final bus = _resolveBus(busProvider, trip);

    return FutureBuilder<School?>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        final school = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: Text(context.tr(AppStrings.childDetail))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ChildAvatar(
                    child: widget.child,
                    size: 100,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    textColor: AppColors.primary,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.child.name,
                    style: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppSurfaceCard(
                  inner: true,
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AppStrings.busStatus),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          _getStatusText(context),
                          style: GoogleFonts.prompt(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context: context,
                        label: context.tr(AppStrings.schoolLabel),
                        value: school?.name.isNotEmpty == true
                            ? school!.name
                            : widget.child.schoolName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context: context,
                        label: context.tr(AppStrings.tripLabel),
                        value: _tripValue(context, trip),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context: context,
                        label: context.tr(AppStrings.busNumber),
                        value: bus?.busNumber ?? context.tr(AppStrings.notAssigned),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context: context,
                        label: context.tr(AppStrings.pickupLocation),
                        value: widget.child.pickupLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ChildQrCard(child: widget.child),
                const SizedBox(height: 24),
                if (bus != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusTrackingScreen(
                              busId: bus.id,
                              childName: widget.child.name,
                              schoolId: widget.child.schoolId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(HugeIcons.strokeRoundedMapPin),
                      label: Text(
                        context.tr(AppStrings.trackBus),
                        style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  AppSurfaceCard(
                    inner: true,
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        const Icon(
                          HugeIcons.strokeRoundedInformationCircle,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(AppStrings.cannotTrackBusUntilAssigned),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.tr(AppStrings.notificationHistory),
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppSurfaceCard(
                    inner: true,
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.child.hasArrived
                              ? context.trArgs(AppStrings.busArrivedAt, {
                                  'time': _tripTime(trip) ?? '--:--',
                                })
                              : context.tr(AppStrings.waitingAdminAssignment),
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bus != null
                              ? context.trArgs(AppStrings.busStartedRoute, {
                                  'bus': bus.busNumber,
                                })
                              : context.tr(AppStrings.assignmentNoticeHint),
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Bus? _resolveBus(BusProvider busProvider, Trip? trip) {
    final busId = trip?.busId ?? widget.child.busId;
    if (busId == null || busId.isEmpty) {
      return null;
    }
    return busProvider.getBusById(busId);
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _tripValue(BuildContext context, Trip? trip) {
    if (trip == null) {
      return context.tr(AppStrings.notAssigned);
    }
    final roundLabel = trip.round == TripRound.toSchool
        ? context.tr(AppStrings.morningRound)
        : context.tr(AppStrings.afternoonRound);
    final date = trip.serviceDate;
    return '$roundLabel - ${date.day}/${date.month}/${date.year}';
  }

  String? _tripTime(Trip? trip) {
    final value = trip?.scheduledStartAt;
    if (value == null) {
      return null;
    }
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
