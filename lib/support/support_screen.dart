import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/support_api.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Support form: pick the problem, fill the fields it needs, send.
class SupportScreen extends StatefulWidget {
  SupportScreen({super.key, SupportApi? api})
    : api = api ?? SupportApi.create();

  final SupportApi api;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _maxScreenshots = 5;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _form = GlobalKey<FormState>();
  final _phoneModel = TextEditingController();
  final _email = TextEditingController();
  final _description = TextEditingController();

  SupportIssue? _issue;
  List<XFile> _screenshots = [];
  bool _sending = false;

  @override
  void dispose() {
    _phoneModel.dispose();
    _email.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshots() async {
    final picked = await ImagePicker().pickMultiImage(
      limit: _maxScreenshots,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    setState(() {
      _screenshots = [
        ..._screenshots,
        ...picked,
      ].take(_maxScreenshots).toList();
    });
  }

  Future<void> _send() async {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final issue = _issue!;
    final detailed = issue.needsDeviceDetails;

    setState(() => _sending = true);
    try {
      await widget.api.submit(
        SupportTicket(
          issue: issue,
          phoneModel: detailed ? _phoneModel.text.trim() : null,
          email: _email.text.trim(),
          description: detailed ? null : _description.text.trim(),
          screenshotPaths: detailed
              ? [for (final s in _screenshots) s.path]
              : const [],
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.supportSendError)));
      return;
    }
    if (!mounted) return;
    setState(() => _sending = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined),
        title: Text(t.supportSentTitle),
        content: Text(t.supportSentText),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.supportSentOk),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final issue = _issue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(t.supportTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Label(t.supportIssueLabel),
              FormField<SupportIssue>(
                validator: (_) =>
                    _issue == null ? t.supportIssueRequired : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final i in SupportIssue.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IssueOption(
                          icon: _issueIcon(i),
                          label: _issueLabel(t, i),
                          selected: issue == i,
                          onTap: () {
                            setState(() => _issue = i);
                            field.didChange(i);
                          },
                        ),
                      ),
                    if (field.hasError)
                      Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (issue != null && issue.needsDeviceDetails) ...[
                const SizedBox(height: 20),
                _Label(t.supportPhoneModel),
                TextFormField(
                  controller: _phoneModel,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(hint: t.supportPhoneModelHint),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? t.supportFieldRequired : null,
                ),
                const SizedBox(height: 20),
                _Label(t.supportScreenshots),
                _ScreenshotPicker(
                  files: _screenshots,
                  max: _maxScreenshots,
                  onAdd: _pickScreenshots,
                  onRemove: (f) => setState(
                    () => _screenshots = [..._screenshots]..remove(f),
                  ),
                ),
              ],
              if (issue == SupportIssue.other) ...[
                const SizedBox(height: 20),
                _Label(t.supportDescription),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(hint: t.supportDescriptionHint),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? t.supportFieldRequired : null,
                ),
              ],
              // Every report needs a way to answer it.
              if (issue != null) ...[
                const SizedBox(height: 20),
                _Label(t.supportEmail),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: _inputDecoration(hint: t.supportEmailHint),
                  validator: (v) {
                    final email = (v ?? '').trim();
                    if (email.isEmpty) return t.supportFieldRequired;
                    return _emailPattern.hasMatch(email)
                        ? null
                        : t.supportEmailInvalid;
                  },
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: _sending ? t.supportSending : t.supportSend,
                icon: Icons.send_rounded,
                onPressed: _sending ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _issueIcon(SupportIssue i) => switch (i) {
    SupportIssue.wrongCalculation => Icons.calculate_outlined,
    SupportIssue.alertNotShown => Icons.notifications_off_outlined,
    SupportIssue.other => Icons.chat_bubble_outline_rounded,
  };

  String _issueLabel(AppLocalizations t, SupportIssue i) => switch (i) {
    SupportIssue.wrongCalculation => t.supportIssueWrongCalculation,
    SupportIssue.alertNotShown => t.supportIssueAlertNotShown,
    SupportIssue.other => t.supportIssueOther,
  };

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: const BorderSide(color: AppColors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: const BorderSide(color: AppColors.red),
    ),
  );
}

/// One selectable problem: icon, full text, and a check when chosen.
class _IssueOption extends StatelessWidget {
  const _IssueOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surfaceHigh : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                IconTile(
                  icon: icon,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(selected),
                    color: selected ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );
}

/// Thumbnails of the picked screenshots plus an "add" tile.
class _ScreenshotPicker extends StatelessWidget {
  const _ScreenshotPicker({
    required this.files,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> files;
  final int max;
  final VoidCallback onAdd;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final f in files)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(f.path),
                      width: 76,
                      height: 120,
                      fit: BoxFit.cover,
                      cacheWidth: 228,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton.filled(
                      tooltip: t.supportRemoveScreenshot,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceHigh,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: () => onRemove(f),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            if (files.length < max)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.supportAddScreenshot,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          t.supportScreenshotsHint(max),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
