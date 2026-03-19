import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/constants/app_theme.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/firebase_options.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/admin_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/admin/admin_main_screen.dart';
import 'package:sks/screens/driver/driver_main_screen.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/parent/parent_main_screen.dart';
import 'package:sks/screens/teacher/teacher_dashboard_screen.dart';
import 'package:sks/services/admin_service.dart';
import 'package:sks/services/auth_service.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/location_service.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/services/trip_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  AppServices? services;
  final preferences = await SharedPreferences.getInstance();
  final startupLocale = AppStateProvider.localeFromPreferences(
    preferences,
    WidgetsBinding.instance.platformDispatcher.locale,
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateAppCheck();
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
    final notificationService = FirebaseNotificationService(
      firestore,
      FirebaseMessaging.instance,
    );
    await notificationService.initialize();

    services = AppServices(
      preferences: preferences,
      startupLocale: startupLocale,
      authService: FirebaseAuthService(
        FirebaseAuth.instance,
        firestore,
        storage,
      ),
      busService: FirebaseBusService(firestore),
      childService: FirebaseChildService(firestore, storage),
      locationService: FirebaseLocationService(firestore),
      notificationService: notificationService,
      referenceDataService: FirebaseReferenceDataService(firestore),
      adminService: FirebaseAdminService(firestore, functions),
      tripService: FirebaseTripService(firestore),
    );
  } catch (error) {
    startupError = error;
  }

  runApp(
    MyApp(
      services: services,
      startupError: startupError,
      startupLocale: startupLocale,
    ),
  );
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      return;
    case TargetPlatform.iOS:
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      return;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return;
  }
}

class AppServices {
  const AppServices({
    required this.preferences,
    required this.startupLocale,
    required this.authService,
    required this.busService,
    required this.childService,
    required this.locationService,
    required this.notificationService,
    required this.referenceDataService,
    required this.adminService,
    required this.tripService,
  });

  final SharedPreferences preferences;
  final Locale startupLocale;
  final IAuthService authService;
  final IBusService busService;
  final IChildService childService;
  final ILocationService locationService;
  final FirebaseNotificationService notificationService;
  final IReferenceDataService referenceDataService;
  final IAdminService adminService;
  final ITripService tripService;
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.services,
    this.startupError,
    required this.startupLocale,
  });

  final AppServices? services;
  final Object? startupError;
  final Locale startupLocale;

  @override
  Widget build(BuildContext context) {
    if (services == null) {
      return MaterialApp(
        title: AppLocalizations(startupLocale).tr(AppStrings.appTitle),
        theme: buildAppTheme(),
        locale: startupLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        home: _FirebaseSetupErrorScreen(
          error: startupError,
          locale: startupLocale,
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<IAuthService>.value(value: services!.authService),
        Provider<IBusService>.value(value: services!.busService),
        Provider<IChildService>.value(value: services!.childService),
        Provider<ILocationService>.value(value: services!.locationService),
        Provider<IReferenceDataService>.value(
          value: services!.referenceDataService,
        ),
        Provider<IAdminService>.value(value: services!.adminService),
        Provider<ITripService>.value(value: services!.tripService),
        ListenableProvider<INotificationService>.value(
          value: services!.notificationService,
        ),
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(
            services!.authService,
            services!.notificationService,
            preferences: services!.preferences,
            initialLocale: services!.startupLocale,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BusProvider(services!.busService, services!.locationService),
        ),
        ChangeNotifierProvider(
          create: (_) => ParentProvider(
            services!.childService,
            services!.notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverProvider(
            services!.busService,
            services!.childService,
            services!.notificationService,
            services!.tripService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(services!.adminService),
        ),
        ChangeNotifierProvider(
          create: (_) => TripProvider(services!.tripService),
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) => MaterialApp(
          title: AppLocalizations(appState.locale).tr(AppStrings.appTitle),
          theme: buildAppTheme(),
          locale: appState.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _homeFor(appState),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  Widget _homeFor(AppStateProvider appState) {
    if (appState.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = appState.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return switch (user.role) {
      UserRole.parent => const ParentMainScreen(),
      UserRole.teacher => const TeacherDashboardScreen(),
      UserRole.driver => const DriverMainScreen(),
      UserRole.admin => const AdminMainScreen(),
    };
  }
}

class _FirebaseSetupErrorScreen extends StatelessWidget {
  const _FirebaseSetupErrorScreen({required this.error, required this.locale});

  final Object? error;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(locale);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr(AppStrings.startupFirebaseIncomplete),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(l10n.tr(AppStrings.startupFirebaseDescription)),
                const SizedBox(height: 16),
                SelectableText(
                  '${l10n.tr(AppStrings.startupErrorLabel)}\n${error ?? l10n.tr(AppStrings.startupUnknownError)}',
                ),
                const SizedBox(height: 16),
                SelectableText(l10n.tr(AppStrings.startupWebHint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
