import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/login/login_screen.dart';

class AccountDeletionTile extends StatelessWidget {
  const AccountDeletionTile({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(AppStrings.deleteAccountTitle)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(AppStrings.deleteAccountMessage)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr(AppStrings.deleteAccountPasswordHint),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () {
              final value = passwordController.text;
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(context.tr(AppStrings.deleteAccountConfirm)),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password == null || !context.mounted) return;

    final appState = context.read<AppStateProvider>();
    final success = await appState.deleteAccount(password);
    if (!context.mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appState.errorMessage ?? context.tr(AppStrings.deleteAccountFailed),
        ),
        backgroundColor: AppColors.statusRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AppStateProvider>().isBusy;
    return ListTile(
      leading: const Icon(
        Icons.delete_forever_outlined,
        color: AppColors.statusRed,
      ),
      title: Text(
        context.tr(AppStrings.deleteAccount),
        style: const TextStyle(color: AppColors.statusRed),
      ),
      enabled: !busy,
      onTap: busy ? null : () => _deleteAccount(context),
    );
  }
}
