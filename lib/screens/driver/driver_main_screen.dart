import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/driver_provider.dart';
import 'package:sks/screens/driver/driver_drivers_tab.dart';
import 'package:sks/screens/driver/driver_home_tab.dart';
import 'package:sks/screens/driver/driver_messages_tab.dart';
import 'package:sks/screens/driver/driver_students_tab.dart';
import 'package:sks/widgets/common/floating_bottom_nav.dart';
import 'package:sks/widgets/common/keep_alive_page.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  static const _tabTransitionDuration = Duration(milliseconds: 220);

  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    final appState = context.read<AppStateProvider>();
    final driverProvider = context.read<DriverProvider>();
    final busProvider = context.read<BusProvider>();

    final driverId = appState.currentUser?.referenceId ?? 'driver_01';
    driverProvider.loadDriverData(driverId);
    busProvider.loadBusesForSchool('school_01');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: _tabTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _switchToStudentsTab() {
    _goToTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (index != _currentIndex) {
            setState(() => _currentIndex = index);
          }
        },
        children: [
          KeepAlivePage(
            child: DriverHomeTab(onSeeAllStudents: _switchToStudentsTab),
          ),
          const KeepAlivePage(child: DriverStudentsTab()),
          const KeepAlivePage(child: DriverMessagesTab()),
          const KeepAlivePage(child: DriverDriversTab()),
        ],
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: const [
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            selectedIcon: HugeIcons.strokeRoundedHome01,
            label: AppStrings.tabHome,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedUserGroup,
            selectedIcon: HugeIcons.strokeRoundedUserGroup,
            label: AppStrings.tabStudents,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedMessage01,
            selectedIcon: HugeIcons.strokeRoundedMessage01,
            label: AppStrings.tabMessages,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedUser02,
            selectedIcon: HugeIcons.strokeRoundedUser02,
            label: AppStrings.tabDrivers,
          ),
        ],
      ),
    );
  }
}
