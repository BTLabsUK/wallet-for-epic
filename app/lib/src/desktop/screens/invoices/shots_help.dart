import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../widgets/kit.dart';
import '../settings/help_invoices.dart';

/// Scrolls the flow diagram's bottom into view, so the shot holds all of it.
Future<void> _showDiagram(ProviderContainer _, BuildContext context) async {
  Element? found;
  void visit(Element e) {
    if (found != null) return;
    if (e.widget is InvoiceFlowDiagram) {
      found = e;
      return;
    }
    e.visitChildElements(visit);
  }

  context.visitChildElements(visit);
  if (found case final e?) await Scrollable.ensureVisible(e, alignment: 1);
}

/// Screenshot tour entries of Help › Invoices (see shots.dart).
final List<DeskShot> invoiceHelpShots = [
  const DeskShot(id: 'inv-help-01-section', title: 'Help › Invoices: the section and its three topics', route: DeskRoute.settingsHelp, arg: HelpAt('invoices', topic: -1), height: 1000),
  DeskShot(id: 'inv-help-02-flow', title: 'Help › Invoices: how an invoice works, with the flow diagram', route: DeskRoute.settingsHelp, arg: HelpAt('invoices'), prepare: _showDiagram, height: 900),
  DeskShot(id: 'inv-help-03-flow-900', title: 'Help › Invoices: the flow at 900 px (rail layout)', route: DeskRoute.settingsHelp, arg: HelpAt('invoices'), prepare: _showDiagram, width: 900, height: 900),
  const DeskShot(id: 'inv-help-04-trusted', title: 'Help › Invoices: why only trusted senders', route: DeskRoute.settingsHelp, arg: HelpAt('invoices', topic: 1), height: 900),
  const DeskShot(id: 'inv-help-05-address', title: 'Help › Invoices: why a separate invoice address', route: DeskRoute.settingsHelp, arg: HelpAt('invoices', topic: 2), height: 900),
];
