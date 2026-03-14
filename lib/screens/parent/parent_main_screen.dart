import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/bus_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/parent/add_child_screen.dart';
import 'package:sks/screens/parent/child_detail_screen.dart';
import 'package:sks/screens/parent/parent_home_tab.dart';
import 'package:sks/screens/parent/parent_schedule_tab.dart';
import 'package:sks/screens/parent/parent_settings_tab.dart';
import 'package:sks/widgets/common/floating_bottom_nav.dart';
import 'package:sks/widgets/common/keep_alive_page.dart';
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
          const KeepAlivePage(child: ParentHomeTab()),
          const KeepAlivePage(child: ParentScheduleTab()),
          KeepAlivePage(child: _buildMyKidsTab()),
          const KeepAlivePage(child: ParentSettingsTab()),
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
        items: const [
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            selectedIcon: HugeIcons.strokeRoundedHome01,
            label: AppStrings.tabHome,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedClock01,
            selectedIcon: HugeIcons.strokeRoundedClock01,
            label: AppStrings.tabSchedule,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedBaby02,
            selectedIcon: HugeIcons.strokeRoundedBaby02,
            label: AppStrings.tabMyKids,
          ),
          FloatingBottomNavItem(
            icon: HugeIcons.strokeRoundedSettings01,
            selectedIcon: HugeIcons.strokeRoundedSettings01,
            label: AppStrings.tabSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildMyKidsTab() {
    return Consumer<ParentProvider>(
      builder: (context, parentProvider, _) {
        final children = parentProvider.myChildren;
        if (children.isEmpty) {
          return Center(
            child: Text(
              AppStrings.emptyList,
              style: GoogleFonts.prompt(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          );
        }
        return ListView.builder(
          key: const PageStorageKey('parent-my-kids-list'),
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            return ChildCard(
              child: child,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildDetailScreen(child: child),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
