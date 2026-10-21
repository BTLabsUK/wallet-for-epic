import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'dialogs.dart';
import 'settings_node.dart';
import 'settings_phrase.dart';
import 'settings_receiving.dart';
import 'settings_rescan.dart';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> settingsShots = [
  const DeskShot(id: '22-settings-node', title: 'Settings, node', route: DeskRoute.settingsNode),
  const DeskShot(id: '22-settings-node-narrow', title: 'Settings, node at 1000x700', route: DeskRoute.settingsNode, width: 1000, height: 700),
  const DeskShot(id: '22b-node-combobox-open', title: 'Node combobox open', route: DeskRoute.settingsNode, arg: NodeDemo.comboOpen),
  const DeskShot(id: '23-settings-receiving', title: 'Settings, receiving', route: DeskRoute.settingsReceiving),
  const DeskShot(id: '23b-epicbox-combobox-open', title: 'Epicbox combobox open', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.comboOpen),
  const DeskShot(id: '23c-receiving-tor-on', title: 'Receiving, Tor on', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.torOn),
  const DeskShot(id: '23d-receiving-epicbox-down', title: 'Receiving, Epicbox down', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.epicboxDown),
  DeskShot(
    id: '24-settings-appearance',
    title: 'Settings, appearance',
    route: DeskRoute.settingsAppearance,
    // 23c turned Tor and HTTP on: put them back for the shots after.
    prepare: (c, _) async {
      final n = c.read(deskProvider.notifier);
      await n.saveSettings(c.read(deskProvider).settings.copyWith(tor: false, directHttp: false));
    },
  ),
  const DeskShot(id: '25-settings-account', title: 'Settings, wallet', route: DeskRoute.settingsAccount),
  const DeskShot(id: '26-settings-wallets', title: 'Settings, wallets', route: DeskRoute.settingsWallets),
  const DeskShot(id: '27-settings-phrase', title: 'Recovery phrase', route: DeskRoute.settingsPhrase),
  const DeskShot(id: '27b-settings-phrase-shown', title: 'Recovery phrase, shown', route: DeskRoute.settingsPhrase, arg: PhraseDemo.shown),
  const DeskShot(id: '28-settings-rescan', title: 'Rescan', route: DeskRoute.settingsRescan),
  const DeskShot(id: '28b-settings-rescan-running', title: 'Rescan, running', route: DeskRoute.settingsRescan, arg: RescanDemo.running),
  const DeskShot(id: '29-settings-about', title: 'About', route: DeskRoute.settingsAbout),
  const DeskShot(id: '30-settings-help', title: 'Help', route: DeskRoute.settingsHelp),
  DeskShot(id: '31-dlg-my-node', title: 'Add node', route: DeskRoute.settingsNode, dialog: (c) => showMyNodeDialog(c)),
  DeskShot(
    id: '31b-dlg-my-node-error',
    title: 'Add node, failed check',
    route: DeskRoute.settingsNode,
    dialog: (c) => showMyNodeDialog(c, initial: 'http://bad.example:3413', showError: true),
  ),
  DeskShot(id: '32-dlg-node-directory', title: 'Node directory', route: DeskRoute.settingsNode, dialog: showNodeDirectoryDialog),
  DeskShot(id: '33-dlg-remove-wallet', title: 'Remove wallet', route: DeskRoute.settingsAccount, dialog: showRemoveWalletDialog),
  DeskShot(id: '34-dlg-public-mode', title: 'Public mode', route: DeskRoute.settingsReceiving, dialog: showPublicModeDialog),
  DeskShot(id: '38-dlg-change-password', title: 'Change password', route: DeskRoute.settingsAccount, dialog: showChangePasswordDialog),
];
