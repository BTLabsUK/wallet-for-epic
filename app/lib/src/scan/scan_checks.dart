/// The address checks the scan router runs, from the wallet service: LEPIC's own checks, the
/// ones Send runs.
library;

import '../recipient.dart';
import '../wallet_service.dart';
import 'scan_router.dart';

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
