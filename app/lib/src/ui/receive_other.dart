// SPDX-License-Identifier: Apache-2.0
/// "Other ways to receive" (Receive-4): the sheet that lists In person, With a file and, where
/// the app has Tor, the Tor address, and the page each of them opens. Each page is today's card
/// for that way, in the redesign's parts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../settings.dart';
import '../tor_phone.dart';
import '../tor_routes.dart' show TorState;
import '../trust_ids.dart';
import 'common.dart';
import 'file_open_screen.dart';
import 'handshake.dart';
import 'kit/kit_button.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'net_block.dart';
import 'network_mode_text.dart';
import 'receive_screen.dart';
import 'request_qr_screen.dart' show openQrRequest;
import 'settings_screen.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';

/// Which of the other ways are offered, from the settings and the device.
class OtherWays {
  const OtherWays({required this.inPerson, required this.file, required this.tor});

  final bool inPerson;
  final bool file;
  final bool tor;

  bool get any => inPerson || file || tor;
}

/// Opens the sheet of [ways].
Future<void> showOtherWays(BuildContext context, {required OtherWays ways}) =>
    showKitSheet<void>(context: context, builder: (_) => _OtherWaysSheet(ways: ways));

void _open(BuildContext sheetContext, Widget page) {
  final navigator = Navigator.of(sheetContext);
  navigator.pop();
  navigator.push(MaterialPageRoute<void>(builder: (_) => page));
}

class _OtherWaysSheet extends ConsumerWidget {
  const _OtherWaysSheet({required this.ways});

