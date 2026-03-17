import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultLocation;
  }

  String get _selectedLabel =>
      'ตำแหน่งที่เลือก (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตำแหน่งรับส่ง')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
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
                  const Text(
                    'แตะบนแผนที่หรือเลื่อน marker เพื่อเลือกจุดรับส่ง',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLabel,
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
                            label: _selectedLabel,
                          ),
                        );
                      },
                      child: const Text('ยืนยันตำแหน่งนี้'),
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
