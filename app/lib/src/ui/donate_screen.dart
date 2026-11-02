// SPDX-License-Identifier: Apache-2.0
/// Settings › Donate on the phone (item 4): BT Labs' donation address with Copy and QR, and
/// BT Labs' contact, opened in Contacts, while this wallet's Contacts hold it. Opening the
/// screen asks nothing on the network.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactsProvider;
import '../donate.dart';
import '../l10n.dart';
import 'address_view.dart' show MarkedAddress;
import 'common.dart';
import 'contact_page.dart' show openContactPage;
import 'settings_rows.dart' show SettingsHeader;
import 'theme/brand.dart' show MarkedQr;
import 'theme/tokens.dart';

/// The keys of the Donate screen's parts, for tests.
const Key donateCopyKey = ValueKey('donate-copy');
const Key donateQrKey = ValueKey('donate-qr');
const Key donateContactKey = ValueKey('donate-contact');

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key});

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  /// Read once when the screen opens: what it copies is what it showed.
  late final String? _address = ref.read(donateLinkProvider).address;
  bool _qr = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final address = _address;
    final contact = donateContactIn(ref.watch(contactsProvider).value ?? const [], address, (c) => c.epicbox);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.settingsDonate)),
      body: ScreenBody(
        children: [
          Text(l.donateLead, style: text.bodyMedium?.copyWith(color: t.dim)),
          // No address in app-config.toml: the lead alone (Settings hides the entry then).
          if (address != null) ...[
            SettingsHeader.inBody(l.donateAddress),
            Container(
              decoration: t.well,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 4),
              child: Row(
                children: [
                  Expanded(child: MarkedAddress(address, selectable: true)),
                  IconButton(
                    key: donateCopyKey,
                    tooltip: l.helpDonateCopy,
                    color: t.accentText,
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => copyText(context, address, l.helpDonateCopied),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: donateQrKey,
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: Icon(_qr ? Icons.qr_code_2 : Icons.qr_code),
                label: Text(_qr ? l.receiveHttpHideQr : l.qrShow),
                onPressed: () => setState(() => _qr = !_qr),
              ),
            ),
            if (_qr)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Dark modules on white scan reliably in either theme.
                    color: protocolLight.surface,
                    borderRadius: BorderRadius.circular(t.radiusSmall),
                  ),
                  child: Semantics(
                    label: l.donateQrLabel,
                    image: true,
                    child: MarkedQr(data: address, size: 220),
                  ),
                ),
              ),
            // BT Labs' contact, only while this wallet's Contacts hold it.
            if (contact != null) ...[
              const SizedBox(height: 8),
              ListTile(
                key: donateContactKey,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(contact.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(l.donateInContacts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openContactPage(context, contact),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
