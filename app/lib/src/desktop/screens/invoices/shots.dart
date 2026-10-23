/// Screenshot tour entries of the invoice screens: every state of docs/invoices/flow.md, dark
/// by default (`flutter test tool/desktop_tour_test.dart --plain-name inv-`). Ids start with
/// `inv-` and sort by part: pay (the payer), req (the issuer), set (Settings, Contacts,
/// Receive), act (Activity, Overview), core (the Invoices page's frame and the edge states).
library;

import '../../app/shots.dart';
import 'shots_act.dart';
import 'shots_core.dart';
import 'shots_help.dart';
import 'shots_pay.dart';
import 'shots_req.dart';
import 'shots_set.dart';

final List<DeskShot> invoiceShots = [
  ...invoiceCoreShots,
  ...invoicePayShots,
  ...invoiceReqShots,
  ...invoiceSetShots,
  ...invoiceSetShotsCore,
  ...invoiceActShots,
  ...invoiceActShotsCore,
  ...invoiceHelpShots,
];
