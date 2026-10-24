import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Google Play's "prominent disclosure" for the AccessibilityService, shown
/// right before sending the user to Android's settings. Pops `true` only on
/// the accept button; back or decline is `false`.
///
/// The section texts (`disclosure*` keys in lib/l10n/app_es.arb) are written
/// by the app owner following Google Play's Accessibility API policy.
class AccessibilityDisclosureScreen extends StatelessWidget {
  const AccessibilityDisclosureScreen({super.key});

  /// Shows the screen; true if the user accepted.
  static Future<bool> show(BuildContext context) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AccessibilityDisclosureScreen(),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sections = [
      (Icons.visibility_outlined, t.disclosureDataTitle, t.disclosureDataText),
      (Icons.calculate_outlined, t.disclosureUseTitle, t.disclosureUseText),
      (
        Icons.phone_android_outlined,
        t.disclosureStorageTitle,
        t.disclosureStorageText,
      ),
      (
        Icons.toggle_off_outlined,
        t.disclosureControlTitle,
        t.disclosureControlText,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text(t.disclosureTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(
                    t.disclosureIntro,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (icon, title, text) in sections) ...[
                    _Section(icon: icon, title: title, text: text),
                    const SizedBox(height: 10),
                  ],
                  const PrivacyPolicyLink(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: t.disclosureAccept,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(t.disclosureDecline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
