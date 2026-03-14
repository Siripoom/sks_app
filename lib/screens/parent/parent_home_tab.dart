import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/parent/bus_tracking_screen.dart';
import 'package:sks/screens/parent/parent_notifications_screen.dart';
import 'package:sks/widgets/common/warm_background.dart';
import 'package:sks/widgets/parent/action_button_card.dart';
import 'package:sks/widgets/parent/arrival_eta_card.dart';

class ParentHomeTab extends StatelessWidget {
  const ParentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final parentProvider = context.watch<ParentProvider>();
    final busProvider = context.watch<BusProvider>();
    final userName = appState.currentUser?.name ?? '';
    final children = parentProvider.myChildren;

    return SingleChildScrollView(
      key: const PageStorageKey('parent-home-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warm header
          WarmBackground(
            title: '${AppStrings.welcomeGreeting} $userName!',
            subtitle: AppStrings.smartKidsShuttle,
            trailing: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset('image/school-bus.png', fit: BoxFit.contain),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Map snippet
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  final child = children.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusTrackingScreen(
                        busId: child.busId,
                        childName: child.name,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: AbsorbPointer(
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(13.7563, 100.5018),
                          zoom: 12,
                        ),
                        liteModeEnabled: true,
                        markers: _buildMarkers(children, busProvider),
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ETA cards for each child
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: children.map((child) {
                final bus = busProvider.getBusById(child.busId);
                final eta = bus?.estimatedArrival;
                final minutesAway = eta != null
                    ? eta.difference(DateTime.now()).inMinutes.clamp(0, 999)
                    : 15;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ArrivalEtaCard(
                    minutesAway: minutesAway,
                    childName: child.name,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ActionButtonCard(
                  label: AppStrings.pickUp,
                  icon: HugeIcons.strokeRoundedHandGrip,
                  onTap: () {},
                  filled: true,
                ),
                const SizedBox(width: 12),
                ActionButtonCard(
                  label: AppStrings.notifications,
                  icon: HugeIcons.strokeRoundedNotification01,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentNotificationsScreen(),
                      ),
                    );
                  },
                  filled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List children, BusProvider busProvider) {
    final markers = <Marker>{};
    for (final child in children) {
      final bus = busProvider.getBusById(child.busId);
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
    }
    // School marker
    markers.add(
      const Marker(
        markerId: MarkerId('school'),
        position: LatLng(13.7563, 100.5018),
      ),
    );
    return markers;
  }
}
