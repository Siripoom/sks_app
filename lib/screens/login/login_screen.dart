import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/driver/driver_main_screen.dart';
import 'package:sks/screens/login/register_screen.dart';
import 'package:sks/screens/parent/parent_main_screen.dart';
import 'package:sks/screens/teacher/teacher_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const String _welcomeSubtitle = 'Safe You Can See, Every Mile';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showTestAccounts = false;
  bool _obscurePassword = true;

  AnimationController? _introController;
  Animation<double>? _heroAnimation;
  Animation<double>? _formAnimation;
  Animation<double>? _footerAnimation;

  @override
  void initState() {
    super.initState();
    _ensureIntroAnimations();
  }

  @override
  void dispose() {
    _introController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _ensureIntroAnimations() {
    if (_introController != null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introController = controller;
    _heroAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.12, 0.56, curve: Curves.easeOutCubic),
    );
    _formAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
    );
    _footerAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.46, 1.0, curve: Curves.easeOutCubic),
    );
    controller.forward();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    final appState = context.read<AppStateProvider>();
    final success = appState.login(email, password);

    if (success) {
      _navigateToRoleScreen(appState.selectedRole!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(AppStrings.loginFailed),
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  void _navigateToRoleScreen(UserRole role) {
    Widget screen;
    switch (role) {
      case UserRole.parent:
        screen = const ParentMainScreen();
      case UserRole.teacher:
        screen = const TeacherDashboardScreen();
      case UserRole.driver:
        screen = const DriverMainScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _fillCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = '1234';
    setState(() => _showTestAccounts = false);
  }

  @override
  Widget build(BuildContext context) {
    _ensureIntroAnimations();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCF1ED), Color(0xFFFCF1ED), Color(0xFFFCF1ED)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 22),
                _buildEntranceTransition(
                  animation: _heroAnimation!,
                  beginOffset: const Offset(0, 0.09),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.94,
                          end: 1,
                        ).animate(_heroAnimation!),
                        child: SizedBox(
                          width: 248,
                          height: 176,
                          child: Image.asset(
                            'image/logo_sh.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBrandLockup(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildEntranceTransition(
                  animation: _formAnimation!,
                  beginOffset: const Offset(0, 0.11),
                  child: _buildLoginCard(),
                ),
                const SizedBox(height: 20),
                _buildEntranceTransition(
                  animation: _footerAnimation!,
                  beginOffset: const Offset(0, 0.1),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr(AppStrings.noAccount),
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              context.tr(AppStrings.register),
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.accentBlue
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTestAccountsPanel(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: const Color(0xFFFCF1ED),
          border: Border.all(color: Colors.white.withValues(alpha: 0.98)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardBrandHeader(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFFF2E4DE),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.72),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.prompt(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: context.tr(AppStrings.email),
                        prefixIcon: const Icon(
                          HugeIcons.strokeRoundedMail01,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.prompt(fontSize: 14),
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
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: Text(
                          context.tr(AppStrings.loginButton),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBrandHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'image/bus2.png',
            width: 150,
            height: 88,
            fit: BoxFit.contain,
          ),
          Transform.translate(
            offset: const Offset(-18, 0),
            child: Text(
              'Welcome',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: -0.8,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntranceTransition({
    required Animation<double> animation,
    required Offset beginOffset,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildBrandLockup() {
    return Column(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF59D3D), Color(0xFFDB6B1A)],
          ).createShader(bounds),
          child: Text(
            'SmartKids',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 0.98,
              letterSpacing: -0.9,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SHUTTLE',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 5.2,
            color: const Color(0xFFE18B31),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _welcomeSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTestAccountsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          InkWell(
            onTap: () => setState(() => _showTestAccounts = !_showTestAccounts),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedTestTube,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(AppStrings.testAccounts),
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showTestAccounts
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showTestAccounts) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountGroup(context.tr(AppStrings.roleParent), [
                    'parent1@sks.com',
                    'parent2@sks.com',
                  ]),
                  const SizedBox(height: 10),
                  _buildAccountGroup(context.tr(AppStrings.roleTeacher), [
                    'teacher1@sks.com',
                    'teacher2@sks.com',
                  ]),
                  const SizedBox(height: 10),
                  _buildAccountGroup(context.tr(AppStrings.roleDriver), [
                    'driver1@sks.com',
                    'driver2@sks.com',
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '${context.tr(AppStrings.password)}: 1234',
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountGroup(String role, List<String> emails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        ...emails.map(
          (email) => GestureDetector(
            onTap: () => _fillCredentials(email),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                email,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: AppColors.accentBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accentBlue.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
