// SPDX-License-Identifier: Apache-2.0
/// Home's Contacts column: the contacts used last, favourites first, each one click from a new
/// payment. Nothing while there are no contacts: their own page says how to add one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../transfer/send_screen.dart' show SendArgs;
import 'contacts_screen.dart' show ContactsArgs;

/// How many contacts Home lists.
const int homeContactsCount = 5;

/// The contacts Home lists: favourites, then the ones used last, then by name.
List<Contact> homeContacts(List<Contact> all) {
  final list = [...all]
    ..sort((a, b) {
      if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
      final at = a.lastUsed, bt = b.lastUsed;
      if (at != null && bt != null && at != bt) return bt.compareTo(at);
      if ((at == null) != (bt == null)) return at == null ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return list.take(homeContactsCount).toList();
}

class HomeContacts extends ConsumerWidget {
  const HomeContacts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(deskProvider.select((s) => s.contacts));
    if (all == null || all.isEmpty) return const SizedBox.shrink();
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final list = homeContacts(all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(
          l.deskShellNavContacts,
          top: Sp.x6,
          trailing: all.length > list.length ? ELink(label: l.deskOvViewAll(all.length), onPressed: () => nav.go(DeskRoute.contacts)) : null,
        ),
        Container(
          key: const ValueKey('home-contacts'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: Column(
            children: [
              for (final (i, x) in list.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                EInkWell(
                  onTap: () => nav.go(DeskRoute.contacts, ContactsArgs(selectedId: x.id)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: 10.u),
                    child: Row(
                      children: [
                        EAvatar(x.name),
                        SizedBox(width: 14.u),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.strong),
                              if ((x.note ?? '').isNotEmpty) Text(x.note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small),
                            ],
                          ),
                        ),
                        SizedBox(width: Sp.x2),
                        EIconButton(icon: EIcons.send, label: l.deskOvSendTo(x.name), size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.send, SendArgs(contact: x))),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
