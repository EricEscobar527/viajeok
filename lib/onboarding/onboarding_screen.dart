import 'package:flutter/material.dart';

import '../app_info.dart';
import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../platform/permissions.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum _Step { welcome, overlay, screenReading, done }

/// First-run setup. Shown only until [AppPrefs.setOnboardingDone] is called.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.prefs,
    required this.onFinished,
  });

  final AppPrefs prefs;
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _overlayGranted = false;
  bool _readingEnabled = false;

  static const _steps = _Step.values;

  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Both permissions are granted in system settings, so re-check whenever
  // the user comes back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final overlay = await Permissions.canDrawOverlays();
    final reading = await TripReader.isServiceEnabled();
    if (!mounted) return;
    setState(() {
      _overlayGranted = overlay;
      _readingEnabled = reading;
    });
  }

  Future<void> _next() async {
    if (_step == _Step.done) {
      await widget.prefs.setOnboardingDone();
      widget.onFinished();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (body, button) = switch (_step) {
      _Step.welcome => (const _WelcomeStep(), _button(t.btnSetupNow, _next)),
      _Step.overlay => (
        _OverlayStep(granted: _overlayGranted),
        _overlayGranted
            ? _button(t.btnNext, _next)
            : _button(t.btnOpenSettings, Permissions.openOverlaySettings),
      ),
      _Step.screenReading => (
        _ScreenReadingStep(enabled: _readingEnabled),
        _readingEnabled
            ? _button(t.btnNext, _next)
            : _button(t.btnOpenSettings, TripReader.openServiceSettings),
      ),
      _Step.done => (const _DoneStep(), _button(t.btnStartEarning, _next)),
    };

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                if (_index > 0)
                  _StepDots(count: _steps.length, current: _index),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: body,
                    ),
                  ),
                ),
                button,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback? onPressed) =>
      PrimaryButton(label: label, onPressed: onPressed);
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i <= current ? AppColors.accent : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.badge,
    required this.title,
    required this.text,
  });

  final Widget badge;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        badge,
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CircleBadge extends StatelessWidget {
  const _CircleBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Icon(icon, color: Colors.black, size: 36),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 16),
        const IconTile(icon: Icons.route_rounded, circle: true, size: 120),
        const SizedBox(height: 28),
        Text(
          t.welcomeTitle(AppInfo.name),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.welcomeText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              FeatureRow(
                icon: Icons.bar_chart_rounded,
                color: AppColors.accent,
                title: t.featureTripAnalysis,
                subtitle: t.featureInYourApps,
              ),
              FeatureRow(
                icon: Icons.layers_rounded,
                color: AppColors.gold,
                title: t.featurePopupOverApp,
                subtitle: t.featureWithoutLeaving,
              ),
              FeatureRow(
                icon: Icons.traffic_rounded,
                color: AppColors.red,
                title: t.featureGreenRed,
                subtitle: t.featureByFilters,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayStep extends StatelessWidget {
  const _OverlayStep({required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 32),
        _StepHeader(
          badge: granted
              ? const _CircleBadge(
                  icon: Icons.check_rounded,
                  color: AppColors.accent,
                )
              : const _CircleBadge(
                  icon: Icons.layers_rounded,
                  color: AppColors.gold,
                ),
          title: t.overlayTitle,
          text: t.overlayText,
        ),
        const SizedBox(height: 28),
        granted
            ? StatusBanner(text: t.overlayGranted)
            : StatusBanner(
                text: t.overlayRequired,
                color: AppColors.red,
                icon: Icons.error_rounded,
              ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.overlayPreviewTitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const _PopupPreview(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.overlayPreviewText,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PopupPreview extends StatelessWidget {
  const _PopupPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: const Column(
        children: [
          Text(
            '\$9.80/km',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '\$78 · 8 km · 15 min',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScreenReadingStep extends StatelessWidget {
  const _ScreenReadingStep({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 32),
        _StepHeader(
          badge: enabled
              ? const _CircleBadge(
                  icon: Icons.check_rounded,
                  color: AppColors.accent,
                )
              : const _CircleBadge(
                  icon: Icons.accessibility_new_rounded,
                  color: AppColors.gold,
                ),
          title: t.readingTitle,
          text: t.readingText(AppInfo.name),
        ),
        const SizedBox(height: 28),
        enabled
            ? StatusBanner(text: t.readingEnabled)
            : StatusBanner(
                text: t.readingRequired,
                color: AppColors.red,
                icon: Icons.error_rounded,
              ),
        if (!enabled) ...[
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.dialogEnableServiceText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 32),
        _StepHeader(
          badge: const _CircleBadge(
            icon: Icons.check_rounded,
            color: AppColors.accent,
          ),
          title: t.doneTitle,
          text: t.doneText(AppInfo.name),
        ),
        const SizedBox(height: 28),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              FeatureRow(
                icon: Icons.bar_chart_rounded,
                color: AppColors.accent,
                title: t.featureAutoAnalysis,
                subtitle: t.featureInYourApps,
              ),
              FeatureRow(
                icon: Icons.layers_rounded,
                color: AppColors.gold,
                title: t.featurePopupOverApps,
                subtitle: t.featureWhileDriving,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
