import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class PickupLocationResult {
  final double lat;
  final double lng;
  final String label;

  const PickupLocationResult({
    required this.lat,
    required this.lng,
    required this.label,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultLocation = LatLng(13.7563, 100.5018);
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultLocation;
  }

  String _selectedLabel(BuildContext context) {
    return context.trArgs(AppStrings.selectedCoordinates, {
      'lat': _selectedLocation.latitude.toStringAsFixed(4),
      'lng': _selectedLocation.longitude.toStringAsFixed(4),
    });
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(AppStrings.locationServiceDisabled)),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr(AppStrings.locationPermissionDenied)),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(AppStrings.locationPermissionDenied)),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() => _selectedLocation = newLocation);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 16),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(AppStrings.locationServiceDisabled)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.choosePickupLocation))),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onTap: (latLng) {
              setState(() => _selectedLocation = latLng);
            },
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (latLng) {
                  setState(() => _selectedLocation = latLng);
                },
              ),
            },
          ),
          // Current location button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              onPressed: _loadingLocation ? null : _goToCurrentLocation,
              tooltip: context.tr(AppStrings.currentLocation),
              child: _loadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(AppStrings.mapPickerHint),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLabel(context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          PickupLocationResult(
                            lat: _selectedLocation.latitude,
                            lng: _selectedLocation.longitude,
                            label: _selectedLabel(context),
                          ),
                        );
                      },
                      child: Text(context.tr(AppStrings.confirmThisLocation)),
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
