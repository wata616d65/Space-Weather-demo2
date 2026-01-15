import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Light/Core モード切替トグルスイッチ
class ModeToggle extends StatelessWidget {
  final bool isCoreMode;
  final ValueChanged<bool> onChanged;

  const ModeToggle({
    super.key,
    required this.isCoreMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            label: 'Light',
            icon: Icons.wb_sunny_outlined,
            isSelected: !isCoreMode,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _buildOption(
            label: 'Core',
            icon: Icons.science_outlined,
            isSelected: isCoreMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
