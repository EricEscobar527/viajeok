import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../data/trip_filters.dart';
import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'accessibility_disclosure_screen.dart';

/// Home: start/stop the analysis and the minimums (filters) that decide
/// green vs red.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> with WidgetsBindingObserver {
  bool _running = false;
  bool _serviceEnabled = false;

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

  // Re-read the state when coming back from DiDi/Uber or from Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final running = await TripReader.isRunning();
    final enabled = await TripReader.isServiceEnabled();
    if (mounted) {
      setState(() {
        _running = running;
        _serviceEnabled = enabled;
      });
    }
  }

  Future<void> _toggle() async {
    if (_running) {
      await TripReader.setRunning(false);
      return _refresh();
    }
    // First start: the one permission the app needs is asked here, always
    // after the disclosure Google Play requires.
    if (!await TripReader.isServiceEnabled()) {
      if (!mounted) return;
      if (await AccessibilityDisclosureScreen.show(context)) {
        await TripReader.openServiceSettings();
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _running
            ? _RunningCard(onStop: _toggle)
            : _StartButton(onStart: _toggle),
        if (_serviceEnabled) ...[
          const SizedBox(height: 12),
          _ServiceCard(onDisable: _disableService),
        ],
        const SizedBox(height: 28),
        _Filters(prefs: widget.prefs),
      ],
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
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          const IconTile(icon: Icons.document_scanner_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.serviceOnTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  t.serviceOnText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDisable,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(t.btnDisableService),
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
