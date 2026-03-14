import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';

class DriverMessagesTab extends StatelessWidget {
  const DriverMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = MockData.mockMessages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            AppStrings.messages,
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: const PageStorageKey('driver-messages-list'),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isSystem = msg['sender'] == 'ระบบ';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSystem
                            ? AppColors.accentBlue.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        isSystem
                            ? HugeIcons.strokeRoundedInformationCircle
                            : HugeIcons.strokeRoundedUser02,
                        color: isSystem
                            ? AppColors.accentBlue
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                msg['sender']!,
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSystem
                                      ? AppColors.accentBlue
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                msg['time']!,
                                style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['message']!,
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
