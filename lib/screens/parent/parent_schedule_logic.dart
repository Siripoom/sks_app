import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/trip_provider.dart';

enum ParentScheduleStatus { waitingForRoute, hasService, noServiceToday }

class ParentSchedulePresentation {
  final ParentScheduleStatus status;
  final String schoolName;
  final String? busNumber;
  final String pickupLabel;
  final String? morningPickup;
  final String? eveningPickup;

  const ParentSchedulePresentation({
    required this.status,
    required this.schoolName,
    required this.busNumber,
    required this.pickupLabel,
    required this.morningPickup,
    required this.eveningPickup,
  });

  bool get hasService => morningPickup != null || eveningPickup != null;
}

ParentSchedulePresentation buildParentSchedulePresentation({
  required Child child,
  required School? school,
  required Bus? bus,
  required ChildTripsForDate dayTrips,
}) {
  return ParentSchedulePresentation(
    status: _resolveStatus(child: child, dayTrips: dayTrips),
    schoolName: school?.name ?? child.schoolName,
    busNumber: dayTrips.primaryTrip == null ? null : bus?.busNumber,
    pickupLabel: child.pickupLabel,
    morningPickup: _timeLabel(dayTrips.morningTrip),
    eveningPickup: _timeLabel(dayTrips.afternoonTrip),
  );
}

ParentScheduleStatus _resolveStatus({
  required Child child,
  required ChildTripsForDate dayTrips,
}) {
  if (!child.isAssigned) {
    return ParentScheduleStatus.waitingForRoute;
  }
  if (dayTrips.hasService) {
    return ParentScheduleStatus.hasService;
  }
  return ParentScheduleStatus.noServiceToday;
}

String? _timeLabel(Trip? trip) {
  final scheduledStartAt = trip?.scheduledStartAt;
  if (scheduledStartAt == null) {
    return trip == null ? null : '--:--';
  }
  final hour = scheduledStartAt.hour.toString().padLeft(2, '0');
  final minute = scheduledStartAt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
