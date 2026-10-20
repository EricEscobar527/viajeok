import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../data/trip_filters.dart';
import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// "Inicio" tab: start/stop analysis, session counters and trip filters.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> with WidgetsBindingObserver {
  bool _running = false;
  TripStats _stats = TripStats.zero;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  // Counters change in the background service while the driver is in
  // Uber/DiDi, so re-read them when coming back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final running = await TripReader.isRunning();
    final stats = await TripReader.stats();
    if (!mounted) return;
    setState(() {
      _running = running;
      _stats = stats;
    });
    _poll?.cancel();
    if (running) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    }
  }

  Future<void> _toggle() async {
    if (_running) {
      await TripReader.setRunning(false);
      return _refresh();
    }
    if (!await TripReader.isServiceEnabled()) {
      final open = await _confirm(
        title: (t) => t.dialogEnableServiceTitle,
        text: (t) => t.dialogEnableServiceText,
        action: (t) => t.btnOpenSettings,
      );
      if (open) await TripReader.openServiceSettings();
      return;
    }
    await TripReader.pushConfig(widget.prefs);
    await TripReader.setRunning(true);
    await _refresh();
  }

  Future<bool> _confirm({
    required String Function(AppLocalizations) title,
    required String Function(AppLocalizations) text,
    required String Function(AppLocalizations) action,
  }) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title(t)),
        content: Text(text(t)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action(t)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _StartCard(running: _running, onToggle: _toggle),
        const SizedBox(height: 16),
        _StatsRow(
          total: _stats.total,
          accepted: _stats.accepted,
          rejected: _stats.rejected,
        ),
        const SizedBox(height: 16),
        _FiltersCard(prefs: widget.prefs),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.running, required this.onToggle});

  final bool running;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AppCard(
      borderColor: running ? AppColors.accent : AppColors.border,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              running ? t.panelRunning : t.panelReady,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSoft,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: running ? AppColors.red : AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: (running ? AppColors.red : AppColors.accent)
                            .withValues(alpha: 0.4),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Icon(
                    running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            running ? t.panelTapToStop : t.panelTapToStart,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.accepted,
    required this.rejected,
  });

  final int total;
  final int accepted;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget stat(int value, String label, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
    const divider = SizedBox(
      height: 40,
      child: VerticalDivider(color: AppColors.border),
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          stat(total, t.statTotal, AppColors.textPrimary),
          divider,
          stat(accepted, t.statAccept, AppColors.green),
          divider,
          stat(rejected, t.statReject, AppColors.red),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatefulWidget {
  const _FiltersCard({required this.prefs});

  final AppPrefs prefs;

  @override
  State<_FiltersCard> createState() => _FiltersCardState();
}

class _FiltersCardState extends State<_FiltersCard> {
  late List<TripFilter> _filters = widget.prefs.filters;
  bool _expanded = true;
  FilterKind? _open;

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

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const IconTile(icon: Icons.tune_rounded, circle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.filtersTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (active > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      t.filtersActive(active),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            for (final f in _filters)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FilterTile(
                  filter: f,
                  open: _open == f.kind,
                  onOpen: () =>
                      setState(() => _open = _open == f.kind ? null : f.kind),
                  onChanged: _update,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String formatFilterValue(AppLocalizations t, FilterKind kind, double v) {
  final n = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);
  return switch (kind) {
    FilterKind.perHour => '\$ $n / h',
    FilterKind.perKm => '\$ $n / km',
    FilterKind.maxPickupKm => t.filterMaxPickupValue(n),
  };
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.filter,
    required this.open,
    required this.onOpen,
    required this.onChanged,
  });

  final TripFilter filter;
  final bool open;
  final VoidCallback onOpen;
  final ValueChanged<TripFilter> onChanged;

  static const _icons = {
    FilterKind.perHour: Icons.timer_rounded,
    FilterKind.perKm: Icons.trending_up_rounded,
    FilterKind.maxPickupKm: Icons.near_me_rounded,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? AppColors.accent : AppColors.border,
          width: on ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconTile(
                    icon: _icons[kind]!,
                    color: on ? AppColors.accent : AppColors.textMuted,
                    circle: true,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 16)),
                        Text(
                          on
                              ? formatFilterValue(t, kind, filter.value)
                              : t.filterOff,
                          style: TextStyle(
                            color: on ? AppColors.accent : AppColors.textMuted,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OnOffPill(
                    on: on,
                    onTap: () => onChanged(filter.copyWith(enabled: !on)),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Slider(
                    value: filter.value,
                    min: kind.min,
                    max: kind.max,
                    divisions: ((kind.max - kind.min) / kind.step).round(),
                    label: formatFilterValue(t, kind, filter.value),
                    // Moving the slider implies the user wants the filter on.
                    onChanged: (v) =>
                        onChanged(filter.copyWith(value: v, enabled: true)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OnOffPill extends StatelessWidget {
  const _OnOffPill({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          on ? 'ON' : 'OFF',
          style: TextStyle(
            color: on ? AppColors.accent : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
