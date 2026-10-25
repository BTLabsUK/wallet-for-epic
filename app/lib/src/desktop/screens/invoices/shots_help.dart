import '../../app/shots.dart';
import '../../widgets/kit.dart';
import '../settings/help_pairing.dart';

/// Screenshot tour entries of Help › Pairing (see shots.dart).
final List<DeskShot> invoiceHelpShots = [
  const DeskShot(id: 'pair-help-01-section', title: 'Help › Pairing: the section and its five topics', route: DeskRoute.settingsHelp, arg: HelpAt('pairing', topic: -1), height: 1000),
  const DeskShot(id: 'pair-help-02-what', title: 'Help › Pairing: what pairing is', route: DeskRoute.settingsHelp, arg: HelpAt('pairing'), height: 900),
  const DeskShot(id: 'pair-help-03-invoices', title: 'Help › Pairing: invoices from paired contacts', route: DeskRoute.settingsHelp, arg: HelpAt('pairing', topic: 3), height: 900),
];
