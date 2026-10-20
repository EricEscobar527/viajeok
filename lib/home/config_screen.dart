import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// "Config" tab: monitored apps.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late Set<RideApp> _apps = widget.prefs.monitoredApps;

  void _toggleApp(RideApp app) {
    setState(() {
      _apps = _apps.contains(app) ? ({..._apps}..remove(app)) : {..._apps, app};
    });
    widget.prefs
        .setMonitoredApps(_apps)
        .then((_) => TripReader.pushConfig(widget.prefs));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.apps_rounded,
                title: t.configAppsTitle,
                subtitle: t.configAppsSubtitle,
              ),
              const SizedBox(height: 16),
              // Two per row; fixed height so long names don't get squeezed.
              for (var i = 0; i < RideApp.values.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      for (final app in RideApp.values.skip(i).take(2)) ...[
                        if (app != RideApp.values[i]) const SizedBox(width: 12),
                        Expanded(
                          child: _AppToggle(
                            app: app,
                            on: _apps.contains(app),
                            onTap: () => _toggleApp(app),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(icon: icon, circle: true),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.app, required this.on, required this.onTap});

  final RideApp app;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? AppColors.accent : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? AppColors.accent : AppColors.border,
            width: on ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  app.label,
                  style: TextStyle(
                    color: on ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              on ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
