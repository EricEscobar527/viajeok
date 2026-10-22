import 'package:flutter/material.dart';

import '../app_info.dart';
import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// First-run screen, shown once. Permissions aren't asked here: the only
/// one needed (Lectura de pantalla) is requested the first time the user
/// starts the analysis, when it's clear why.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.prefs,
    required this.onFinished,
  });

  final AppPrefs prefs;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.welcomeTitle(AppInfo.name),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.welcomeText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FeatureRow(
                        icon: Icons.document_scanner_outlined,
                        title: t.featureReadTitle,
                        subtitle: t.featureReadText,
                      ),
                      FeatureRow(
                        icon: Icons.rule_outlined,
                        title: t.featureVerdictTitle,
                        subtitle: t.featureVerdictText,
                      ),
                      FeatureRow(
                        icon: Icons.picture_in_picture_alt_outlined,
                        title: t.featureOverlayTitle,
                        subtitle: t.featureOverlayText,
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: t.btnStart,
                icon: Icons.arrow_forward_rounded,
                onPressed: () async {
                  await prefs.setOnboardingDone();
                  onFinished();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
