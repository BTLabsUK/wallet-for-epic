/// The address checks the scan router runs, from the wallet service: LEPIC's own checks, the
/// ones Send runs.
library;

import '../recipient.dart';
import '../wallet_service.dart';
import 'scan_router.dart';

/// Where a payment code came from, for the review's origin line.
enum CodeOrigin {
  /// Read by the camera.
  qr,

  /// Opened from a link in another app.
  link,

  /// Pasted.
  paste,
}

/// [AddressCheck] on [service]: the checksum, chain and host Send checks.
AddressCheck scanCheckFor(WalletService service) => (to) {
  switch (to.kind) {
    case RecipientKind.epicbox:
      if (service.validateEpicboxAddress(address: to.address)) {
        return AddressVerdict.valid;
      }
      return service.epicboxAddressOtherChain(address: to.address)
          ? AddressVerdict.otherChain
          : AddressVerdict.invalid;
    case RecipientKind.tor:
      return service.validateOnionAddress(address: to.address)
          ? AddressVerdict.valid
          : AddressVerdict.invalid;
    case RecipientKind.http:
      return httpAddressComplete(to.address)
          ? AddressVerdict.valid
          : AddressVerdict.invalid;
  }
};

/// What [text] is, checked against [service].
ScannedCode classifyFor(WalletService service, String text) =>
    classifyScan(text, check: scanCheckFor(service));

/// The address in [text] for a field that takes only an address (a contact, an invoice
/// payer): an `epic:` code's address, or a bare address cleaned up; anything else as it was,
/// for the field's own check to speak.
String addressOfScan(WalletService service, String text) =>
    switch (classifyFor(service, text)) {
      PaymentRequest(:final recipient) => recipient.address,
      ScannedAddress(:final recipient) => recipient.address,
      WrongNetwork(:final recipient) => recipient.address,
      _ => text,
    };
