import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final _subjectController = TextEditingController();
  final _detailController = TextEditingController();
  final _contactController = TextEditingController();
  String _issueType = AppStrings.generalQuestion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppStateProvider>().currentUser;
    if (_contactController.text.isEmpty && user != null) {
      _contactController.text =
          '${user.name} - ${context.tr(_roleLabel(user.role))}';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_subjectController.text.trim().isEmpty ||
        _detailController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AppStrings.fieldRequired))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(AppStrings.issueSubmitted)),
        backgroundColor: AppColors.statusGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final issueTypes = [
      AppStrings.generalQuestion,
      AppStrings.incidentReport,
      AppStrings.technicalProblem,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.adminSupportTitle))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppSurfaceCard(
          inner: true,
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(AppStrings.adminSupportSubtitle),
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _issueType,
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.issueType),
                ),
                items: issueTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(context.tr(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _issueType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.issueSubject),
                  hintText: context.tr(AppStrings.subjectHint),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.issueDetail),
                  hintText: context.tr(AppStrings.supportHint),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.senderContact),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(context.tr(AppStrings.submitIssue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return AppStrings.roleParent;
      case UserRole.teacher:
        return AppStrings.roleTeacher;
      case UserRole.driver:
        return AppStrings.roleDriver;
    }
  }
}
