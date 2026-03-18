import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/parent/add_child_screen.dart';
import 'package:sks/screens/parent/child_detail_screen.dart';
import 'package:sks/screens/parent/parent_home_tab.dart';
import 'package:sks/screens/parent/parent_notifications_screen.dart';
import 'package:sks/screens/parent/parent_schedule_tab.dart';
import 'package:sks/screens/parent/parent_settings_tab.dart';
import 'package:sks/widgets/common/floating_bottom_nav.dart';
import 'package:sks/widgets/common/keep_alive_page.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/parent/child_card.dart';

class ParentMainScreen extends StatefulWidget {
  const ParentMainScreen({super.key});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  static const _tabTransitionDuration = Duration(milliseconds: 220);

  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    final appState = context.read<AppStateProvider>();
    final parentProvider = context.read<ParentProvider>();
    final busProvider = context.read<BusProvider>();
    parentProvider.loadChildren(appState.currentUser!.referenceId);
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentNotificationsScreen()),
    );
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
            child: ParentHomeTab(onOpenSchedule: () => _goToTab(1)),
          ),
          KeepAlivePage(
            child: ParentScheduleTab(onNotificationTap: _openNotifications),
          ),
          KeepAlivePage(
            child: _ParentMyKidsTab(onNotificationTap: _openNotifications),
          ),
          KeepAlivePage(
            child: ParentSettingsTab(onNotificationTap: _openNotifications),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddChildScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(
                HugeIcons.strokeRoundedAdd01,
                color: AppColors.textOnPrimary,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: [
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            selectedIcon: HugeIcons.strokeRoundedHome01,
            label: context.tr(AppStrings.tabHome),
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedClock01,
            selectedIcon: HugeIcons.strokeRoundedClock01,
            label: context.tr(AppStrings.tabSchedule),
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedBaby02,
            selectedIcon: HugeIcons.strokeRoundedBaby02,
            label: context.tr(AppStrings.tabMyKids),
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedSettings01,
            selectedIcon: HugeIcons.strokeRoundedSettings01,
            label: context.tr(AppStrings.tabSettings),
          ),
        ],
      ),
    );
  }
}

class _ParentMyKidsTab extends StatelessWidget {
  final VoidCallback onNotificationTap;

  const _ParentMyKidsTab({required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentProvider>(
      builder: (context, parentProvider, _) {
        final children = parentProvider.myChildren;

        return SingleChildScrollView(
          key: const PageStorageKey('parent-my-kids-scroll'),
          child: Column(
            children: [
              SectionHeader(
                title: context.tr(AppStrings.tabMyKids),
                notificationCount: parentProvider.notifications.length,
                onNotificationTap: onNotificationTap,
              ),
              const SizedBox(height: 12),
              if (children.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                  child: Text(
                    context.tr(AppStrings.emptyList),
                    style: GoogleFonts.prompt(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ...children.map(
                  (child) => ChildCard(
                    child: child,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildDetailScreen(child: child),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 96),
            ],
          ),
        );
      },
    );
  }
}