  final OtherWays ways;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final torOff =
        !(ref.watch(appSettingsProvider.select((s) => s.value?.payments.linkTor)) ?? PaymentPrefs.defaults.linkTor) ||
        phoneTorState(ref.watch(phoneTorProvider)) == TorState.off;
    return TrustId(
      TrustIds.receiveOtherSheet,
      child: KitSheet(
        title: l.phoneRecvOther,
        secondary: KitButton(
          label: l.commonCancel,
          kind: KitButtonKind.ghost,
          semanticsId: TrustIds.receiveOtherCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(l.phoneRecvOtherSheetLine, style: KitType.rowSub.copyWith(color: t.dim)),
            ),
            KitGroup(
              onSheet: true,
              children: [
                if (ways.inPerson)
                  KitRow(
                    size: KitRowSize.sheet,
                    leading: KitIconWell(KitIcons.qr),
                    title: l.phoneSettingsInPerson,
                    subtitle: l.phoneRecvInPersonLine,
                    chevron: true,
                    semanticsId: TrustIds.receiveOtherInPerson,
                    onTap: () => _open(context, const ReceiveInPersonPage()),
                  ),
                if (ways.file)
                  KitRow(
                    size: KitRowSize.sheet,
                    leading: KitIconWell(KitIcons.invoice),
                    title: l.phoneSettingsWithFile,
                    subtitle: l.phoneRecvFileLine,
                    chevron: true,
                    semanticsId: TrustIds.receiveOtherFile,
                    onTap: () => _open(context, const FileOpenScreen()),
                  ),
                if (ways.tor)
                  KitRow(
                    size: KitRowSize.sheet,
                    leading: KitIconWell(MethodIcons.of(MethodKind.linkTor)),
                    title: l.phoneSettingsTorAddress,
                    subtitle: l.phoneRecvTorLine,
                    value: torOff ? l.phoneRecvOff : null,
                    chevron: true,
                    semanticsId: TrustIds.receiveOtherTor,
                    onTap: () => _open(context, const ReceiveTorPage()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A page of one of the other ways: back header, a "?" where the way has an explainer, the
/// content scrolling under it.
class _WayPage extends StatelessWidget {
  const _WayPage({required this.title, required this.children, this.onHelp});

  final String title;
  final VoidCallback? onHelp;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SlotScaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              KitFlowHeader(title: title, back: true, onLeading: () => Navigator.of(context).maybePop(), onHelp: onHelp),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 20, Kit.gutter, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// In person: the payer's phone shows its payment, this one scans it and shows its reply.
class ReceiveInPersonPage extends ConsumerWidget {
  const ReceiveInPersonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    // Scanning a payment asks the node to sign, like opening a file: Offline lets it use the
    // node in use, and says so when that node is not local.
    final offlineNode = watchOfflineUsesNode(context, ref);
    final requests = ref.watch(sessionProvider.select((s) => s?.supportsRequestFiles ?? false));
    return _WayPage(
      title: l.receiveQrTitle,
      onHelp: () => showHandshakeSheet(context, flow: HandshakeFlow.qrReceive),
      children: [
        Text(l.receiveQrBody, style: KitType.body.copyWith(color: t.dim)),
        const SizedBox(height: 20),
        KitButton(
          key: receiveScanQrKey,
          label: l.qrScanPayment,
          icon: KitIcons.scan,
          onPressed: () => scanSlateQr(context, ref),
        ),
        if (requests) ...[
          const SizedBox(height: 10),
          KitButton(
            key: receiveQrRequestKey,
            label: l.receiveQrRequest,
            kind: KitButtonKind.quiet,
            icon: KitIcons.invoice,
            onPressed: () => openQrRequest(context),
          ),
        ],
        if (offlineNode) const Padding(padding: EdgeInsets.only(top: 12), child: OfflineNodeNote()),
      ],
    );
  }
}

/// Tor address: the onion address with its QR, Tor's state, or what to turn on.
class ReceiveTorPage extends ConsumerWidget {
  const ReceiveTorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final payments =
        ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
        (ref.watch(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults);
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    final offlineBlock = watchNetBlock(context, ref);
    final offline = offlineBlock.byMode;
    final offlineNote = NetBlockNote(offlineBlock, line: l.receiveLinkOffMode(networkModeName(l, ref.watch(networkModeProvider))));
    final dim = KitType.body.copyWith(color: t.dim);
    final List<Widget> body;
    if (!payments.linkTor) {
      // Link · Tor off: the reason and its Turn on.
      final name = MethodIcons.fullName(l, MethodKind.linkTor);
      body = [
        Text(l.netBlockMethodOff(name), textAlign: TextAlign.center, style: dim),
        const SizedBox(height: 16),
        KitButton(
          key: receiveTurnOnLinkTorKey,
          label: l.sendTurnOnMethod(name),
          kind: KitButtonKind.quiet,
          icon: MethodIcons.of(MethodKind.linkTor),
          onPressed: () => ref.read(appSettingsProvider.notifier).setPayments(payments.withMethod(MethodKind.linkTor, true)),
        ),
      ];
    } else if (torState == TorState.off) {
      // No Link · Tor receiving without Tor, and no onion to hand out: Tor never runs in
      // Offline either.
      body = [
        Text(l.receiveDirectNeedsTor, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.text)),
        if (payments.epicbox && !offline) ...[
          const SizedBox(height: 6),
          Text(l.receiveDirectMeanwhile, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
        ],
        if (!offline) ...[
          const SizedBox(height: 16),
          KitButton(
            key: receiveTurnOnTorKey,
            label: l.torTurnOn,
            icon: torIcon,
            onPressed: () => ref.read(phoneTorProvider.notifier).setReceiving(true),
          ),
        ],
        if (offline) ...[const SizedBox(height: 12), offlineNote],
      ];
    } else {
      final onion = ref.watch(phoneTorProvider.select((s) => s.onion));
      // The code stays, scannable and the same address, but dimmed until the address is
      // reachable: the state line under it says why.
      final reachable = ref.watch(phoneTorProvider.select((s) => s.phase == PhoneTorPhase.ready));
      body = [
        if (onion != null) ...[
          AnimatedOpacity(
            key: receiveTorQrKey,
            opacity: reachable ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: ReceiveQr(address: onion, semanticsLabel: l.receiveTorQrLabel),
          ),
          const SizedBox(height: 30),
          AnimatedOpacity(
            opacity: reachable ? 1 : 0.6,
            duration: const Duration(milliseconds: 300),
            child: ReceiveAddressBlock(address: onion, label: l.receiveTorAddressLabel, cardKey: receiveTorAddressKey, copied: l.receiveAddressCopied),
          ),
          const SizedBox(height: 8),
          Text(l.receiveTorCaption, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
          const SizedBox(height: 12),
        ] else
          const LinearProgressIndicator(),
        if (offline) offlineNote else TorStateLine(openSettings: () => openPrivacySettings(context)),
      ];
    }
    return _WayPage(title: l.phoneSettingsTorAddress, children: body);
  }
}
