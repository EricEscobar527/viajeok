import 'package:flutter/material.dart';

import '../billing/subscription_controller.dart';
import '../billing/subscription_screen.dart';
import '../data/app_prefs.dart';
import '../data/trip_filters.dart';
import '../l10n/app_localizations.dart';
import '../platform/reader_diagnostics.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'accessibility_disclosure_screen.dart';

/// Home: start/stop the analysis and the minimums (filters) that decide
/// green vs red.
class PanelScreen extends StatefulWidget {
  const PanelScreen({
    super.key,
    required this.prefs,
    required this.subscriptions,
  });

  final AppPrefs prefs;
  final SubscriptionController subscriptions;

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> with WidgetsBindingObserver {
  bool _running = false;
  bool _serviceEnabled = false;

  /// What could keep the alert from showing; null until read (or off Android).
  ReaderDiagnostics? _diag;

  /// Android binds the service a moment after it's switched on, so "enabled
  /// but not running" is only reported if it's still true on a second look.
  bool _notConnectedSeen = false;
  bool _stoppedConfirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-read the state when coming back from DiDi/Uber/Rappi or from Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    var running = await TripReader.isRunning();
    final enabled = await TripReader.isServiceEnabled();
    final prefs = widget.prefs;
    // Back from Android's settings with the permission on: the user already
    // pressed ▶, so start without making them press it again.
    if (enabled && prefs.startAfterPermission) {
      await prefs.setStartAfterPermission(false);
      if (!running) {
        await TripReader.pushConfig(prefs);
        await TripReader.setRunning(true);
        running = await TripReader.isRunning();
      }
    }
    final diag = await ReaderDiagnostics.load();
    if (!mounted) return;
    final notConnected = diag != null && enabled && !diag.serviceConnected;
    final recheck = notConnected && !_notConnectedSeen;
    setState(() {
      _running = running;
      _serviceEnabled = enabled;
      _diag = diag;
      _stoppedConfirmed = notConnected && _notConnectedSeen;
      _notConnectedSeen = notConnected;
    });
    if (recheck) {
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) _refresh();
      });
    }
  }

  Future<void> _openServiceSettings() async {
    await widget.prefs.setStartAfterPermission(true);
    await TripReader.openServiceSettings();
  }

  Future<void> _dismissBatteryHint() async {
    await widget.prefs.setBatteryHintDismissed();
    if (mounted) setState(() {});
  }

  /// Only while the user wants the analysis on (or is setting it up): the
  /// first thing on the phone that keeps the alert from showing.
  Widget? _warning(AppLocalizations t) {
    final pending = widget.prefs.startAfterPermission;
    if (!_running && !pending) return null;
    if (!_serviceEnabled) {
      return _WarningCard(
        icon: Icons.visibility_off_outlined,
        title: t.warnServiceOffTitle,
        text: t.warnServiceOffText,
        action: t.warnServiceOffAction,
        onAction: _openServiceSettings,
      );
    }
    final diag = _diag;
    if (diag == null) return null;
    if (_stoppedConfirmed) {
      return _WarningCard(
        icon: Icons.sync_problem_outlined,
        title: t.warnServiceStoppedTitle,
        text: t.warnServiceStoppedText,
        action: t.warnOpenSettings,
        onAction: _openServiceSettings,
      );
    }
    final limited = !diag.batteryUnrestricted || diag.backgroundRestricted;
    if (_running && limited && !widget.prefs.batteryHintDismissed) {
      return _WarningCard(
        icon: Icons.battery_alert_outlined,
        title: t.warnBatteryTitle,
        text: t.warnBatteryText,
        action: t.warnOpenSettings,
        onAction: TripReader.openAppSettings,
        dismiss: t.warnBatteryDone,
        onDismiss: _dismissBatteryHint,
      );
    }
    return null;
  }

  Future<void> _toggle() async {
    if (_running) {
      await TripReader.setRunning(false);
      return _refresh();
    }
    // With billing on, starting needs an active subscription.
    final subs = widget.subscriptions;
    if (subs.needsSubscription &&
        !await SubscriptionScreen.show(context, subs)) {
      return;
    }
    // First start: the one permission the app needs is asked here, always
    // after the disclosure Google Play requires.
    if (!await TripReader.isServiceEnabled()) {
      if (!mounted) return;
      if (await AccessibilityDisclosureScreen.show(context)) {
        await _openServiceSettings();
      }
      return;
    }
    await TripReader.pushConfig(widget.prefs);
    await TripReader.setRunning(true);
    await _refresh();
  }

  Future<void> _disableService() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_open_outlined),
        title: Text(t.dialogDisableServiceTitle),
        content: Text(t.dialogDisableServiceText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.btnDisableService),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final turnedOff = await TripReader.disableService();
    // Android updates the enabled-services list a moment later.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _refresh();
    if (turnedOff) {
      messenger.showSnackBar(SnackBar(content: Text(t.serviceDisabledNotice)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final warning = _warning(AppLocalizations.of(context));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _running
            ? _RunningCard(onStop: _toggle)
            : _StartButton(onStart: _toggle),
        if (warning != null) ...[const SizedBox(height: 12), warning],
        if (_serviceEnabled) ...[
          const SizedBox(height: 12),
          _ServiceCard(onDisable: _disableService),
        ],
        _PlanStatus(subscriptions: widget.subscriptions),
        const SizedBox(height: 28),
        _Filters(prefs: widget.prefs),
      ],
    );
  }
}

