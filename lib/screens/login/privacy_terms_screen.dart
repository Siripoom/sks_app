import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/parent/parent_main_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class PrivacyTermsScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;

  const PrivacyTermsScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<PrivacyTermsScreen> createState() => _PrivacyTermsScreenState();
}

class _PrivacyTermsScreenState extends State<PrivacyTermsScreen> {
  bool _accepted = false;

  Future<void> _handleAccept() async {
    final appState = context.read<AppStateProvider>();
    final success = await appState.register(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      phone: widget.phone,
      password: widget.password,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(AppStrings.registerSuccess),
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.statusGreen,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ParentMainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ?? context.tr(AppStrings.emailAlreadyExists),
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.privacyAndTerms))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(30),
                child: AppSurfaceCard(
                  inner: true,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            HugeIcons.strokeRoundedShield01,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr(AppStrings.privacyPolicyTitle),
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(AppStrings.privacyPolicyContent),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            HugeIcons.strokeRoundedFile01,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr(AppStrings.termsOfServiceTitle),
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(AppStrings.termsOfServiceContent),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AppSurfaceCard(
              inner: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              borderRadius: BorderRadius.circular(26),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _accepted = !_accepted),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _accepted,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (val) =>
                                setState(() => _accepted = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(AppStrings.acceptTerms),
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _accepted && !appState.isBusy
                          ? _handleAccept
                          : null,
                      child: appState.isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : Text(
                              context.tr(AppStrings.acceptAndRegister),
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
