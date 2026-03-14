import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/screens/login/privacy_terms_screen.dart';

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

    if (MockData.mockCredentials.containsKey(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.emailAlreadyExists,
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.warmGradientEnd,
              AppColors.warmGradientMid,
              AppColors.warmGradientStart,
              AppColors.background,
            ],
            stops: [0.0, 0.15, 0.35, 0.65],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Header with back button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          HugeIcons.strokeRoundedArrowLeft01,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.register,
                          style: GoogleFonts.prompt(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          AppStrings.createParentAccount,
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // First name
                        TextFormField(
                          controller: _firstNameController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: AppStrings.firstName,
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedUser02,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Last name
                        TextFormField(
                          controller: _lastNameController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: AppStrings.lastName,
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedUser02,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedMail01,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            final emailRegex = RegExp(
                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return AppStrings.invalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: AppStrings.phoneNumber,
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedCall,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            final phoneRegex = RegExp(r'^0[689]\d{8}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return AppStrings.invalidPhone;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
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
                              return AppStrings.fieldRequired;
                            }
                            if (value.length < 4) {
                              return AppStrings.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirm password
                        TextFormField(
                          controller: _confirmPasswordController,
                          style: GoogleFonts.prompt(fontSize: 14),
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: AppStrings.confirmPassword,
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
                              return AppStrings.fieldRequired;
                            }
                            if (value != _passwordController.text) {
                              return AppStrings.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            child: Text(
                              AppStrings.next,
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
                const SizedBox(height: 20),

                // Already have account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.loginButton,
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
