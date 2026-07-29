import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/login/privacy_terms_screen.dart';
import 'package:sks/services/auth_service.dart';
import 'package:sks/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login does not expose test account credentials', (tester) async {
    final appState = await _createAppState();

    await tester.pumpWidget(
      _AuthHarness(
        appState: appState,
        observer: NavigatorObserver(),
        signedOutHome: const LoginScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('บัญชีทดสอบ'), findsNothing);
    expect(find.text('parent1@sks.com'), findsNothing);
    expect(find.text('teacher1@sks.com'), findsNothing);
    expect(find.text('driver1@sks.com'), findsNothing);
  });

  testWidgets('successful login resets to one authenticated route', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    final appState = await _createAppState();

    await tester.pumpWidget(
      _AuthHarness(
        appState: appState,
        observer: observer,
        signedOutHome: const LoginScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    observer.reset();

    await tester.enterText(find.byType(TextField).at(0), 'parent@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.ensureVisible(find.text(AppStrings.loginButton));
    await tester.pump();
    await tester.tap(find.text(AppStrings.loginButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('authenticated-home')), findsOneWidget);
    expect(observer.pushCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful registration clears the registration stack', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    final appState = await _createAppState();

    await tester.pumpWidget(
      _AuthHarness(
        appState: appState,
        observer: observer,
        signedOutHome: const PrivacyTermsScreen(
          firstName: 'Test',
          lastName: 'Parent',
          email: 'parent@example.com',
          phone: '0800000000',
          password: '123456',
        ),
      ),
    );
    await tester.pump();
    observer.reset();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(AppStrings.acceptAndRegister));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('authenticated-home')), findsOneWidget);
    expect(observer.pushCount, 1);
    expect(tester.takeException(), isNull);
  });

  test('account deletion clears the authenticated session', () async {
    final appState = await _createAppState();
    expect(await appState.login('parent@example.com', '123456'), isTrue);
    expect(appState.currentUser, isNotNull);

    expect(await appState.deleteAccount('123456'), isTrue);
    expect(appState.currentUser, isNull);
    expect(appState.selectedRole, isNull);
  });
}

Future<AppStateProvider> _createAppState() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final appState = AppStateProvider(
    _FakeAuthService(),
    _FakeNotificationService(),
    preferences: preferences,
    initialLocale: const Locale('th'),
  );
  return appState;
}

class _AuthHarness extends StatelessWidget {
  const _AuthHarness({
    required this.appState,
    required this.observer,
    required this.signedOutHome,
  });

  final AppStateProvider appState;
  final NavigatorObserver observer;
  final Widget signedOutHome;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppStateProvider>(
        builder: (context, state, _) => MaterialApp(
          key: ValueKey<String>(
            'auth:${state.currentUser?.id ?? 'signed-out'}',
          ),
          locale: const Locale('th'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorObservers: [observer],
          home: state.currentUser == null
              ? signedOutHome
              : const Scaffold(body: SizedBox(key: Key('authenticated-home'))),
        ),
      ),
    );
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  void reset() => pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

class _FakeAuthService implements IAuthService {
  static const _parent = AppUser(
    id: 'user-parent',
    name: 'Test Parent',
    role: UserRole.parent,
    referenceId: 'parent-1',
    email: 'parent@example.com',
  );

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _parent;

  @override
  Future<AppUser> registerParent({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async => _parent;

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
