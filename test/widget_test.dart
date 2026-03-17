import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/main.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/screens/parent/parent_home_tab.dart';
import 'package:sks/widgets/common/section_header.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('SmartKids.'), findsOneWidget);
    expect(find.text('SHUTTLE'), findsAtLeastNWidgets(1));
    expect(
      find.widgetWithText(ElevatedButton, AppStrings.loginButton),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('SectionHeader triggers notification callback', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'หน้าหลัก',
            hasUnreadNotifications: true,
            onNotificationTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('Parent home renders redesigned sections and opens schedule', (
    WidgetTester tester,
  ) async {
    var openedSchedule = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ParentHomeContent(
            user: const AppUser(
              id: 'user_parent_test',
              name: 'มานะ',
              role: UserRole.parent,
              referenceId: 'parent_01',
            ),
            children: MockData.children
                .where((child) => child.parentId == 'parent_01')
                .toList(),
            notifications: MockData.notificationHistory,
            primaryBus: MockData.buses.first,
            primaryDriver: MockData.drivers.first,
            markers: const <Marker>{},
            hasUnreadNotifications: true,
            onNotificationTap: () {},
            onOpenSchedule: () => openedSchedule = true,
            onMapTap: () {},
            mapBuilder: (_, __) => Container(
              key: const Key('home-map-placeholder'),
              color: Colors.orange.shade50,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.mapSection), findsOneWidget);
    expect(find.text(AppStrings.todayTrip), findsOneWidget);
    expect(find.text(AppStrings.studentStatus), findsOneWidget);
    expect(find.text(AppStrings.todayPickupHistory), findsOneWidget);
    expect(find.byKey(const Key('home-map-placeholder')), findsOneWidget);

    await tester.ensureVisible(find.byTooltip(AppStrings.busSchedule));
    await tester.tap(find.byTooltip(AppStrings.busSchedule));
    await tester.pump();

    expect(openedSchedule, isTrue);
  });
}
