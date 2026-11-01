// SPDX-License-Identifier: Apache-2.0
/// The To field's controller on the phone and the desktop: draws a typed or pasted link's
/// scheme and host (and an onion address) in lower case ([displayCase]), as every other place
/// shows them, while its text stays exactly what was typed. What is parsed and sent is the
/// text, so the display never changes a payment.
library;

import 'package:flutter/widgets.dart';

import 'address_format.dart';

class AddressFieldController extends TextEditingController {
  AddressFieldController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final shown = displayCase(text);
    if (shown == text) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    // [displayCase] keeps the length, so the cursor, the selection and the composing range
    // still fall on the same characters.
    final composing = value.composing;
    if (!withComposing || !value.isComposingRangeValid) return TextSpan(style: style, text: shown);
    final under = (style ?? const TextStyle()).merge(const TextStyle(decoration: TextDecoration.underline));
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: composing.textBefore(shown)),
        TextSpan(style: under, text: composing.textInside(shown)),
        TextSpan(text: composing.textAfter(shown)),
      ],
    );
  }
}
