import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/admin_profile.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/parent/parent_home_tab.dart';
import 'package:sks/services/auth_service.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/location_service.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/services/trip_service.dart';

void main() {
  testWidgets('ParentHomeTab disposes without reading a deactivated context', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final notificationService = _FakeNotificationService();
    final appState = AppStateProvider(
      _FakeAuthService(),
      notificationService,
      preferences: preferences,
      initialLocale: const Locale('th'),
    );
    appState.selectRole(UserRole.parent, _FakeAuthService.parent);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider(
            create: (_) =>
                BusProvider(_FakeBusService(), _FakeLocationService()),
          ),
          ChangeNotifierProvider(
            create: (_) => ParentProvider(
              _FakeChildService(),
              notificationService,
              _FakeTripService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => TripProvider(_FakeTripService()),
          ),
          Provider<IReferenceDataService>(
            create: (_) => _FakeReferenceDataService(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('th'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: ParentHomeTab(
              onOpenSchedule: () {},
              mapBuilder: (_, Set<Marker> markers) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthService implements IAuthService {
  static const parent = AppUser(
    id: 'user-parent',
    name: 'Test Parent',
    role: UserRole.parent,
    referenceId: 'parent-1',
  );

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => parent;

  @override
  Future<AppUser> registerParent({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async => parent;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({required String password}) async {}

  @override
  Future<AppUser> updateProfile(
    AppUser user, {
    required String name,
    required String phone,
  }) async => user;

  @override
  Future<AppUser> updateProfilePhoto(
    AppUser user, {
    XFile? photo,
    bool clear = false,
  }) async => user;
}

class _FakeBusService implements IBusService {
  @override
  Stream<List<Bus>> watchAllBuses() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationService implements ILocationService {
  @override
  Stream<Map<String, LatLng>> getBusLocationStream() => Stream.value(const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChildService implements IChildService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTripService implements ITripService {
  @override
  Stream<List<Trip>> watchAllTrips() => Stream.value(const []);

  @override
  Stream<Trip?> watchTripById(String tripId) => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReferenceDataService implements IReferenceDataService {
  @override
  Future<List<School>> getSchools() async => const [];

  @override
  Future<AdminProfile?> getAdminById(String adminId) async => null;

  @override
  Future<Driver?> getDriverById(String driverId) async => null;

  @override
  Future<List<Driver>> getDriversByIds(Iterable<String> driverIds) async =>
      const [];

  @override
  Future<Parent?> getParentById(String parentId) async => null;

  @override
  Future<School?> getSchoolById(String schoolId) async => null;

  @override
  Future<Teacher?> getTeacherById(String teacherId) async => null;

  @override
  Stream<List<School>> watchSchools() => Stream.value(const []);
}

class _FakeNotificationService extends ChangeNotifier
    implements INotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerDeviceForUser(AppUser user) async {}

  @override
  Stream<List<Map<String, String>>> watchMessagesForDriver(String driverId) =>
      Stream.value(const []);

  @override
  Stream<List<Map<String, String>>> watchNotificationsForParent(
    String parentId,
  ) => Stream.value(const []);

  @override
  Stream<List<Map<String, String>>> watchNotificationsForSchool(
    String schoolId,
  ) => Stream.value(const []);

  @override
  Future<void> sendApproachingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
    required int minutesAway,
  }) async {}

  @override
  Future<void> sendArrivalNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {}

  @override
  Future<void> sendBoardingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {}

  @override
  Future<void> sendChildSkippedNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {}

  @override
  Future<void> sendTripStartedNotification({
    required Trip trip,
    required Bus bus,
    required List<Child> children,
  }) async {}
}
