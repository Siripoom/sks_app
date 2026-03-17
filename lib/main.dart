import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/core/constants/app_theme.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/location_service.dart';
import 'package:sks/services/notification_service.dart';

final IBusService _busService = MockBusService();
final IChildService _childService = MockChildService();
final ILocationService _locationService = MockLocationService();
final MockNotificationService _notificationService = MockNotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _notificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<IBusService>.value(value: _busService),
        Provider<IChildService>.value(value: _childService),
        Provider<ILocationService>.value(value: _locationService),
        ChangeNotifierProvider<MockNotificationService>.value(
          value: _notificationService,
        ),

        // App State
        ChangeNotifierProvider(create: (_) => AppStateProvider()),

        // Bus Provider
        ChangeNotifierProvider(
          create: (_) => BusProvider(_busService, _locationService),
        ),

        // Parent Provider
        ChangeNotifierProvider(
          create: (_) => ParentProvider(_childService, _notificationService),
        ),

        // Driver Provider
        ChangeNotifierProvider(
          create: (_) => DriverProvider(
            _busService,
            _childService,
            _notificationService,
          ),
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) => MaterialApp(
          title: appState.locale.languageCode == 'en'
              ? 'Shuttle Tracking'
              : AppStrings.appTitle,
          theme: buildAppTheme(),
          locale: appState.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
