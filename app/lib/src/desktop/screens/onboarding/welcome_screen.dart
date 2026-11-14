// SPDX-License-Identifier: Apache-2.0
import '../../../trust_ids.dart';
import '../../desk_l10n.dart';
import '../../../app_info.dart';
import '../../../data_folder_io.dart' show desktopDataFolderName;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../first_start.dart' show firstStartProvider;
import '../../../tor_build.dart' show torBuilt;
import '../../../ui/theme/brand.dart' show BrandVariant, BrandWordmark;
import '../../../ui/theme/epic1_mark.dart' show Epic1Text;
import '../../data/desk_first_start.dart' show deskFirstStartProvider;
import '../../widgets/kit.dart';
import 'undercover_row.dart';
import 'import_warning.dart';
import 'onboarding_parts.dart';

/// Where the app keeps its data (`appDataDirectory`), as the home-relative path the screens show.
const _defaultFolder = '~/$desktopDataFolderName'; // l10n-ok: a path

/// Why the mock folder picker refuses a folder.
enum _FolderIssue { notEmpty, walletFolder }

/// The mock folder picker's choices and what each answers: null when the folder can be used.
const _folders = {
  '~/EpicData': null, // l10n-ok: a path
  '~/Documents': _FolderIssue.notEmpty, // l10n-ok: a path
  '~/.epic/main': _FolderIssue.walletFolder, // l10n-ok: a path
};

