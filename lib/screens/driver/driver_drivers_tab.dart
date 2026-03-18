import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/common/admin_support_screen.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/user_avatar.dart';

class DriverDriversTab extends StatefulWidget {
  final VoidCallback onOpenMessages;

  const DriverDriversTab({super.key, required this.onOpenMessages});

  @override
  State<DriverDriversTab> createState() => _DriverDriversTabState();
}

class _DriverDriversTabState extends State<DriverDriversTab> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (photo == null || !mounted) {
      return;
    }

    context.read<AppStateProvider>().updateCurrentUserProfilePhoto(photo.path);
  }

  void _removeProfilePhoto() {
    context.read<AppStateProvider>().updateCurrentUserProfilePhoto('');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentUser = appState.currentUser;
    final currentDriver = MockData.drivers.firstWhere(
      (driver) => driver.id == currentUser?.referenceId,
      orElse: () => MockData.drivers.first,
    );

    return SingleChildScrollView(
      key: const PageStorageKey('driver-drivers-scroll'),
      child: Column(
        children: [
          SectionHeader(
            title: context.tr(AppStrings.driverProfile),
            notificationCount: MockData.mockMessages.length,
            onNotificationTap: widget.onOpenMessages,
          ),
          const SizedBox(height: 20),
          AppSurfaceCard(
            inner: true,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                UserAvatar(user: currentUser, size: 72),
                const SizedBox(height: 12),
                Text(
                  currentDriver.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.call_outlined, currentDriver.phone),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.badge_outlined,
                  currentDriver.licenseNumber,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.directions_bus_outlined,
                  '${context.tr(AppStrings.assignedBus)}: ${currentDriver.busId.replaceFirst('bus_', 'สาย ')}',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.tr(AppStrings.changeProfilePhoto)),
                    ),
                    if ((currentUser?.profilePhotoPath ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: _removeProfilePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.tr(AppStrings.removeProfilePhoto)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            inner: true,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                RadioListTile<AppLanguage>(
                  title: Text(context.tr(AppStrings.languageThai)),
                  value: AppLanguage.thai,
                  groupValue: appState.language,
                  onChanged: (value) {
                    if (value != null) {
                      appState.setLanguage(value);
                    }
                  },
                ),
                RadioListTile<AppLanguage>(
                  title: Text(context.tr(AppStrings.languageEnglish)),
                  value: AppLanguage.english,
                  groupValue: appState.language,
                  onChanged: (value) {
                    if (value != null) {
                      appState.setLanguage(value);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text(context.tr(AppStrings.contactAdmin)),
                  subtitle: Text(context.tr(AppStrings.reportIssue)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                  Icons.logout,
                  color: AppColors.statusRed,
                ),
                label: Text(
                  context.tr(AppStrings.logout),
                  style: const TextStyle(
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
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
