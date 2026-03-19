import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/school.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class BusTrackingScreen extends StatefulWidget {
  final String busId;
  final String childName;
  final String? schoolId;

  const BusTrackingScreen({
    super.key,
    required this.busId,
    required this.childName,
    this.schoolId,
  });

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  late final Future<School?> _schoolFuture;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadAllBuses();
    _schoolFuture = widget.schoolId == null || widget.schoolId!.trim().isEmpty
        ? Future<School?>.value(null)
        : context.read<IReferenceDataService>().getSchoolById(widget.schoolId!);
  }

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<BusProvider>().getBusById(widget.busId);

    return FutureBuilder<School?>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        final school = snapshot.data;
        final center = _initialTarget(bus, school);
        final markers = _buildMarkers(context, bus, school);

        return Scaffold(
          appBar: AppBar(
            title: Text('${context.tr(AppStrings.trackBus)} - ${widget.childName}'),
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: 12),
                markers: markers,
              ),
              if (bus != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AppSurfaceCard(
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
                  ),
                ),
            ],
          ),
        );
      },
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

  Set<Marker> _buildMarkers(BuildContext context, dynamic bus, School? school) {
    final markers = <Marker>{};

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

    if (school != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('school'),
          position: LatLng(school.lat, school.lng),
          infoWindow: InfoWindow(title: school.name),
        ),
      );
    }

    return markers;
  }
}
