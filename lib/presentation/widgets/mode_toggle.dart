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
            icon: Icons.visibility_outlined,
            isSelected: !isCoreMode,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _buildOption(
            icon: Icons.insights,
            isSelected: isCoreMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
}
