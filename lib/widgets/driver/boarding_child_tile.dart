import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/models/child.dart';

class BoardingChildTile extends StatelessWidget {
  final Child child;
  final VoidCallback onToggle;

  const BoardingChildTile({
    super.key,
    required this.child,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: child.hasBoarded
              ? AppColors.statusGreen
              : AppColors.statusGrey,
          child: Text(
            child.name.isNotEmpty ? child.name[0] : '?',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          child.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          child.homeAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: child.hasBoarded
                  ? AppColors.statusGreen
                  : AppColors.statusGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              child.hasBoarded ? HugeIcons.strokeRoundedTick01 : HugeIcons.strokeRoundedCancel01,
              color: AppColors.textOnPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
