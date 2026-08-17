import 'package:flutter/material.dart';

import 'network_image.dart';

enum _UserMenuAction { theme, more, logout }

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({
    super.key,
    required this.username,
    this.userImageUrl = '',
    required this.isDark,
    required this.onThemeToggle,
    required this.onLogout,
  });

  final String username;
  final String userImageUrl;
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
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: userImageUrl.trim().isEmpty
                    ? _ProfileImageFallback(
                        displayName: displayName,
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      )
                    : AppNetworkImage(
                        key: const ValueKey('user-profile-image'),
                        imageUrl: userImageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 96,
                        memCacheHeight: 96,
                        maxWidthDiskCache: 192,
                        maxHeightDiskCache: 192,
                        placeholder: _ProfileImageFallback(
                          displayName: displayName,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                        errorWidget: _ProfileImageFallback(
                          displayName: displayName,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                      ),
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

class _ProfileImageFallback extends StatelessWidget {
  const _ProfileImageFallback({
    required this.displayName,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String displayName;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Text(
          displayName.characters.first.toUpperCase(),
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
