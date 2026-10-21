import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'found_screen.dart' show FoundVariant;
import 'onboarding_parts.dart';

const _defaultFolder = '~/.config/Epic Wallet';

/// The mock folder picker's choices and what each answers: null when the folder can be used.
const _folders = {
  '~/EpicData': null,
  '~/Documents': 'That folder is not empty. Choose a new, empty folder.',
  '~/.epic/main': 'That is a wallet folder. Choose a new, empty folder.',
};

/// First run, and "add a wallet" later: create, add an existing one, or restore. [arg] `'add'`
/// is the later visit (wallets exist), `'advanced'` starts with Advanced open.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _tip = false;
  String? _folderError;

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
    final hasWallets = widget.arg == 'add' || nav.canBack;
    return EHeroScreen(
      footer: const AuthFoot(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480.u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: EGlyphTile()),
            SizedBox(height: Sp.x5),
            Semantics(
              header: true,
              child: Text(hasWallets ? 'Add a wallet' : 'Epic Cash wallet', style: ts.h1, textAlign: TextAlign.center),
            ),
            if (!hasWallets) ...[
              SizedBox(height: Sp.x2),
              Text('Keys and coins stay on this computer, locked with a password.', style: ts.bodyDim, textAlign: TextAlign.center),
            ],
            SizedBox(height: Sp.x8),
            EChoiceCard(
              title: 'Create a new wallet',
              description: 'New recovery phrase',
              icon: EIcons.plus,
              selected: false,
              onTap: () => nav.go(DeskRoute.create),
            ),
            SizedBox(height: Sp.x3),
            EChoiceCard(
              title: 'Add an existing wallet',
              description: 'From a folder or an older version',
              icon: EIcons.folderOpen,
              selected: false,
              onTap: () => nav.go(DeskRoute.found, FoundVariant.addExisting),
            ),
            SizedBox(height: Sp.x3),
            EChoiceCard(
              title: 'Restore from a phrase',
              description: 'From the recovery words',
              icon: EIcons.key,
              selected: false,
              onTap: () => nav.go(DeskRoute.restore),
            ),
            if (flow.testNet) ...[
              SizedBox(height: Sp.x4),
              NetNote(flow.network, 'New wallets are made on this test network.', center: true),
            ],
            if (hasWallets) ...[
              SizedBox(height: Sp.x5),
              Center(
                child: ELink(
                  label: 'Back to unlock',
                  onPressed: () => nav.canBack ? nav.back() : nav.reset(DeskRoute.unlock),
                ),
              ),
            ],
            SizedBox(height: Sp.x6),
            EDetails(
              title: 'Advanced',
              initiallyOpen: widget.arg == 'advanced' || flow.dataFolder != null,
              child: _advanced(context, flow, hasWallets),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advanced(BuildContext context, OnbFlow flow, bool locked) {
    final ts = context.ts;
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EField(
          label: 'Network',
          help: 'Mainnet holds real EPIC. Floonet and Usernet are test networks.',
          child: ESelect<String>(
            semanticLabel: 'Network',
            value: flow.network,
            onChanged: ref.read(onbFlowProvider.notifier).setNetwork,
            items: const [
              ESelectItem('mainnet', 'Mainnet'),
              ESelectItem('floonet', 'Floonet'),
              ESelectItem('usernet', 'Usernet'),
            ],
          ),
        ),
        SizedBox(height: Sp.x5),
        Row(
          children: [
            Expanded(child: Text('App data folder', style: ts.label)),
            EIconButton(
              icon: EIcons.info,
              label: _tip ? 'Hide details' : 'More about this',
              size: EBtnSize.inline,
              selected: _tip,
              onPressed: () => setState(() => _tip = !_tip),
            ),
          ],
        ),
        SizedBox(height: Sp.x1),
        Text('Where the app keeps wallets and settings.', style: ts.small),
        if (_tip) ...[
          SizedBox(height: Sp.x1),
          Semantics(
            liveRegion: true,
            child: Text(
              'With the built-in node, the blockchain is kept here too. A new folder must be empty: the app makes its folders there and keeps using it.',
              style: ts.small,
            ),
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
                Flexible(child: Text('Using ${flow.dataFolder}. The app restarts to use it.', style: ts.small)),
              ],
            ),
          )
        else
          Text(_defaultFolder, style: ts.mono()),
        SizedBox(height: Sp.x3),
        if (locked)
          Text('It can be changed only before the first wallet is added.', style: ts.small)
        else
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EButton(label: 'Choose a folder', icon: EIcons.folder, size: EBtnSize.sm, onPressed: _pickFolder),
              if (flow.dataFolder != null)
                ELink(
                  label: 'Default folder',
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
                Expanded(child: Text(_folderError!, style: ts.small.copyWith(color: c.risk))),
              ],
            ),
          ),
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
    title: 'Choose a folder',
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
      EButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      EButton.primary(label: 'Choose', onPressed: _sel == null ? null : () => Navigator.pop(context, _sel)),
    ],
  );
}
