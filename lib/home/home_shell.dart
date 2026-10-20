import 'package:flutter/material.dart';

import '../app_info.dart';
import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'config_screen.dart';
import 'panel_screen.dart';
import 'placeholder_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon);

  final String Function(AppLocalizations) label;
  final IconData icon;
}

final _tabs = [
  _Tab((t) => t.tabHome, Icons.home_rounded),
  _Tab((t) => t.tabConfig, Icons.settings_rounded),
  _Tab((t) => t.tabSupport, Icons.help_rounded),
];

/// Main app after onboarding: app-name header + bottom tab bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = [
      PanelScreen(prefs: widget.prefs),
      ConfigScreen(prefs: widget.prefs),
      PlaceholderScreen(
        icon: Icons.help_rounded,
        title: t.tabSupport,
        text: t.supportText,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 72,
      child: Center(
        child: Text(
          AppInfo.name,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _tabItem(
                    _tabs[i].label(t),
                    _tabs[i].icon,
                    i == index,
                    () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
