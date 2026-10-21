import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum FoundVariant { found, failed, addExisting, addExistingPicked, settingsError }

/// A wallet an older Epic Wallet left on this computer (mock).
class _OldWallet {
  const _OldWallet(this.name, this.dir, {this.network = 'mainnet', this.lastUsed, this.contacts = 0, this.app, this.legacyDb = false});

  final String name;
  final String dir;
  final String network;
  final String? lastUsed;
  final int contacts;
  final String? app;
  final bool legacyDb;

  String get meta => [
    if (lastUsed != null) 'last used $lastUsed',
    if (contacts > 0) '$contacts contact${contacts == 1 ? '' : 's'}',
    if (app != null) 'Epic Wallet $app',
  ].join(' · ');
}

const _oldWallets = [
  _OldWallet('Main', '~/.epic/main', lastUsed: '12 Mar 2026', contacts: 3, app: '4.2.0'),
  _OldWallet('Savings', '~/EpicWallet-old/Savings', lastUsed: '2 Jan 2025', app: '3.6.1', legacyDb: true),
  _OldWallet('Test', '~/.epic/floo', network: 'floonet', contacts: 1),
];

/// The wallets the mock folder picker finds in the chosen folder.
const _folderWallets = [
  ('~/Documents/old-wallet-backup/main', 'mainnet'),
  ('~/Documents/old-wallet-backup/floo', 'floonet'),
];

const _settingsFile = '~/.config/Epic Wallet/settings.json';