/// First run, and "add a wallet" later: create, add an existing one, or restore. [arg] `'add'`
/// is the later visit (wallets exist), `'advanced'` starts with Advanced open, `'tor-only'` with
/// Tor only on (the screenshot tour's first start).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _tip = false;
  _FolderIssue? _folderError;
  late bool _undercover = widget.arg == 'tor-only';
  bool _busy = false;

  /// The first-start step is still to answer: the gate is held, nothing connects.
  bool get _held => ref.read(firstStartProvider);

  /// A door was pressed: on a fresh install, answer the first-start step (with Tor only when
  /// it is on) and only then [go]. Nothing connects before this on a fresh install.
  Future<void> _enter(VoidCallback go) async {
    if (_busy) return;
    if (_held) {
      setState(() => _busy = true);
      try {
        await ref.read(deskFirstStartProvider).complete(undercover: _undercover);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
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
    void toCreate() => nav.go(DeskRoute.create);
    // The warning comes first: cancelling it answers nothing.
    void toImport() => importAfterWarning(context, ref, () {
      void go() => nav.go(DeskRoute.importWallets);
      hasWallets ? go() : _enter(go);
    });
    void toRestore() => nav.go(DeskRoute.restore);
    final create = _Door(
      key: const ValueKey('door-create'),
      semanticsId: TrustIds.welcomeCreate,
      title: l.deskOnbWelcomeCreate,
      text: l.deskOnbWelcomeCreateSub,
      icon: EIcons.plus,
      main: true,
      onTap: hasWallets ? toCreate : () => _enter(toCreate),
    );
    // The other apps' line belongs to Restore (their wallets come back by phrase).
    final restore = _Door(
      key: const ValueKey('door-restore'),
      semanticsId: TrustIds.welcomeRestore,
      title: l.deskOnbWelcomeRestore,
      text: l.deskOnbWelcomeRestoreSub,
      icon: EIcons.refresh,
      onTap: hasWallets ? toRestore : () => _enter(toRestore),
    );
    final import = _Door(
      key: const ValueKey('door-import'),
      semanticsId: TrustIds.welcomeImport,
      title: l.deskOnbWelcomeImport,
      text: l.deskOnbWelcomeImportSub,
      icon: EIcons.folderOpen,
      onTap: toImport,
    );
    final gap = Sp.x2p5;
    // Tor only from the first connection: a fresh install, Tor builds.
    final offered = torBuilt && held && !hasWallets;
    return EHeroScreen(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: hasWallets ? 480.u : 780.u),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: EGlyphTile()),
                  SizedBox(height: Sp.x4p5),
                  if (hasWallets)
                    Semantics(
                      header: true,
                      child: Text(l.deskOnbWelcomeAdd, style: ts.h1, textAlign: TextAlign.center),
                    )
                  else ...[
                    Semantics(
                      header: true,
                      child: Center(child: BrandWordmark(variant: BrandVariant.desktop, size: Fs.h1.u, label: appName)),
                    ),
                    SizedBox(height: Sp.x3p5),
                    Text(l.deskOnbWelcomeTagline, style: ts.bodyDim, textAlign: TextAlign.center),
                  ],
                  SizedBox(height: 28.u),
                  // Create first and widest; Restore and Import side by side under it when they fit.
                  create,
                  SizedBox(height: gap),
                  LayoutBuilder(
                    builder: (context, box) => box.maxWidth >= Lay.md
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [Expanded(child: restore), SizedBox(width: gap), Expanded(child: import)],
                            ),
                          )
                        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [restore, SizedBox(height: gap), import]),
                  ),
                  if (!hasWallets) ...[
                    SizedBox(height: 28.u),
                    const _Facts(),
                    // Niche, so under the doors and quiet.
                    if (offered) ...[
                      SizedBox(height: Sp.x6),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 480.u),
                          child: DeskUndercoverRow(value: _undercover, onChanged: _busy ? null : (v) => setState(() => _undercover = v)),
                        ),
                      ),
                    ],
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
            help: 'The main network holds real EPIC. The test networks hold coins of no value.', // l10n-ok: development builds only
            child: ESelect<String>(
              semanticLabel: l.deskOnbWelcomeNetwork,
              value: flow.network,
              onChanged: ref.read(onbFlowProvider.notifier).setNetwork,
              items: [
                for (final n in const ['mainnet', 'floonet', 'usernet']) ESelectItem(n, networkName(n)),
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

/// A way in: a tile with its glyph, the title, one line, an arrow. The [main] one (Create) is
/// larger and wears the brand's tint.
class _Door extends StatefulWidget {
  const _Door({super.key, required this.semanticsId, required this.title, required this.text, required this.icon, required this.onTap, this.main = false});

  final String semanticsId;
  final String title;
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool main;

  @override
  State<_Door> createState() => _DoorState();
}

class _DoorState extends State<_Door> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final main = widget.main;
    final tile = (main ? 44 : 36).u;
    final edge = main || _hover ? c.accent.withValues(alpha: _hover ? 0.7 : 0.45) : c.lineStrong;
    return TrustId(
      widget.semanticsId,
      child: Semantics(
        button: true,
        child: EPressable(
          onHover: (v) => setState(() => _hover = v),
          onTap: widget.onTap,
          builder: (context, focused) => FocusRing(
            focused: focused,
            child: AnimatedContainer(
              duration: Dur.fast,
              padding: main ? EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4p5) : EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3p5),
              decoration: BoxDecoration(
                color: main ? Color.alphaBlend(c.accentFaint, c.s1) : c.s1,
                borderRadius: BorderRadius.circular(Rad.sm),
                border: Border.all(color: edge),
              ),
              child: Row(
                children: [
                  Container(
                    width: tile,
                    height: tile,
                    decoration: BoxDecoration(
                      color: main ? c.accentSoft : c.s3,
                      borderRadius: BorderRadius.circular(Rad.sm),
                      border: main ? Border.all(color: c.accent.withValues(alpha: 0.45)) : null,
                    ),
                    child: Icon(widget.icon, size: Ctl.icon, color: main ? c.accentText : c.dim),
                  ),
                  SizedBox(width: Sp.x3p5),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: main ? ts.h3 : ts.strong.copyWith(fontSize: (ts.strong.fontSize ?? Fs.md) * Fs.lg / Fs.md)),
                        SizedBox(height: 2.u),
                        Text(widget.text, style: ts.small),
                      ],
                    ),
                  ),
                  SizedBox(width: Sp.x3),
                  Icon(EIcons.chevronRight, size: Ctl.iconSm, color: main ? c.accentText : c.faint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the app is, in three short facts under the doors.
class _Facts extends StatelessWidget {
  const _Facts();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final style = ts.small;
    Widget fact(IconData icon, String title, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.only(top: 2.u), child: Icon(icon, size: Ctl.iconSm, color: c.accentText)),
        SizedBox(width: Sp.x2p5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts.strong.copyWith(fontSize: style.fontSize)),
              Epic1Text(text, style: style),
            ],
          ),
        ),
      ],
    );
    final facts = [
      fact(EIcons.lock, l.deskOnbWelcomeFactAccount, l.deskOnbWelcomeFactAccountText),
      fact(EIcons.link, l.deskOnbWelcomeFactLink, l.deskOnbWelcomeFactLinkText),
      fact(EIcons.server, l.deskOnbWelcomeFactNode, l.deskOnbWelcomeFactNodeText),
    ];
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= Lay.md
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, f) in facts.indexed) ...[if (i > 0) SizedBox(width: Sp.x5p5), Expanded(child: f)],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, f) in facts.indexed) ...[if (i > 0) SizedBox(height: Sp.x3), f],
              ],
            ),
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
    icon: EIcons.folderOpen,
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
