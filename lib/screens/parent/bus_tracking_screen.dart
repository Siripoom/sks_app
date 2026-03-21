import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/parent/trip_progress_card.dart';

class BusTrackingScreen extends StatefulWidget {
  final String busId;
  final String childName;
  final String childId;
  final String? schoolId;
  final String? tripId;

  const BusTrackingScreen({
    super.key,
    required this.busId,
    required this.childName,
    this.childId = '',
    this.schoolId,
    this.tripId,
  });

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  late final Future<School?> _schoolFuture;
  GoogleMapController? _mapController;
  LatLng? _lastBusPosition;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadAllBuses();
    _schoolFuture = widget.schoolId == null || widget.schoolId!.trim().isEmpty
        ? Future<School?>.value(null)
        : context.read<IReferenceDataService>().getSchoolById(widget.schoolId!);

    // Start watching trip for real-time stop updates
    if (widget.tripId != null && widget.tripId!.isNotEmpty) {
      context.read<ParentProvider>().watchTrip(widget.tripId!);
    }
  }

  @override
  void dispose() {
    context.read<ParentProvider>().stopWatchingTrip();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<BusProvider>().getBusById(widget.busId);
    final parentProvider = context.watch<ParentProvider>();
    final watchedTrip = parentProvider.watchedTrip;
    final isTripActive = watchedTrip?.status == TripStatus.active;

    // Auto-follow bus when position changes
    if (bus != null && _mapController != null) {
      final newPos = LatLng(bus.currentLat, bus.currentLng);
      if (newPos.latitude != 0 && newPos.longitude != 0 &&
          (_lastBusPosition == null ||
           _lastBusPosition!.latitude != newPos.latitude ||
           _lastBusPosition!.longitude != newPos.longitude)) {
        _lastBusPosition = newPos;
        _mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
      }
    }

    return FutureBuilder<School?>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        final school = snapshot.data;
        final center = _initialTarget(bus, school);
        final markers = _buildMarkers(context, bus, school, parentProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${context.tr(AppStrings.trackBus)} - ${widget.childName}',
            ),
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 13,
                ),
                markers: markers,
                myLocationEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
              ),
              // Context-aware info panel
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: isTripActive && watchedTrip != null
                    ? _buildTripProgressPanel(
                        parentProvider,
                        watchedTrip,
                        bus,
                      )
                    : _buildBasicInfoPanel(bus, school),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripProgressPanel(
    ParentProvider parentProvider,
    Trip trip,
    dynamic bus,
  ) {
    final busLat = bus?.currentLat ?? 0.0;
    final busLng = bus?.currentLng ?? 0.0;

    final remaining = widget.childId.isNotEmpty
        ? parentProvider.stopsRemaining(widget.childId)
        : -1;
    final eta = widget.childId.isNotEmpty
        ? parentProvider.estimatedMinutesAway(
            childId: widget.childId,
            busLat: busLat,
            busLng: busLng,
          )
        : -1;
    final myStop = widget.childId.isNotEmpty
        ? parentProvider.myChildStop(widget.childId)
        : null;
    final currentIdx = trip.currentStopIndex;

    return TripProgressCard(
      currentlyPickingUpName: parentProvider.currentlyPickingUpName,
      stopsRemaining: remaining,
      estimatedMinutes: eta,
      myChildStatus: myStop?.status,
      myChildName: widget.childName,
      currentStopNumber: currentIdx >= 0 ? currentIdx + 1 : 0,
      totalStops: trip.stops.length,
      isToHome: trip.round == TripRound.toHome,
    );
  }

  Widget _buildBasicInfoPanel(dynamic bus, School? school) {
    if (bus == null) return const SizedBox.shrink();

    return AppSurfaceCard(
      inner: true,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bus.busNumber,
            style: GoogleFonts.prompt(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (school != null)
            Text(
              school.name,
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          if (school != null) const SizedBox(height: 6),
          Text(
            context.trArgs(AppStrings.selectedCoordinates, {
              'lat': bus.currentLat.toStringAsFixed(4),
              'lng': bus.currentLng.toStringAsFixed(4),
            }),
            style: GoogleFonts.prompt(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  LatLng _initialTarget(dynamic bus, School? school) {
    if (bus != null) {
      return LatLng(bus.currentLat, bus.currentLng);
    }
    if (school != null) {
      return LatLng(school.lat, school.lng);
    }
    return const LatLng(13.7563, 100.5018);
  }

  Set<Marker> _buildMarkers(
    BuildContext context,
    dynamic bus,
    School? school,
    ParentProvider parentProvider,
  ) {
    final markers = <Marker>{};

    // Bus marker
    if (bus != null) {
      markers.add(
        Marker(
          markerId: MarkerId(bus.id),
          position: LatLng(bus.currentLat, bus.currentLng),
          infoWindow: InfoWindow(title: bus.busNumber),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    // School marker
    if (school != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('school'),
          position: LatLng(school.lat, school.lng),
          infoWindow: InfoWindow(title: school.name),
        ),
      );
    }

    // Child's pickup point marker (green)
    if (widget.childId.isNotEmpty) {
      final myStop = parentProvider.myChildStop(widget.childId);
      if (myStop != null && myStop.lat != 0 && myStop.lng != 0) {
        markers.add(
          Marker(
            markerId: const MarkerId('my-pickup'),
            position: LatLng(myStop.lat, myStop.lng),
            infoWindow: InfoWindow(
              title: context.trArgs(AppStrings.pickupPointMarker, {
                'name': widget.childName,
              }),
              snippet: myStop.pickupLabel,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    return markers;
  }
}
