// SPDX-License-Identifier: Apache-2.0
/// The quiet offer to link another device: one line and a button, at the moment the need shows
/// (the end of the history offer after a restore, the details of a payment another device made).
/// Nothing to turn on: Linked devices is on unless the user switched it off, and then the offer
/// is not shown.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/desk_app.dart' show deskNavigatorKey;
import '../../data/devices_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'link_flow.dart';

const Key deskLinkOfferKey = ValueKey('desk-link-offer');
const Key deskLinkOfferButtonKey = ValueKey('desk-link-offer-button');

class DeskLinkOffer extends ConsumerWidget {
  const DeskLinkOffer({super.key, required this.text, this.inDialog = false});

  /// The line: why linking helps here.
  final String text;

  /// The offer sits in a dialog: it closes before the link dialog opens.
  final bool inDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(deskLinkedDevicesOnProvider)) return const SizedBox.shrink();
    final l = context.l10n;
    final ts = context.ts;
    // With a device linked already, a third device holds this wallet: the line says so.
    final linked = ref.watch(deskDevices.devices).isNotEmpty;
    return Padding(
      key: deskLinkOfferKey,
      padding: EdgeInsets.only(top: Sp.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(linked ? l.offerLinkThird : text, style: ts.small),
          SizedBox(height: Sp.x2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton(
                key: deskLinkOfferButtonKey,
                label: linked ? l.expLinkedDevices : l.devicesLink,
                icon: EIcons.devices,
                size: EBtnSize.inline,
                onPressed: () {
                  if (linked) {
                    if (inDialog) Navigator.of(context).pop();
                    ref.read(deskNavProvider.notifier).go(DeskRoute.settingsDevices);
                    return;
                  }
                  if (!inDialog) return unawaited(showDeskLinkDevice(context));
                  // The dialog holding the offer goes first; the link dialog opens over the app.
                  Navigator.of(context).pop();
                  final host = deskNavigatorKey.currentContext;
                  if (host != null) unawaited(showDeskLinkDevice(host));
                },
              ),
              EBadge(l.advExperimental),
            ],
          ),
        ],
      ),
    );
  }
}
