// SPDX-License-Identifier: Apache-2.0
/// Settings › Donate (desktop) and Help › Donate (phone), item 4: BT Labs' donation page opens
/// in the browser. Its address is `[donate] page` of `settings.toml`; when the page is not set
/// or does not answer, the app shows the donation address (`support.donation` of
/// `app-config.toml`) with Copy and QR, and `[donate] contact`, the contact page. No host is
/// written in the code.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'net/http.dart' show httpGet;
import 'net/http_types.dart' show NetError, NetTooLarge;
import 'network_gate.dart' show NetGate;
import 'settings_file/host_settings.dart';
import 'settings_file/settings_providers.dart' show hostSettingsProvider;

/// What Donate offers, from the two settings files: each part null when not configured.
class DonateLink {
  const DonateLink({this.page, this.contact, this.address});

  /// [settings]' donate page, contact page and donation address.
  factory DonateLink.of(HostSettings settings) => DonateLink(
    page: _https(settings.donatePage),
    contact: _https(settings.donateContact),
    address: settings.supportDonation,
  );

  /// The donation page; null: none, Donate shows the address and the contact page.
  final Uri? page;

  /// The contact page offered when the donation page does not answer.
  final Uri? contact;

  /// The Epicbox address donations go to.
  final String? address;

  /// Anything to show: Donate's entry is hidden without it.
  bool get any => page != null || contact != null || address != null;

  static Uri? _https(String v) {
    final u = v.isEmpty ? null : Uri.tryParse(v);
    return u != null && u.scheme == 'https' && u.host.isNotEmpty ? u : null;
  }
}

/// Donate's page, contact page and address, following `settings.toml` as it changes.
final donateLinkProvider = Provider<DonateLink>((ref) => DonateLink.of(ref.watch(hostSettingsProvider)));

/// What the check before opening the donation page found.
enum DonateCheck {
  /// It answered: open it.
  answers,

  /// It did not answer in time, or answered with an error: show the address and contact page.
  noAnswer,

  /// Node only or Kill switch: nothing may connect, so the page is not asked; the address
  /// and contact page show.
  skipped,

  /// No donation page is set.
  none,
}

/// Asks [link]'s donation page once, the way the network mode lets the app's own requests go
/// (over Tor with the Tor switch on or in Tor only). [get] stands in for the request in tests.
Future<DonateCheck> checkDonatePage(
  DonateLink link, {
  Duration? timeout,
  Future<int> Function(Uri page, Duration timeout)? get,
}) async {
  final page = link.page;
  if (page == null) return DonateCheck.none;
  if (NetGate.restricted) return DonateCheck.skipped;
  final wait = timeout ?? hostSettings.config.pageCheck;
  try {
    final status = await (get ?? _status)(page, wait);
    return status >= 200 && status < 400 ? DonateCheck.answers : DonateCheck.noAnswer;
  } on NetTooLarge {
    // A long page answered: only its length passed the check's limit.
    return DonateCheck.answers;
  } on NetError {
    return DonateCheck.noAnswer;
  } on Object {
    return DonateCheck.noAnswer;
  }
}

Future<int> _status(Uri page, Duration timeout) async => (await httpGet(page, timeout: timeout, maxBytes: 64 * 1024)).status;
