// SPDX-License-Identifier: Apache-2.0
import '../../desk_l10n.dart';
import '../../../app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../levels/first_start.dart' show firstStartProvider;
import '../../../levels/wallet_level.dart';
import '../../../tor_build.dart' show torBuilt;
import '../../../ui/theme/brand.dart' show BrandVariant, BrandWordmark;
import '../../data/desk_levels.dart';
import '../../widgets/kit.dart';
import 'depth_dial.dart';
import 'import_warning.dart';
import 'onboarding_parts.dart';

const _defaultFolder = '~/.config/Epic Cash Desktop'; // l10n-ok: a path

/// Why the mock folder picker refuses a folder.
enum _FolderIssue { notEmpty, walletFolder }

/// The mock folder picker's choices and what each answers: null when the folder can be used.
const _folders = {
  '~/EpicData': null, // l10n-ok: a path
  '~/Documents': _FolderIssue.notEmpty, // l10n-ok: a path
  '~/.epic/main': _FolderIssue.walletFolder, // l10n-ok: a path
};

/// First run, and "add a wallet" later: create, add an existing one, or restore. [arg] `'add'`
/// is the later visit (wallets exist), `'advanced'` starts with Advanced open, a [WalletLevel]
/// starts with that stop picked (the screenshot tour's first start).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _tip = false;
  _FolderIssue? _folderError;

  /// The stop picked on the dial; null until a pick (a fresh install) or the current level.
  late WalletLevel? _pick = widget.arg is WalletLevel ? widget.arg! as WalletLevel : null;
  bool _undercover = false;
  bool _busy = false;

  /// The first-start step is still to answer: the gate is held, nothing connects.
  bool get _held => ref.read(firstStartProvider);

  /// A door was pressed: answer the first-start step (the level, Undercover) or store a changed
  /// stop, then [go]. Nothing connects before this on a fresh install.
  Future<void> _enter(VoidCallback go) async {
    if (_busy) return;
    final level = _pick ?? (_held ? null : ref.read(deskLevelProvider));
    if (level == null) return;
    setState(() => _busy = true);
    try {
      final control = ref.read(deskLevelControlProvider);
      if (_held) {
        await control.completeFirstStart(level, undercover: _undercover);
      } else if (level != ref.read(deskLevelProvider)) {
        await control.setLevel(level);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) go();
  }

  Future<void> _pickFolder() async {
    final picked = await showEDialog<String>(context, builder: (_) => const _FolderDialog());
    if (picked == null || !mounted) return;
    final error = _folders[picked];
    setState(() => _folderError = error);
    if (error == null) ref.read(onbFlowProvider.notifier).setFolder(picked);
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final flow = ref.watch(onbFlowProvider);
    final ts = context.ts;
    final l = context.l10n;
    final hasWallets = widget.arg == 'add' || nav.canBack;
    final held = ref.watch(firstStartProvider);
    // Watched even while held, so the stored level is loaded before a pick is stored over it.
    final current = ref.watch(deskLevelProvider);
    // The stop the dial shows: the pick, else the level in force (none on a fresh install).
    final shown = _pick ?? (held ? null : current);
    // The doors stay above the fold: a smaller picker below 940 px, no glyph tile below 860 and
    // no tagline below 740 (a 1280 x 720 window).
    final windowHeight = MediaQuery.sizeOf(context).height;
    final tight = windowHeight < 940;
    final noGlyph = windowHeight < 860;
    final noTagline = windowHeight < 740;
    // The doors wait for a stop on a fresh install; elsewhere they work as they always did.
    final locked = !hasWallets && held && _pick == null;
    void toCreate() => nav.go(DeskRoute.create);
    // The warning comes first: cancelling it answers nothing.
    void toImport() => importAfterWarning(context, ref, () {
      void go() => nav.go(DeskRoute.importWallets);
      hasWallets ? go() : _enter(go);
    });
    void toRestore() => nav.go(DeskRoute.restore);
    Widget door(Widget card) => hasWallets
        ? card
        : Semantics(
            enabled: !locked,
            child: ExcludeFocus(
              excluding: locked,
              child: IgnorePointer(
                ignoring: locked,
                child: AnimatedOpacity(duration: Dur.base, opacity: locked ? 0.45 : 1, child: card),
              ),
            ),
          );
    final create = door(
      EChoiceCard(
        key: const ValueKey('door-create'),
        title: l.deskOnbWelcomeCreate,
        description: l.deskOnbWelcomeCreateSub,
        icon: EIcons.plus,
        selected: false,
        onTap: hasWallets ? toCreate : () => _enter(toCreate),
      ),
    );
    final import = door(
      EChoiceCard(
        key: const ValueKey('door-import'),
        title: l.deskOnbWelcomeImport,
        description: l.deskOnbWelcomeImportSub,
        icon: EIcons.folderOpen,
        selected: false,
        onTap: toImport,
      ),
    );
    // The other apps' line belongs to Restore (their wallets come back by phrase): its card's
    // line, like the others', so the cards keep one rhythm.
    final restore = door(
      EChoiceCard(
        key: const ValueKey('door-restore'),
        title: l.deskOnbWelcomeRestore,
        description: l.deskOnbWelcomeRestoreSub,
        icon: EIcons.key,
        selected: false,
        onTap: hasWallets ? toRestore : () => _enter(toRestore),
      ),
    );
    final offered = torBuilt && held;
    return EHeroScreen(
      footer: const AuthFoot(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: hasWallets ? 480.u : 1180.u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!(noGlyph && !hasWallets)) ...[
              const Center(child: EGlyphTile()),
              SizedBox(height: Sp.x5),
            ],
            if (hasWallets)
              Semantics(
                header: true,
                child: Text(l.deskOnbWelcomeAdd, style: ts.h1, textAlign: TextAlign.center),
              )
            else
              Semantics(
                header: true,
                child: Center(child: BrandWordmark(variant: BrandVariant.desktop, size: Fs.h1.u, label: appName)),
              ),
            if (!hasWallets && !noTagline) ...[
              SizedBox(height: Sp.x2),
              Text(l.deskOnbWelcomeTagline, style: ts.bodyDim, textAlign: TextAlign.center),
            ],
            SizedBox(height: hasWallets ? Sp.x8 : (tight ? Sp.x4 : Sp.x6)),
            if (hasWallets) ...[
              create,
              SizedBox(height: Sp.x3),
              import,
              SizedBox(height: Sp.x3),
              restore,
            ] else ...[
              DeskDepthPicker(
                title: l.lvPickTitle,
                lead: l.lvPickLead,
                level: shown,
                onLevel: (v) => setState(() => _pick = v),
                compact: tight,
                covered: true,
                caption: l.deskLvStartPreviewCaption,
                foot: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (offered) DeskUndercoverRow(value: _undercover, onChanged: (v) => setState(() => _undercover = v)),
                    SizedBox(height: Sp.x2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Sp.x2,
                      children: [
                        Text(l.deskLvStartChangeLater, style: ts.small),
                        ELink(label: l.lvPickHelpTitle, onPressed: () => showDepthHelp(context)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: tight ? Sp.x3 : Sp.x4),
              LayoutBuilder(
                builder: (context, box) => box.maxWidth >= Lay.lg
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [Expanded(child: create), SizedBox(width: Sp.x3), Expanded(child: import), SizedBox(width: Sp.x3), Expanded(child: restore)],
                        ),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [create, SizedBox(height: Sp.x3), import, SizedBox(height: Sp.x3), restore]),
              ),
              SizedBox(height: Sp.x2),
              // The line's room stays, so the doors do not move when it goes.
              locked
                  ? Text(l.deskLvStartPickFirst, style: ts.small, textAlign: TextAlign.center)
                  : SizedBox(height: Fs.sm * 1.45),
            ],
            if (flow.testNet) ...[
              SizedBox(height: Sp.x4),
              NetNote(flow.network, l.deskOnbWelcomeTestNote, center: true),
            ],
            if (hasWallets) ...[
              SizedBox(height: Sp.x5),
              Center(
                child: ELink(
                  label: l.deskOnbWelcomeBack,
                  onPressed: () => nav.canBack ? nav.back() : nav.reset(DeskRoute.unlock),
                ),
              ),
            ],
            if (DeskFeatures.testNetworks || DeskFeatures.dataFolder) ...[
              SizedBox(height: Sp.x6),
              EDetails(
                title: l.deskOnbWelcomeAdvanced,
                initiallyOpen: widget.arg == 'advanced' || flow.dataFolder != null,
                child: _advanced(context, flow, hasWallets),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _advanced(BuildContext context, OnbFlow flow, bool locked) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (DeskFeatures.testNetworks) ...[
        EField(
          label: l.deskOnbWelcomeNetwork,
          help: 'Mainnet holds real EPIC. Floonet and Usernet are test networks.', // l10n-ok: development builds only
          child: ESelect<String>(
            semanticLabel: l.deskOnbWelcomeNetwork,
            value: flow.network,
            onChanged: ref.read(onbFlowProvider.notifier).setNetwork,
            items: const [
              ESelectItem('mainnet', 'Mainnet'), // l10n-ok: network names
              ESelectItem('floonet', 'Floonet'), // l10n-ok
              ESelectItem('usernet', 'Usernet'), // l10n-ok
            ],
          ),
        ),
        SizedBox(height: Sp.x5),
        ],
        if (DeskFeatures.dataFolder) ...[
        Row(
          children: [
            Expanded(child: Text(l.deskOnbWelcomeFolder, style: ts.label)),
            EIconButton(
              icon: EIcons.info,
              label: _tip ? l.deskOnbWelcomeHideDetails : l.deskOnbWelcomeMoreAbout,
              size: EBtnSize.inline,
              selected: _tip,
              onPressed: () => setState(() => _tip = !_tip),
            ),
          ],
        ),
        SizedBox(height: Sp.x1),
        Text(l.deskOnbWelcomeFolderWhere, style: ts.small),
        if (_tip) ...[
          SizedBox(height: Sp.x1),
          Semantics(
            liveRegion: true,
            child: Text(l.deskOnbWelcomeFolderDetail, style: ts.small),
          ),
        ],
        SizedBox(height: Sp.x2),
        if (flow.dataFolder != null)
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok),
                SizedBox(width: Sp.x2),
                Flexible(child: Text(l.deskOnbWelcomeUsing('${flow.dataFolder}'), style: ts.small)),
              ],
            ),
          )
        else
          Text(_defaultFolder, style: ts.mono()),
        SizedBox(height: Sp.x3),
        if (locked)
          Text(l.deskOnbWelcomeLocked, style: ts.small)
        else
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EButton(label: l.deskOnbWelcomeChooseFolder, icon: EIcons.folder, size: EBtnSize.sm, onPressed: _pickFolder),
              if (flow.dataFolder != null)
                ELink(
                  label: l.deskOnbWelcomeDefaultFolder,
                  onPressed: () => setState(() {
                    _folderError = null;
                    ref.read(onbFlowProvider.notifier).setFolder(null);
                  }),
                ),
            ],
          ),
        if (_folderError != null) ...[
          SizedBox(height: Sp.x2),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(EIcons.error, size: Ctl.iconSm, color: c.risk),
                SizedBox(width: Sp.x2),
                Expanded(child: Text(switch (_folderError!) { _FolderIssue.notEmpty => l.deskOnbWelcomeFolderNotEmpty, _FolderIssue.walletFolder => l.deskOnbWelcomeFolderIsWallet }, style: ts.small.copyWith(color: c.risk))),
              ],
            ),
          ),
        ],
        ],
      ],
    );
  }
}

/// The mock system folder picker.
class _FolderDialog extends StatefulWidget {
  const _FolderDialog();

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  String? _sel;

  @override
  Widget build(BuildContext context) => EDialog(
    title: context.l10n.deskOnbWelcomeChooseFolder,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in _folders.keys) ...[
          EChoiceCard(title: f, icon: EIcons.folder, selected: _sel == f, onTap: () => setState(() => _sel = f)),
          SizedBox(height: Sp.x2),
        ],
      ],
    ),
    actions: [
      EButton(label: context.l10n.commonCancel, onPressed: () => Navigator.pop(context)),
      EButton.primary(label: context.l10n.deskOnbWelcomeChoose, onPressed: _sel == null ? null : () => Navigator.pop(context, _sel)),
    ],
  );
}
