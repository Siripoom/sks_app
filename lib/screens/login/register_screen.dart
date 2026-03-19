import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/screens/login/privacy_terms_screen.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivacyTermsScreen(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: email,
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: const AppSurfaceCard(
                      inner: true,
                      padding: EdgeInsets.all(12),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: Icon(
                        HugeIcons.strokeRoundedArrowLeft01,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AppStrings.register),
                        style: GoogleFonts.prompt(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        context.tr(AppStrings.createParentAccount),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(32),
                child: AppSurfaceCard(
                  inner: true,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.firstName),
                            prefixIcon: Icon(
                              HugeIcons.strokeRoundedUser02,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastNameController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.lastName),
                            prefixIcon: Icon(
                              HugeIcons.strokeRoundedUser02,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.email),
                            prefixIcon: Icon(
                              HugeIcons.strokeRoundedMail01,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            final emailRegex = RegExp(
                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return context.tr(AppStrings.invalidEmail);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.phoneNumber),
                            prefixIcon: Icon(
                              HugeIcons.strokeRoundedCall,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            final phoneRegex = RegExp(r'^0[689]\d{8}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return context.tr(AppStrings.invalidPhone);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.password),
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedLockPassword,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? HugeIcons.strokeRoundedViewOff
                                    : HugeIcons.strokeRoundedView,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            if (value.length < 6) {
                              return context.tr(AppStrings.passwordTooShort);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: context.tr(AppStrings.confirmPassword),
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedLockPassword,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? HugeIcons.strokeRoundedViewOff
                                    : HugeIcons.strokeRoundedView,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) => _handleRegister(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr(AppStrings.fieldRequired);
                            }
                            if (value != _passwordController.text) {
                              return context.tr(AppStrings.passwordsDoNotMatch);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            child: Text(
                              context.tr(AppStrings.next),
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
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr(AppStrings.alreadyHaveAccount),
                    style: GoogleFonts.prompt(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      context.tr(AppStrings.loginButton),
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accentBlue.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
