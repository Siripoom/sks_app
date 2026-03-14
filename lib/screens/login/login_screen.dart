import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showTestAccounts = false;
  bool _obscurePassword = true;

  AnimationController? _introController;
  Animation<double>? _badgeAnimation;
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
    _badgeAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
    );
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
          content: Text(AppStrings.loginFailed, style: GoogleFonts.prompt()),
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
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFDFDFD),
              AppColors.background,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PremiumLoginBackgroundPainter()),
              ),
            ),
            Positioned(
              top: -72,
              right: -32,
              child: _buildSoftCircle(
                size: 220,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              top: 140,
              left: -42,
              child: _buildSoftCircle(
                size: 160,
                color: AppColors.accentBlue.withValues(alpha: 0.035),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 34),
                   
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
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'image/logo_new.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.smartKidsShuttle,
                            style: GoogleFonts.prompt(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.appTitle,
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
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
                                AppStrings.noAccount,
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
                                  AppStrings.register,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.loginButton,
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.prompt(fontSize: 14),
            decoration: InputDecoration(
              labelText: AppStrings.email,
              prefixIcon: const Icon(HugeIcons.strokeRoundedMail01, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.prompt(fontSize: 14),
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
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
                AppStrings.loginButton,
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftCircle({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

  Widget _buildHeroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedSchoolBus,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Smart route monitoring',
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
                      AppStrings.testAccounts,
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
                  _buildAccountGroup(AppStrings.roleParent, [
                    'parent1@sks.com',
                    'parent2@sks.com',
                  ]),
                  const SizedBox(height: 10),
                  _buildAccountGroup(AppStrings.roleTeacher, [
                    'teacher1@sks.com',
                    'teacher2@sks.com',
                  ]),
                  const SizedBox(height: 10),
                  _buildAccountGroup(AppStrings.roleDriver, [
                    'driver1@sks.com',
                    'driver2@sks.com',
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'รหัสผ่าน: 1234',
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

class _PremiumLoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final warmLine = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final coolLine = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final topRoute = Path()
      ..moveTo(size.width * 0.12, size.height * 0.14)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.07,
        size.width * 0.5,
        size.height * 0.2,
        size.width * 0.68,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.05,
        size.width * 0.98,
        size.height * 0.16,
        size.width * 0.86,
        size.height * 0.28,
      );

    final lowerRoute = Path()
      ..moveTo(size.width * 0.06, size.height * 0.76)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.69,
        size.width * 0.36,
        size.height * 0.84,
        size.width * 0.52,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.84,
        size.height * 0.86,
        size.width * 0.96,
        size.height * 0.8,
      );

    canvas.drawPath(topRoute, warmLine);
    canvas.drawPath(lowerRoute, coolLine);

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final nodeStroke = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final nodes = [
      Offset(size.width * 0.12, size.height * 0.14),
      Offset(size.width * 0.68, size.height * 0.12),
      Offset(size.width * 0.86, size.height * 0.28),
      Offset(size.width * 0.52, size.height * 0.78),
      Offset(size.width * 0.96, size.height * 0.8),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 8, glowPaint);
      canvas.drawCircle(node, 3.6, nodePaint);
      canvas.drawCircle(node, 3.6, nodeStroke);
    }

    final accentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.68, size.height * 0.19, 80, 30),
      const Radius.circular(18),
    );
    final accentFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.74)
      ..style = PaintingStyle.fill;
    final accentStroke = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(accentRect, accentFill);
    canvas.drawRRect(accentRect, accentStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
