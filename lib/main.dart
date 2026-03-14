import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = MockNotificationService();
  await notificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<IBusService>(create: (_) => MockBusService()),
        Provider<IChildService>(create: (_) => MockChildService()),
        Provider<ILocationService>(create: (_) => MockLocationService()),
        Provider<INotificationService>(
          create: (_) => MockNotificationService(),
        ),

        // App State
        ChangeNotifierProvider(create: (_) => AppStateProvider()),

        // Bus Provider
        ChangeNotifierProvider(
          create: (ctx) => BusProvider(
            ctx.read<IBusService>(),
            ctx.read<ILocationService>(),
          ),
        ),

        // Parent Provider
        ChangeNotifierProvider(
          create: (ctx) => ParentProvider(
            ctx.read<IChildService>(),
            ctx.read<INotificationService>(),
          ),
        ),

        // Driver Provider
        ChangeNotifierProvider(
          create: (ctx) => DriverProvider(
            ctx.read<IBusService>(),
            ctx.read<IChildService>(),
            ctx.read<INotificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: buildAppTheme(),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
