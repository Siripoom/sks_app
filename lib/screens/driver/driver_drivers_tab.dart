import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/login/login_screen.dart';

class DriverDriversTab extends StatelessWidget {
  const DriverDriversTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentUser = appState.currentUser;
    final allDrivers = MockData.drivers;

    final currentDriver = allDrivers.firstWhere(
      (d) => d.id == currentUser?.referenceId,
      orElse: () => allDrivers.first,
    );
    final otherDrivers = allDrivers
        .where((d) => d.id != currentDriver.id)
        .toList();

    return SingleChildScrollView(
      key: const PageStorageKey('driver-drivers-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.driverProfile,
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Current driver
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
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      currentDriver.name.isNotEmpty
                          ? currentDriver.name[0]
                          : '?',
                      style: GoogleFonts.prompt(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentDriver.name,
                  style: GoogleFonts.prompt(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(HugeIcons.strokeRoundedCall, currentDriver.phone),
                const SizedBox(height: 6),
                _buildInfoRow(
                  HugeIcons.strokeRoundedIdentityCard,
                  currentDriver.licenseNumber,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  HugeIcons.strokeRoundedBus01,
                  '${AppStrings.assignedBus}: ${currentDriver.busId.replaceFirst('bus_', 'สาย ')}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.otherDrivers,
              style: GoogleFonts.prompt(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...otherDrivers.map(
            (driver) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: Text(
                      driver.name.isNotEmpty ? driver.name[0] : '?',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(driver.name),
                subtitle: Text(driver.busId.replaceFirst('bus_', 'สาย ')),
              ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.prompt(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
