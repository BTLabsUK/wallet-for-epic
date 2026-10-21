import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum FoundVariant { found, addExisting, settingsError }

/// Three small bare screens in one class: wallets found on this computer, add an existing
/// wallet (older versions or a folder) and the settings-file error. [arg] is a [FoundVariant].
class FoundScreen extends ConsumerStatefulWidget {
  const FoundScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends ConsumerState<FoundScreen> {
  late final FoundVariant _variant = widget.arg is FoundVariant ? widget.arg as FoundVariant : FoundVariant.found;
  List<WalletEntry>? _wallets;
  final Set<String> _picked = {};
  bool _busy = false;
  bool _retrying = false;
  String? _folderError;
  String? _folder;

  @override
  void initState() {
    super.initState();
    if (_variant == FoundVariant.found) _load();
  }

  Future<void> _load() async {
    setState(() => _wallets = null);
    final w = await ref.read(deskApiProvider).wallets();
    if (!mounted) return;
    setState(() {
      _wallets = w;
      _picked
        ..clear()
        ..addAll(w.map((e) => e.folder));
    });
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).go(DeskRoute.unlock);
  }

  Future<void> _pickFolder() async {
    setState(() {
      _busy = true;
      _folderError = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _folder = '~/Documents/old-wallet-backup';
    });
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _retrying = false);
    ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock);
  }

  @override
  Widget build(BuildContext context) => EHeroScreen(
    footer: const AuthFoot(),
    child: switch (_variant) {
      FoundVariant.found => _found(context),
      FoundVariant.addExisting => _existing(context),
      FoundVariant.settingsError => _settingsError(context),
    },
  );

  Widget _found(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final c = context.dc;
    final wallets = _wallets;
    if (wallets == null) {
      return EAuthCard(
        title: 'Finding wallets',
        icon: EIcons.search,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const ESpinner(), const SizedBox(width: Sp.x3), Flexible(child: Text('Searching this computer', style: ts.bodyDim))],
        ),
      );
    }
    if (wallets.isEmpty) {
      return EAuthCard(
        title: 'No wallets found',
        lead: 'No wallet folders in the usual places.',
        icon: EIcons.search,
        width: 480,
        alternatives: [ELink(label: 'Back', dim: true, onPressed: nav.back)],
        child: EButton(label: 'Search again', icon: EIcons.refresh, expand: true, onPressed: _load),
      );
    }
    return EAuthCard(
      title: '${wallets.length} wallets found',
      lead: 'Tick the wallets to add to this app.',
      icon: EIcons.wallet,
      width: 520,
      alternatives: [
        ELink(label: 'Back', dim: true, onPressed: nav.back),
        ELink(label: 'Choose a folder', dim: true, onPressed: () => nav.go(DeskRoute.found, FoundVariant.addExisting)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final w in wallets)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.x3),
              child: Container(
                padding: const EdgeInsets.all(Sp.x3),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(Rad.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ECheckbox(
                        value: _picked.contains(w.folder),
                        label: w.name,
                        onChanged: (v) => setState(() => v ? _picked.add(w.folder) : _picked.remove(w.folder)),
                      ),
                    ),
                    if (w.network != 'mainnet') ETag(w.network, tone: ETone.warn),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Sp.x3),
          EButton.primary(
            label: _picked.isEmpty ? 'Add wallets' : 'Add ${_picked.length} wallet${_picked.length == 1 ? '' : 's'}',
            icon: EIcons.plus,
            expand: true,
            busy: _busy,
            onPressed: _picked.isEmpty ? null : _add,
          ),
        ],
      ),
    );
  }

  Widget _way(BuildContext context, IconData icon, String title, String text, Widget action) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: const EdgeInsets.all(Sp.x5),
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Ctl.icon, color: c.accentText),
              const SizedBox(width: Sp.x2),
              Expanded(child: Semantics(header: true, child: Text(title, style: ts.label))),
            ],
          ),
          const SizedBox(height: Sp.x2),
          Text(text, style: ts.small),
          const SizedBox(height: Sp.x4),
          action,
        ],
      ),
    );
  }

  Widget _existing(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EGlyphTile()),
          const SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text('Add an existing wallet', style: ts.h1, textAlign: TextAlign.center)),
          const SizedBox(height: Sp.x6),
          _way(
            context,
            EIcons.history,
            'From an older version',
            'Looks in the folders of older Epic Wallet versions and the epic program. Nothing is changed.',
            Align(
              alignment: Alignment.centerLeft,
              child: EButton(
                label: 'Find wallets',
                icon: EIcons.search,
                size: EBtnSize.sm,
                onPressed: () => nav.go(DeskRoute.importWallets),
              ),
            ),
          ),
          const SizedBox(height: Sp.x4),
          _way(
            context,
            EIcons.folderOpen,
            'From a folder',
            'Pick the folder that holds wallet_data.',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EButton(label: 'Choose a folder', icon: EIcons.folder, size: EBtnSize.sm, busy: _busy, onPressed: _pickFolder),
                if (_folder != null) ...[
                  const SizedBox(height: Sp.x3),
                  Text(_folder!, style: ts.mono()),
                ],
                if (_folderError != null) ...[
                  const SizedBox(height: Sp.x3),
                  Text(_folderError!, style: ts.small),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sp.x5),
          Center(child: ELink(label: 'Back', dim: true, onPressed: nav.back)),
        ],
      ),
    );
  }

  Widget _settingsError(BuildContext context) {
    final ts = context.ts;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EGlyphTile(icon: EIcons.alert)),
          const SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text('Settings file unreadable', style: ts.h1, textAlign: TextAlign.center)),
          const SizedBox(height: Sp.x6),
          ENotice(
            title: 'The settings file could not be read',
            text: 'Unexpected token } in JSON at position 214\n~/.config/Epic Wallet/settings.json',
            tone: ETone.risk,
          ),
          const SizedBox(height: Sp.x4),
          Text('Fix or delete the file, then try again. Wallets are not affected.', style: ts.body),
          const SizedBox(height: Sp.x2),
          Text('A copy of the last good settings is kept next to the file.', style: ts.small),
          const SizedBox(height: Sp.x6),
          Row(
            children: [
              EButton.ghost(label: 'Open folder', icon: EIcons.external, onPressed: () {}),
              const Spacer(),
              EButton(label: 'Quit', onPressed: () {}),
              const SizedBox(width: Sp.x3),
              EButton.primary(label: 'Try again', icon: EIcons.refresh, busy: _retrying, onPressed: _retry),
            ],
          ),
        ],
      ),
    );
  }
}
