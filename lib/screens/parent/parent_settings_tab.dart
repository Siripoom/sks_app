import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/common/admin_support_screen.dart';
import 'package:sks/screens/common/edit_profile_screen.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/section_header.dart';
import 'package:sks/widgets/common/user_avatar.dart';

class ParentSettingsTab extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const ParentSettingsTab({super.key, this.onNotificationTap});

  @override
  State<ParentSettingsTab> createState() => _ParentSettingsTabState();
}

class _ParentSettingsTabState extends State<ParentSettingsTab> {
  bool _notificationsEnabled = true;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    final appState = context.read<AppStateProvider>();
    if (appState.isBusy) return;

    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (photo == null || !mounted) return;

    final success = await appState.updateCurrentUserProfilePhoto(photo);

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ??
                context.tr(AppStrings.profilePhotoUploadFailed),
          ),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    final appState = context.read<AppStateProvider>();
    if (appState.isBusy) return;

    final success = await appState.updateCurrentUserProfilePhoto(
      null,
      clear: true,
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ??
                context.tr(AppStrings.profilePhotoUploadFailed),
          ),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  Future<void> _openEditProfile() async {
    final appState = context.read<AppStateProvider>();
    final user = appState.currentUser;
    if (user == null) return;

    final refService = context.read<IReferenceDataService>();
    final parent = await refService.getParentById(user.referenceId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentPhone: parent?.phone ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final parentProvider = context.watch<ParentProvider>();
    final user = appState.currentUser;

    return SingleChildScrollView(
      key: const PageStorageKey('parent-settings-scroll'),
      child: Column(
        children: [
          SectionHeader(
            title: context.tr(AppStrings.tabSettings),
            notificationCount: parentProvider.notifications.length,
            onNotificationTap: widget.onNotificationTap,
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            inner: true,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                Row(
                  children: [
                    UserAvatar(user: user, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(AppStrings.roleParent),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: appState.isBusy ? null : _pickProfilePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.tr(AppStrings.changeProfilePhoto)),
                    ),
                    if ((user?.profilePhotoPath ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed:
                            appState.isBusy ? null : _removeProfilePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.tr(AppStrings.removeProfilePhoto)),
                      ),
                    OutlinedButton.icon(
                      onPressed: appState.isBusy ? null : _openEditProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.tr(AppStrings.editProfile)),
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
                SwitchListTile(
                  title: Text(context.tr(AppStrings.notificationPreferences)),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
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
                onPressed: () async {
                  await context.read<AppStateProvider>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.statusRed),
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
}
