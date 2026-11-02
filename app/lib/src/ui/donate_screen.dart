// SPDX-License-Identifier: Apache-2.0
/// Settings › Donate on the phone (item 4): BT Labs' donation page, from settings.toml
/// ([donateLinkProvider], never a host in the code), with the donation address (Copy, QR) and
/// the contact page beside it. When the page does not answer ([checkDonatePage]) a notice
/// says so and the address and the contact page are the way; in Node only and Kill switch it
/// is not asked. The phone opens no browser: links are copied, as everywhere else in Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address_format.dart' show shownUrl;
import '../donate.dart';
import '../l10n.dart';
import 'address_view.dart' show MarkedAddress;
import 'common.dart';
import 'settings_rows.dart' show SettingsHeader;
import 'theme/brand.dart' show MarkedQr;
import 'theme/tokens.dart';

/// The keys of the Donate screen's parts, for tests.
const Key donatePageKey = ValueKey('donate-page');
const Key donatePageDownKey = ValueKey('donate-page-down');
const Key donateCopyKey = ValueKey('donate-copy');
const Key donateQrKey = ValueKey('donate-qr');
const Key donateContactKey = ValueKey('donate-contact');

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key, this.check = checkDonatePage});

  /// Asks the donation page; a stand-in in tests.
  final Future<DonateCheck> Function(DonateLink link) check;

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  /// Read once when the screen opens: a settings.toml edited meanwhile changes nothing here.
  late final DonateLink _link = ref.read(donateLinkProvider);

  /// What asking the donation page found; null while asking.
  DonateCheck? _check;
  bool _qr = false;

  @override
  void initState() {
    super.initState();
    if (_link.page != null) {
      widget.check(_link).then((c) {
        if (mounted) setState(() => _check = c);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final url = _link.page;
    final address = _link.address;
    final contact = _link.contact;
    // The page is gone, or not set: the address and the contact page are the way. While it is
    // asked, and when nothing may be asked (Node only, Kill switch), its link stays.
    final down = url == null || _check == DonateCheck.noAnswer;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.settingsDonate)),
      body: ScreenBody(
        children: [
          Text(l.donateLead, style: text.bodyMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 16),
          if (url != null && down)
            Container(
              key: donatePageDownKey,
              decoration: t.well,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: t.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l.donatePageDown, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const TextSpan(text: ' '),
                          TextSpan(text: l.donatePageDownText),
                        ],
                      ),
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          if (url != null && !down)
            _LinkRow(
              key: donatePageKey,
              icon: Icons.volunteer_activism_outlined,
              title: l.donatePage,
              url: url.toString(),
            ),
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
          ],
          if (contact != null) ...[
            const SizedBox(height: 16),
            _LinkRow(
              key: donateContactKey,
              icon: Icons.mail_outline,
              title: l.donateContact,
              url: contact.toString(),
            ),
          ],
          // Nothing in settings.toml and no address: say so rather than show an empty page.
          if (url == null && address == null && contact == null)
            Text(l.donateNothing, style: text.bodyMedium?.copyWith(color: t.dim)),
        ],
      ),
    );
  }
}

/// A link as Settings shows one: its name, the address without the scheme, Copy at the end.
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.icon, required this.title, required this.url});

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(shownUrl(url), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.copy, semanticLabel: l.settingsCopyLink),
      onTap: () => copyText(context, url, l.settingsLinkCopied),
    );
  }
}
