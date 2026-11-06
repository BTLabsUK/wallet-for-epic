// SPDX-License-Identifier: Apache-2.0
/// Export contacts and Import contacts on the phone (the Contacts list's More menu): the shared
/// address book to a file and back (`contacts_file.dart`). The file leaves the app like a
/// history backup, through Share or Save to device; it comes back through the file picker, then
/// a sheet says what the import does before anything is saved.
library;

import 'phone_sheet.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contact_label.dart';
import '../contact_store.dart' show ContactFields;
import '../contacts.dart';
import '../contacts_file.dart';
import '../errors.dart';
import '../l10n.dart';
import '../legacy/gui_contacts.dart' show AddressChecks;
import '../providers.dart';
import '../settings.dart';
import 'common.dart';
import 'settings_history.dart' show handOverFile, historyFilesProvider;
import 'theme/tokens.dart';
import 'method_names.dart' show recipientMethodWord;

/// Keys for tests.
const Key contactsImportDoKey = ValueKey('contacts-import-do');

ContactFields _fields(Contact c) =>
    ContactFields(id: c.id, name: c.name, epicbox: c.epicbox, http: c.http, tor: c.tor, note: c.note, label: c.label);

/// Writes the address book to a file and hands it over. Returns true once saved or shared.
Future<bool> exportContacts(BuildContext context, WidgetRef ref) async {
  final config = ref.read(walletConfigProvider);
  final l = context.l10n;
  try {
    final all = exportableContacts([for (final c in await ref.read(contactsProvider.future)) _fields(c)]);
    if (all.isEmpty || config == null || !context.mounted) return false;
    final now = ref.read(clockProvider)();
    final text = encodeContactsFile(all, network: config.chain.name, now: now);
    return await handOverFile(
      context,
      ref,
      name: contactsExportFileName(now),
      bytes: Uint8List.fromList(utf8.encode(text)),
      title: l.contactsExport,
      note: l.contactsExportHolds,
      saveDialogTitle: l.contactsExport,
      doneNotice: l.contactsExported(all.length),
    );
  } catch (error) {
    if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    return false;
  }
}

/// Picks a contacts file, shows what importing it does, and saves on Import. Returns true when
/// contacts were saved.
Future<bool> importContacts(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final l = context.l10n;
  final service = ref.read(walletServiceProvider);
  final ContactsImportPlan plan;
  try {
    final bytes = await ref
        .read(autoLockHoldProvider.notifier)
        .during(() => ref.read(historyFilesProvider).pick(dialogTitle: l.contactsImport));
    if (bytes == null) return false;
    final file = readContactsFile(bytes);
    final saved = await ref.read(contactsProvider.future);
    plan = planContactsFile(
      file,
      [for (final c in saved) _fields(c)],
      AddressChecks(
        epicbox: (a) => service.validateEpicboxAddress(address: a),
        onion: (a) => service.validateOnionAddress(address: a),
      ),
      network: config.chain.name,
      otherChain: (a) => service.epicboxAddressOtherChain(address: a),
    );
  } on ContactsFileError catch (e) {
    if (context.mounted) await _sheet(context, (context) => _ImportFailed(message: e.text(context.l10n)));
    return false;
  } on LocalizedFormatException {
    // Too large for the picker: far larger than any contacts file.
    if (context.mounted) await _sheet(context, (context) => _ImportFailed(message: context.l10n.contactsImportNotFile));
    return false;
  } catch (error) {
    // A file that could not be read.
    if (context.mounted) await _sheet(context, (context) => _ImportFailed(message: describeError(context.l10n, error)));
    return false;
  }
  if (!context.mounted) return false;
  final go = await _sheet<bool>(context, (context) => _ImportConfirm(plan: plan));
  if (go != true || !context.mounted) return false;
  final notices = ref.read(noticeProvider.notifier);
  try {
    final byId = {for (final c in await ref.read(contactsProvider.future)) c.id: c};
    await applyContactsImport(plan, (c) async {
      // A saved contact gains only the kinds and the note it lacked, whatever changed since.
      final was = byId[c.id];
      await session.saveContact(
        contact: Contact(
          id: c.id,
          name: was?.name ?? c.name,
          epicbox: was?.epicbox ?? c.epicbox,
          http: was?.http ?? c.http,
          tor: was?.tor ?? c.tor,
          note: (was?.note ?? '').trim().isEmpty ? c.note : was!.note,
          label: was == null || was.label == ContactLabel.wallet ? c.label : was.label,
        ),
      );
    });
    notices.show(contactsImportedText(l, plan), level: NoticeLevel.success);
    return true;
  } catch (error) {
    notices.show(describeError(l, error), level: NoticeLevel.error);
    return false;
  } finally {
    ref.invalidate(contactsProvider);
  }
}

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) => showPhoneSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: builder,
);

/// What the import does, line by line, with Import and Cancel.
class _ImportConfirm extends StatelessWidget {
  const _ImportConfirm({required this.plan});

  final ContactsImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final lines = [
      if (plan.add.isNotEmpty) (Icons.person_add_alt, l.contactsImportNew(plan.add.length), t.text),
      if (plan.update.isNotEmpty) (Icons.edit_note, l.contactsImportMerged(plan.update.length), t.text),
      for (final a in plan.addedToSaved)
        (Icons.add_link, l.contactsImportAddsAddress(a.name, recipientMethodWord(l, a.kind), a.address), t.text),
      if (plan.same > 0) (Icons.check, l.contactsImportSame(plan.same), t.dim),
      if (plan.leftOut > 0) (Icons.block, l.contactsImportLeftOut(plan.leftOut), t.dim),
      if (plan.otherNetwork > 0) (Icons.public_off_outlined, l.contactsImportOtherNet(plan.otherNetwork), t.dim),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(header: true, child: Text(l.contactsImportTitle, style: theme.textTheme.titleLarge)),
          if (!plan.hasChanges) ...[
            const SizedBox(height: 8),
            Text(l.contactsImportNothing, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          for (final (icon, text, color) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: t.dim),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(l.contactsImportKeeps, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          const SizedBox(height: 20),
          FilledButton(
            key: contactsImportDoKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: plan.hasChanges ? () => Navigator.pop(context, true) : null,
            child: Text(l.contactsImportDo),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
        ],
      ),
    );
  }
}

/// A file the import refuses: why, and Close.
class _ImportFailed extends StatelessWidget {
  const _ImportFailed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(header: true, child: Text(l.contactsImport, style: theme.textTheme.titleLarge)),
          const SizedBox(height: 16),
          InlineNotice(level: NoticeLevel.error, text: message, liveRegion: true),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonClose),
          ),
        ],
      ),
    );
  }
}
