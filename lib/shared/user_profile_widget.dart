import 'package:flutter/material.dart';

enum _UserMenuAction { theme, more, logout }

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({
    super.key,
    required this.username,
    required this.isDark,
    required this.onThemeToggle,
    required this.onLogout,
  });

  final String username;
  final bool isDark;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayName = username.trim().isEmpty ? 'អ្នកប្រើប្រាស់' : username;

    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'បើកជម្រើសអ្នកប្រើប្រាស់',
      offset: const Offset(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (action) {
        switch (action) {
          case _UserMenuAction.theme:
            onThemeToggle();
          case _UserMenuAction.logout:
            onLogout();
          case _UserMenuAction.more:
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.theme,
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(isDark ? 'រចនាប័ទ្មងងឹត' : 'រចនាប័ទ្មភ្លឺ')),
              IgnorePointer(
                child: Switch(value: isDark, onChanged: (_) {}),
              ),
            ],
          ),
        ),
        const PopupMenuItem<_UserMenuAction>(
          enabled: false,
          value: _UserMenuAction.more,
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 10),
              Text('ជម្រើសផ្សេងៗ'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: colors.error, size: 20),
              const SizedBox(width: 10),
              Text('ចាកចេញ', style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