/// The free-beta notice while billing is off, or the subscription's state
/// (with a link to manage it in Play) while it's on.
class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.subscriptions});

  final SubscriptionController subscriptions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: subscriptions,
      builder: (context, _) {
        final subs = subscriptions;
        final beta = subs.betaMessage;
        final ent = subs.entitlement;
        final String text;
        if (beta != null) {
          text = beta;
        } else if (subs.config.paywallEnabled && subs.isSubscribed) {
          final until = ent.expiresAt?.toLocal();
          text = until == null
              ? t.subActive
              : ent.inTrial
              ? t.subTrialUntil(until)
              : t.subActiveUntil(until);
        } else {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppCard(
            padding: EdgeInsets.fromLTRB(16, 14, beta != null ? 16 : 8, 14),
            child: Row(
              children: [
                IconTile(
                  icon: beta != null
                      ? Icons.campaign_outlined
                      : Icons.workspace_premium_outlined,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(text)),
                if (beta == null)
                  TextButton(
                    onPressed: () =>
                        openManageSubscription(subs.config.productId),
                    child: Text(t.btnManageSubscription),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shown while the accessibility service is on: some banking apps won't
/// open until it's off, so it can be turned off here without uninstalling.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.onDisable});

  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Kept compact: it's a secondary action, not the panel's focus.
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          const IconTile(icon: Icons.document_scanner_outlined, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.serviceOnTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  t.serviceOnText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDisable,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(t.btnDisableService),
          ),
        ],
      ),
    );
  }
}

/// Something on the phone keeps the alert from showing, and how to fix it.
class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
    this.dismiss,
    this.onDismiss,
  });

  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback onAction;
  final String? dismiss;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (dismiss != null)
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(dismiss!),
                ),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: Text(action),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Idle state: one wide white button.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(kRadius),
          child: InkWell(
            onTap: onStart,
            borderRadius: BorderRadius.circular(kRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(
                children: [
                  const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.black,
                    size: 34,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      t.btnStartAnalysis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t.panelHintIdle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Running state: status line plus an outlined stop button.
class _RunningCard extends StatelessWidget {
  const _RunningCard({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.panelRunning,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.panelHintRunning,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded),
              label: Text(t.btnStopAnalysis),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Softly pulsing green dot that signals the analysis is live.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Filters extends StatefulWidget {
  const _Filters({required this.prefs});

  final AppPrefs prefs;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late List<TripFilter> _filters = widget.prefs.filters;

  void _update(TripFilter f) {
    setState(
      () => _filters = [for (final x in _filters) x.kind == f.kind ? f : x],
    );
    widget.prefs.setFilter(f).then((_) => TripReader.pushConfig(widget.prefs));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final active = _filters.where((f) => f.enabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                t.filtersTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              t.filtersActive(active),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t.filtersSubtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final f in _filters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FilterCard(filter: f, onChanged: _update),
          ),
      ],
    );
  }
}

String formatFilterValue(AppLocalizations t, FilterKind kind, double v) {
  final n = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);
  return switch (kind) {
    FilterKind.perHour => '\$$n / h',
    FilterKind.perKm => '\$$n / km',
    FilterKind.maxPickupKm => t.filterMaxPickupValue(n),
  };
}

/// One minimum: switch to turn it on; value and slider only while on.
class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.filter, required this.onChanged});

  final TripFilter filter;
  final ValueChanged<TripFilter> onChanged;

  static const _icons = {
    FilterKind.perHour: Icons.schedule_outlined,
    FilterKind.perKm: Icons.route_outlined,
    FilterKind.maxPickupKm: Icons.person_pin_circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final on = filter.enabled;
    final kind = filter.kind;
    final (label, hint) = switch (kind) {
      FilterKind.perHour => (t.filterPerHour, t.filterPerHourHint),
      FilterKind.perKm => (t.filterPerKm, t.filterPerKmHint),
      FilterKind.maxPickupKm => (t.filterMaxPickup, t.filterMaxPickupHint),
    };

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: _icons[kind]!,
                color: on ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      on
                          ? formatFilterValue(t, kind, filter.value)
                          : t.filterOff,
                      style: TextStyle(
                        color: on ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: on,
                onChanged: (v) => onChanged(filter.copyWith(enabled: v)),
              ),
            ],
          ),
          if (on) ...[
            Slider(
              value: filter.value,
              min: kind.min,
              max: kind.max,
              divisions: ((kind.max - kind.min) / kind.step).round(),
              label: formatFilterValue(t, kind, filter.value),
              onChanged: (v) => onChanged(filter.copyWith(value: v)),
            ),
            Text(
              hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
