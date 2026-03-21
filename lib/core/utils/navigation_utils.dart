import 'package:url_launcher/url_launcher.dart';

Future<bool> openGoogleMapsNavigation(double lat, double lng) async {
  final uri = Uri.parse(
    'google.navigation:q=$lat,$lng&mode=d',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }

  final webUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );
  return launchUrl(webUri, mode: LaunchMode.externalApplication);
}
