/// What a pairing link or a sealed file meets while Pairing (or an invoice while Invoices) is
/// off in Settings › Advanced › Experimental: it is experimental, and Open Advanced goes there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../scan_result_sheet.dart';
import '../settings_sections.dart' show openSettingsSection;
import '../settings_screen.dart' show SettingsSection;

Future<void> showExperimentalOffSheet(BuildContext context, WidgetRef ref, {bool invoices = false}) async {
  final l = context.l10n;
  final open = await showScanResultSheet(
    context,
    icon: invoices ? Icons.request_quote_outlined : Icons.handshake_outlined,
    title: invoices ? l.expInvoicesOffTitle : l.expPairingOffTitle,
    text: invoices ? l.expInvoicesOffBody : l.expPairingOffBody,
    secondary: l.commonClose,
    primary: l.expOpenAdvanced,
  );
  if (open && context.mounted) await openSettingsSection(context, SettingsSection.advanced);
}
