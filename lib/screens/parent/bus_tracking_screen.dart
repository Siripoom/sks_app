import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class BusTrackingScreen extends StatefulWidget {
  final String busId;
  final String childName;

  const BusTrackingScreen({
    super.key,
    required this.busId,
    required this.childName,
  });

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().loadBusesForSchool('school_01');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
  }

  void _updateMarkers() {
    if (_mapController == null) return;

    final bus = context.read<BusProvider>().getBusById(widget.busId);
    _markers.clear();

    if (bus != null) {
      _markers.add(
        Marker(
          markerId: MarkerId(bus.id),
          position: LatLng(bus.currentLat, bus.currentLng),
          infoWindow: InfoWindow(title: bus.busNumber),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(bus.currentLat, bus.currentLng),
            zoom: 13,
          ),
        ),
      );
    }

    _markers.add(
      const Marker(
        markerId: MarkerId('school'),
        position: LatLng(13.7563, 100.5018),
        infoWindow: InfoWindow(title: 'โรงเรียนสาธิต'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<BusProvider>().getBusById(widget.busId);

    if (bus != null) {
      _updateMarkers();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppStrings.trackBus} - ${widget.childName}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7563, 100.5018),
              zoom: 12,
            ),
            markers: _markers,
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
                    Text(
                      'ตำแหน่ง: ${bus.currentLat.toStringAsFixed(4)}, ${bus.currentLng.toStringAsFixed(4)}',
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
  }
}
