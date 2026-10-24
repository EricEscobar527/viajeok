import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'billing_api.dart';

/// Replaces the whole app when the backend's `min_supported_build` is above
/// this build.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  static const _package = HttpBillingBackend.packageName;

  Future<void> _openStore() async {
    if (!await TripReader.openUrl('market://details?id=$_package')) {
      await TripReader.openUrl(
        'https://play.google.com/store/apps/details?id=$_package',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const IconTile(icon: Icons.system_update_outlined, size: 56),
              const SizedBox(height: 20),
              Text(
                t.updateTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.updateText,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              PrimaryButton(
                label: t.btnUpdate,
                icon: Icons.arrow_forward_rounded,
                onPressed: _openStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
