// SPDX-License-Identifier: Apache-2.0
/// The contact page's compatibility line: one sentence under the Pairing block, never a badge.
/// "Anna’s last payment was answered by another wallet app." when the contact's key last
/// answered without this app's marker, or "Not heard from Anna’s wallet since 3 Aug." for a
/// paired contact silent for 90 days (`trust/policy.dart`, [contactLine]). Nothing otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../trust/contact_trust.dart';
import '../trust/trust_providers.dart';
import 'theme/tokens.dart';

/// The line, for tests.
const Key contactTrustLineKey = ValueKey('contact-trust-line');

class ContactTrustLine extends ConsumerWidget {
  const ContactTrustLine({super.key, required this.contactId, required this.name});

  final String contactId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = contactLineText(context.l10n, ref.watch(contactLineProvider(contactId)), name);
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Text(
        text,
        key: contactTrustLineKey,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim),
      ),
    );
  }
}
