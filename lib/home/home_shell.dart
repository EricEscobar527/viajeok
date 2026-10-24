import 'package:flutter/material.dart';

import '../app_info.dart';
import '../billing/subscription_controller.dart';
import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../support/support_screen.dart';
import '../theme/app_theme.dart';
import 'panel_screen.dart';

/// Main screen after onboarding: header + the analysis panel. Support is
/// reached from the header instead of a bottom bar.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.prefs,
    required this.subscriptions,
  });

  final AppPrefs prefs;
  final SubscriptionController subscriptions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppInfo.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: t.supportTitle,
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SupportScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PanelScreen(prefs: prefs, subscriptions: subscriptions),
            ),
          ],
        ),
      ),
    );
  }
}
