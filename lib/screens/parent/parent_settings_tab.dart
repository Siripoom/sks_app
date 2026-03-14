import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/login/login_screen.dart';

class ParentSettingsTab extends StatefulWidget {
  const ParentSettingsTab({super.key});

  @override
  State<ParentSettingsTab> createState() => _ParentSettingsTabState();
}

class _ParentSettingsTabState extends State<ParentSettingsTab> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final userName = appState.currentUser?.name ?? '';

    return SingleChildScrollView(
      key: const PageStorageKey('parent-settings-scroll'),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profile
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0] : '?',
                      style: GoogleFonts.prompt(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.roleParent,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(AppStrings.notificationPreferences),
                  secondary: const Icon(
                    HugeIcons.strokeRoundedNotification01,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
                ListTile(
                  leading: const Icon(
                    HugeIcons.strokeRoundedLanguageCircle,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: const Text(AppStrings.language),
                  trailing: Text(
                    'ไทย',
                    style: GoogleFonts.prompt(color: AppColors.textSecondary),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AppStateProvider>().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  HugeIcons.strokeRoundedLogout01,
                  color: AppColors.statusRed,
                ),
                label: Text(
                  AppStrings.logout,
                  style: GoogleFonts.prompt(
                    color: AppColors.statusRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusRed, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
