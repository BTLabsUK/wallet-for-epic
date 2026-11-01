// SPDX-License-Identifier: Apache-2.0
/// The contact's compatibility line in the details pane: one sentence under the Pairing block,
/// never a badge ("Anna’s last payment was answered by another wallet app.", "Not heard from
/// Anna’s wallet since 3 Aug."; `trust/policy.dart`, [contactLine]). Nothing otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust/contact_trust.dart';
import '../../data/trust_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The line, for tests.
const Key deskContactTrustLineKey = ValueKey('contact-trust-line');

class DeskContactTrustLine extends ConsumerWidget {
  const DeskContactTrustLine({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = contactLineText(context.l10n, deskContactLine(ref, contact), contact.name);
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: Sp.x3),
      child: Text(text, key: deskContactTrustLineKey, style: context.ts.small),
    );
  }
}
