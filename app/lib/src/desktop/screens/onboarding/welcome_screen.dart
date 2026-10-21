import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

/// First run, and "add a wallet" later: create, restore, import or open one that exists.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(deskNavProvider.notifier);
    return EHeroScreen(
      footer: const AuthFoot(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: EGlyphTile()),
            const SizedBox(height: Sp.x5),
            Semantics(header: true, child: Text('Epic Cash wallet', style: context.ts.h1, textAlign: TextAlign.center)),
            const SizedBox(height: Sp.x2),
            Text(
              'Keys and coins stay on this computer, locked with a password.',
              style: context.ts.bodyDim,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sp.x8),
            EChoiceCard(
              title: 'Create a new wallet',
              description: 'New recovery phrase',
              icon: EIcons.plus,
              selected: false,
              onTap: () => nav.go(DeskRoute.create),
            ),
            const SizedBox(height: Sp.x3),
            EChoiceCard(
              title: 'Restore from a phrase',
              description: 'From the recovery words',
              icon: EIcons.key,
              selected: false,
              onTap: () => nav.go(DeskRoute.restore),
            ),
            const SizedBox(height: Sp.x3),
            EChoiceCard(
              title: 'Import wallets',
              description: 'From an older Epic Wallet, the epic program or a folder',
              icon: EIcons.folderOpen,
              selected: false,
              onTap: () => nav.go(DeskRoute.importWallets),
            ),
            const SizedBox(height: Sp.x5),
            Center(
              child: ELink(label: 'Open an existing wallet', onPressed: () => nav.go(DeskRoute.unlock)),
            ),
          ],
        ),
      ),
    );
  }
}