/// Wallets from an older Epic Wallet, adding an existing wallet, and the unreadable settings
/// file. [arg] is a [FoundVariant].
class FoundScreen extends ConsumerStatefulWidget {
  const FoundScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends ConsumerState<FoundScreen> {
  late final FoundVariant _variant = widget.arg is FoundVariant ? widget.arg as FoundVariant : FoundVariant.found;
  List<_OldWallet>? _wallets;
  final Set<String> _picked = {};
  bool _busy = false;
  bool _retrying = false;
  bool _tip = false;

  /// Folder picks so far: odd ones find wallets, even ones find none.
  late int _picks = _variant == FoundVariant.addExistingPicked ? 1 : 0;
  late String? _pickedDir = _variant == FoundVariant.addExistingPicked ? _folderWallets.first.$1 : null;

  @override
  void initState() {
    super.initState();
    if (_variant == FoundVariant.found) _load();
  }

  Future<void> _load() async {
    setState(() => _wallets = null);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _wallets = _oldWallets;
      _picked
        ..clear()
        ..addAll(_oldWallets.map((e) => e.dir));
    });
  }

  void _toUnlock(String added) => ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, UnlockAdded(added));

  Future<void> _add() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final names = [for (final w in _oldWallets) if (_picked.contains(w.dir)) w.name];
    _toUnlock(names.length == 1 ? names.first : '${names.length} wallets');
  }

  void _notNow() {
    final nav = ref.read(deskNavProvider.notifier);
    nav.canBack ? nav.back() : nav.reset(DeskRoute.welcome);
  }

  Future<void> _pickFolder() async {
    setState(() {
      _busy = true;
      _pickedDir = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _picks++;
      if (_picks.isOdd) _pickedDir = _folderWallets.first.$1;
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
      FoundVariant.failed => _failed(context),
      FoundVariant.addExisting || FoundVariant.addExistingPicked => _existing(context),
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
        child: Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ESpinner(size: Ctl.iconSm),
              SizedBox(width: Sp.x3),
              Flexible(child: Text('Looking for wallets from an older Epic Wallet', style: ts.bodyDim)),
            ],
          ),
        ),
      );
    }
    if (wallets.isEmpty) {
      return EAuthCard(
        title: 'Nothing found',
        lead: 'No wallets from an older Epic Wallet are left to import on this computer.',
        icon: EIcons.search,
        width: 480.u,
        alternatives: [ELink(label: 'Back', dim: true, onPressed: nav.back)],
        child: EButton(label: 'Search again', icon: EIcons.refresh, expand: true, onPressed: _load),
      );
    }
    final n = wallets.length;
    return EAuthCard(
      title: '$n wallet${n == 1 ? '' : 's'} found',
      lead: 'From an older Epic Wallet. Use ${n == 1 ? 'it' : 'them'} here? Coins and recovery phrase stay the same.',
      icon: EIcons.wallet,
      width: 560.u,
      alternatives: [
        ELink(label: 'Create wallet', dim: true, onPressed: () => nav.go(DeskRoute.create)),
        ELink(label: 'Restore wallet', dim: true, onPressed: () => nav.go(DeskRoute.restore)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final w in wallets)
            Padding(
              padding: EdgeInsets.only(bottom: Sp.x3),
              child: Container(
                padding: EdgeInsets.all(Sp.x3),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(Rad.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ECheckbox(
                            value: _picked.contains(w.dir),
                            label: w.name,
                            onChanged: _busy ? (_) {} : (v) => setState(() => v ? _picked.add(w.dir) : _picked.remove(w.dir)),
                          ),
                        ),
                        if (w.network != 'mainnet') ETag(networkName(w.network), tone: ETone.warn),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: Sp.x8, top: Sp.x1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.dir, style: ts.mono(), overflow: TextOverflow.ellipsis),
                          if (w.meta.isNotEmpty) Text(w.meta, style: ts.caption),
                          if (w.legacyDb) ...[
                            SizedBox(height: Sp.x1),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(EIcons.history, size: Ctl.iconSm, color: c.warn),
                                SizedBox(width: Sp.x2),
                                Expanded(
                                  child: Text(
                                    'Made with an older wallet version: the balance comes back with a rescan, older history may not show.',
                                    style: ts.small,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text('Close the older Epic Wallet first. Unlock with the password used there.', style: ts.small),
          SizedBox(height: Sp.x1),
          Text('${n == 1 ? 'It' : 'They'} can be imported later in Settings.', style: ts.caption),
          SizedBox(height: Sp.x5),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            children: [
              EButton.ghost(label: 'Not now', onPressed: _busy ? null : _notNow),
              EButton.primary(
                label: _picked.length == 1 ? 'Use this wallet' : 'Use ${_picked.length} wallets',
                icon: EIcons.download,
                busy: _busy,
                onPressed: _picked.isEmpty ? null : _add,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _failed(BuildContext context) {
    final ts = context.ts;
    return EAuthCard(
      title: '1 wallet not imported',
      lead: '2 wallets were imported.',
      icon: EIcons.alert,
      width: 520.u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ENotice(
            title: 'The older wallet is not changed',
            text: 'Try again later: Add a wallet › Add an existing wallet.',
            tone: ETone.risk,
            icon: EIcons.alert,
          ),
          SizedBox(height: Sp.x4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Savings', style: ts.strong),
                TextSpan(text: ': the wallet folder could not be read.', style: ts.body),
              ],
            ),
          ),
          SizedBox(height: Sp.x6),
          Align(
            alignment: Alignment.centerRight,
            child: EButton.primary(label: 'Continue', onPressed: () => _toUnlock('2 wallets')),
          ),
        ],
      ),
    );
  }

  Widget _way(BuildContext context, IconData icon, String title, String text, Widget action, {Widget? trailing}) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.all(Sp.x5),
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
              SizedBox(width: Sp.x2),
              Expanded(child: Semantics(header: true, child: Text(title, style: ts.label))),
              ?trailing,
            ],
          ),
          SizedBox(height: Sp.x2),
          Text(text, style: ts.small),
          SizedBox(height: Sp.x4),
          action,
        ],
      ),
    );
  }

  Widget _existing(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520.u),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EGlyphTile()),
          SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text('Add an existing wallet', style: ts.h1, textAlign: TextAlign.center)),
          SizedBox(height: Sp.x2),
          Text(
            'The wallet stays in its folder and is added to the list. No wallet is replaced.',
            style: ts.bodyDim,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Sp.x6),
          _way(
            context,
            EIcons.history,
            'From an older version',
            'Finds wallets from older Epic Wallet versions and the epic program. Nothing is changed.',
            Align(
              alignment: Alignment.centerLeft,
              child: EButton(
                label: 'Look for wallets',
                icon: EIcons.search,
                size: EBtnSize.sm,
                onPressed: () => nav.go(DeskRoute.importWallets),
              ),
            ),
          ),
          SizedBox(height: Sp.x4),
          _way(
            context,
            EIcons.folderOpen,
            'From a wallet folder',
            _tip
                ? 'The folder with wallet_data inside, for example .epic/main in the home folder. A folder above it works too.'
                : 'Pick the wallet’s folder.',
            trailing: EIconButton(
              icon: EIcons.info,
              label: _tip ? 'Hide details' : 'More about this',
              size: EBtnSize.inline,
              selected: _tip,
              onPressed: () => setState(() => _tip = !_tip),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: EButton(label: 'Choose a folder', icon: EIcons.folder, size: EBtnSize.sm, busy: _busy, onPressed: _pickFolder),
                ),
                if (_picks > 0 && !_busy) ...[
                  SizedBox(height: Sp.x4),
                  _pickResult(context),
                ],
              ],
            ),
          ),
          SizedBox(height: Sp.x5),
          Center(child: ELink(label: 'Back', dim: true, onPressed: nav.back)),
        ],
      ),
    );
  }

  /// What the picked folder holds: its wallets to choose from, or none.
  Widget _pickResult(BuildContext context) {
    final ts = context.ts;
    final cancel = EButton.ghost(
      label: 'Cancel',
      size: EBtnSize.sm,
      onPressed: () => setState(() {
        _picks = 0;
        _pickedDir = null;
      }),
    );
    if (_picks.isEven) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ENotice(
            title: 'No wallet in this folder',
            text: 'Choose the folder with wallet_data inside, or a folder above it.',
            tone: ETone.warn,
            icon: EIcons.info,
          ),
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [EButton(label: 'Choose another', size: EBtnSize.sm, onPressed: _pickFolder), cancel],
          ),
        ],
      );
    }
    return Container(
      padding: EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: context.dc.accentFaint,
        border: Border.all(color: context.dc.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('${_folderWallets.length} wallets in this folder', style: ts.label)),
          SizedBox(height: Sp.x3),
          for (final (dir, net) in _folderWallets) ...[
            EChoiceCard(
              title: dir.split('/').last,
              description: dir,
              icon: EIcons.wallet,
              tag: net == 'mainnet' ? null : ETag(networkName(net), tone: ETone.warn),
              selected: _pickedDir == dir,
              onTap: () => setState(() => _pickedDir = dir),
            ),
            SizedBox(height: Sp.x2),
          ],
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton.primary(
                label: 'Open',
                size: EBtnSize.sm,
                onPressed: _pickedDir == null ? null : () => _toUnlock(_pickedDir!.split('/').last),
              ),
              EButton(label: 'Choose another', size: EBtnSize.sm, onPressed: _pickFolder),
              cancel,
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsError(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520.u),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: EGlyphTile(size: 72.u, icon: EIcons.alert)),
          SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text('Settings cannot be read', style: ts.h1, textAlign: TextAlign.center)),
          SizedBox(height: Sp.x6),
          const ENotice(
            title: 'This file exists but could not be read',
            text: 'Reason: Unexpected token } in JSON at position 214',
            tone: ETone.risk,
            icon: EIcons.alert,
          ),
          SizedBox(height: Sp.x3),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            decoration: BoxDecoration(
              color: c.s1,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: SelectableText(_settingsFile, style: ts.mono()),
          ),
          SizedBox(height: Sp.x4),
          Text('Fix the file or remove it, then try again. Until then the app writes nothing, so the wallet list is kept.', style: ts.body),
          SizedBox(height: Sp.x2),
          Text('settings.json.bak in the same folder holds the version before the last change.', style: ts.small),
          SizedBox(height: Sp.x6),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            children: [
              EButton.ghost(label: 'Open folder', icon: EIcons.external, onPressed: () => showEToast(context, 'Opened ~/.config/Epic Wallet')),
              EButton(label: 'Quit', onPressed: () => showEToast(context, 'The app would quit here')),
              EButton.primary(label: 'Try again', icon: EIcons.refresh, busy: _retrying, onPressed: _retry),
            ],
          ),
        ],
      ),
    );
  }
}
