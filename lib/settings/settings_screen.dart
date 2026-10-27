import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Opened from the header's gear: the popup labels. While on, the user
/// writes up to [AppPrefs.maxLabels] short texts for green and for red
/// popups; the service shows one at random on top of each popup.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _on = widget.prefs.labelsEnabled;

  Future<void> _setOn(bool on) async {
    setState(() => _on = on);
    await widget.prefs.setLabelsEnabled(on);
    await TripReader.pushConfig(widget.prefs);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  IconTile(
                    icon: Icons.sell_outlined,
                    color: _on ? AppColors.accent : AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.labelsTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _on ? t.labelsOn : t.labelsOff,
                          style: TextStyle(
                            color: _on ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _on, onChanged: _setOn),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.labelsHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (_on) ...[
              const SizedBox(height: 20),
              _LabelList(prefs: widget.prefs, accept: true),
              const SizedBox(height: 16),
              _LabelList(prefs: widget.prefs, accept: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// The texts for one verdict: a field per text, remove buttons, and
/// "Agregar texto" until the limit.
class _LabelList extends StatefulWidget {
  const _LabelList({required this.prefs, required this.accept});

  final AppPrefs prefs;
  final bool accept;

  @override
  State<_LabelList> createState() => _LabelListState();
}

class _LabelListState extends State<_LabelList> {
  late final List<TextEditingController> _fields = [
    for (final text in widget.prefs.labels(accept: widget.accept))
      TextEditingController(text: text),
  ];

  @override
  void initState() {
    super.initState();
    // Turning labels on shows one empty field to start with.
    if (_fields.isEmpty) _fields.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await widget.prefs.setLabels([
      for (final c in _fields) c.text,
    ], accept: widget.accept);
    await TripReader.pushConfig(widget.prefs);
  }

  void _add() {
    setState(() => _fields.add(TextEditingController()));
    _save();
  }

  void _remove(int i) {
    setState(() => _fields.removeAt(i).dispose());
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = widget.accept ? AppColors.green : AppColors.red;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: widget.accept ? Icons.check_rounded : Icons.close_rounded,
                color: color,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.accept ? t.labelsAccepted : t.labelsRejected,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  t.labelsCount(_fields.length, AppPrefs.maxLabels),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, field) in _fields.indexed)
            Padding(
              key: ObjectKey(field),
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: field,
                      maxLength: AppPrefs.maxLabelLength,
                      onChanged: (_) => _save(),
                      decoration: InputDecoration(
                        hintText: widget.accept
                            ? t.labelsAcceptedExample
                            : t.labelsRejectedExample,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: t.labelsRemove,
                    onPressed: () => _remove(i),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (_fields.length < AppPrefs.maxLabels)
            TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.labelsAdd),
            ),
        ],
      ),
    );
  }
}
