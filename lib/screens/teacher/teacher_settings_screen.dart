import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/common/admin_support_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.teacherSettings))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppSurfaceCard(
          inner: true,
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
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
      ),
    );
  }
}
