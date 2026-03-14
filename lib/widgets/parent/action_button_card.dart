import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sks/core/constants/app_colors.dart';

class ActionButtonCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const ActionButtonCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600);

    return Expanded(
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: style),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: style),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
    );
  }
}
