/// Export contacts and Import contacts on the desktop (the Contacts header's More menu): the
/// shared address book to a file and back (`contacts_file.dart`), through the system Save and
/// Open dialogs. Import says what it does in a dialog before anything is saved.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contact_store.dart' show ContactFields;
import '../../../contacts_file.dart';
import '../../../legacy/gui_contacts.dart' show AddressChecks;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/history_files.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// Keys for tests.
const Key deskContactsMoreKey = ValueKey('desk-contacts-more');
const Key deskContactsImportKey = ValueKey('desk-contacts-import');
const Key deskContactsExportKey = ValueKey('desk-contacts-export');
const Key deskContactsImportDoKey = ValueKey('desk-contacts-import-do');
const Key deskContactsExportDoKey = ValueKey('desk-contacts-export-do');

ContactFields _fields(Contact c) =>
    ContactFields(id: c.id, name: c.name, epicbox: c.epicbox, http: c.http, tor: c.tor, note: c.note);

/// The header's More button: Import contacts, Export contacts (off with nothing to export).
class ContactsMoreButton extends ConsumerWidget {
  const ContactsMoreButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    // A contact without an address (a pairing's) goes as its name and note.
    final canExport = ref.watch(deskProvider.select((s) => (s.contacts ?? const <Contact>[]).isNotEmpty));
    Widget item(Key key, IconData icon, String label, VoidCallback? run) => MenuItemButton(
      key: key,
      onPressed: run,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(200.u, 40.u)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.s3 : null,
        ),
      ),
      leadingIcon: Icon(icon, size: Ctl.iconSm, color: run == null ? c.faint : c.dim),
      child: Text(label, style: run == null ? ts.body.copyWith(color: c.faint) : ts.body),
    );
    return MenuAnchor(
      consumeOutsideTap: true,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.s4),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.all(Sp.x2)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
        ),
      ),
      menuChildren: [
        item(deskContactsImportKey, EIcons.fileDown, l.contactsImport, () => deskImportContacts(context)),
        item(deskContactsExportKey, EIcons.fileUp, l.contactsExport, canExport ? () => deskExportContacts(context) : null),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
        child: EIconButton(
          key: deskContactsMoreKey,
          icon: EIcons.dots,
          label: l.contactMore,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// Says what the file holds, then saves the address book where the user chooses, then a toast
/// with Open folder.
Future<void> deskExportContacts(BuildContext context) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final l = context.l10n;
  final api = ref.read(deskApiProvider);
  final all = exportableContacts([for (final c in ref.read(deskProvider).contacts ?? const <Contact>[]) _fields(c)]);
  if (all.isEmpty) return;
  final go = await showEDialog<bool>(
    context,
    builder: (context) => EDialog(
      title: l.contactsExport,
      icon: EIcons.fileUp,
      width: 520.u,
      body: Text(l.contactsExportHolds, style: context.ts.body),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(key: deskContactsExportDoKey, label: l.deskConExportDo, onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final now = DateTime.now();
  try {
    final path = await ref
        .read(deskHistoryFilesProvider)
        .save(
          name: contactsExportFileName(now),
          bytes: utf8.encode(encodeContactsFile(all, network: api.network, now: now)),
          title: l.contactsExport,
        );
    if (path == null || !context.mounted) return;
    showEToast(
      context,
      l.contactsExported(all.length),
      text: path,
      tone: ETone.ok,
      action: (
        label: l.deskFinOpenFolder,
        run: () async {
          if (!await ref.read(deskOpenFolderProvider)(File(path).parent.path) && context.mounted) {
            showEToast(context, l.deskFinFolderNotOpened, text: path, tone: ETone.warn);
          }
        },
      ),
    );
  } on Object catch (e) {
    if (context.mounted) showEToast(context, l.contactsExport, text: deskErrorText(e, l), tone: ETone.risk);
  }
}

/// Picks a contacts file, shows what importing it does, and saves on Import.
Future<void> deskImportContacts(BuildContext context) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final l = context.l10n;
  final api = ref.read(deskApiProvider);
  final ContactsImportPlan plan;
  try {
    final picked = await ref
        .read(deskHistoryFilesProvider)
        .pick(title: l.contactsImport, extensions: const ['json'], maxBytes: maxContactsFileBytes);
    if (picked == null) return;
    plan = planContactsFile(
      readContactsFile(picked.bytes),
      [for (final c in ref.read(deskProvider).contacts ?? const <Contact>[]) _fields(c)],
      AddressChecks(epicbox: api.isEpicboxAddress, onion: api.isOnionAddress, http: (url) => parseAddress(url, api).complete),
      network: api.network,
      otherChain: api.epicboxAddressOtherChain,
    );
  } on ContactsFileError catch (e) {
    if (context.mounted) await _failed(context, e.text(l));
    return;
  } on HistoryFileError {
    // Larger than any contacts file.
    if (context.mounted) await _failed(context, l.contactsImportNotFile);
    return;
  } on Object catch (e) {
    if (context.mounted) await _failed(context, deskErrorText(e, l));
    return;
  }
  if (!context.mounted) return;
  final go = await showEDialog<bool>(context, builder: (_) => _ImportConfirm(plan: plan));
  if (go != true || !context.mounted) return;
  final byId = {for (final c in ref.read(deskProvider).contacts ?? const <Contact>[]) c.id: c};
  final changes = <Contact>[];
  await applyContactsImport(plan, (c) async {
    // A saved contact gains only the kinds and the note it lacked; its star stays.
    final was = byId[c.id];
    changes.add(
      Contact(
        id: c.id,
        name: was?.name ?? c.name,
        epicbox: was?.epicbox ?? c.epicbox,
        http: was?.http ?? c.http,
        tor: was?.tor ?? c.tor,
        note: (was?.note ?? '').trim().isEmpty ? c.note : was!.note,
        favourite: was?.favourite ?? false,
        lastUsed: was?.lastUsed,
        hasPicture: was?.hasPicture ?? false,
      ),
    );
  });
  try {
    await ref.read(deskProvider.notifier).saveContacts(changes);
    if (context.mounted) showEToast(context, contactsImportedText(l, plan), tone: ETone.ok);
  } on Object catch (e) {
    if (context.mounted) showEToast(context, l.contactsImport, text: deskErrorText(e, l), tone: ETone.risk);
  }
}

Future<void> _failed(BuildContext context, String message) => showEDialog<void>(
  context,
  builder: (context) => EDialog(
    title: context.l10n.contactsImport,
    icon: EIcons.fileDown,
    width: 520.u,
    body: ENotice(title: message, tone: ETone.risk),
    actions: [EButton(label: context.l10n.commonClose, onPressed: () => Navigator.pop(context))],
  ),
);

/// What the import does, line by line, with Import and Cancel.
class _ImportConfirm extends StatelessWidget {
  const _ImportConfirm({required this.plan});

  final ContactsImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final lines = [
      if (plan.add.isNotEmpty) (EIcons.userPlus, l.contactsImportNew(plan.add.length), true),
      if (plan.update.isNotEmpty) (EIcons.pencil, l.contactsImportMerged(plan.update.length), true),
      if (plan.same > 0) (EIcons.check, l.contactsImportSame(plan.same), false),
      if (plan.leftOut > 0) (EIcons.close, l.contactsImportLeftOut(plan.leftOut), false),
      if (plan.otherNetwork > 0) (EIcons.close, l.contactsImportOtherNet(plan.otherNetwork), false),
    ];
    return EDialog(
      title: l.contactsImportTitle,
      description: plan.hasChanges ? null : l.contactsImportNothing,
      icon: EIcons.fileDown,
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (icon, text, strong) in lines)
            Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: Ctl.iconSm, color: c.dim),
                  SizedBox(width: Sp.x3),
                  Expanded(child: Text(text, style: strong ? ts.body : ts.bodyDim)),
                ],
              ),
            ),
          SizedBox(height: Sp.x3),
          Text(l.contactsImportKeeps, style: ts.small),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(
          key: deskContactsImportDoKey,
          label: l.contactsImportDo,
          onPressed: plan.hasChanges ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }
}
