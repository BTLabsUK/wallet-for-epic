// SPDX-License-Identifier: Apache-2.0
/// The test drivers' stable names for the controls they press (`Semantics.identifier`, the
/// resource-id on Android). The ids are generated from `tools/rellib/drivers/trust_ids.json`
/// into `trust_ids.g.dart`: a new or renamed id is `tools/ui-targets add` or `rename`, and
/// `tools/ui-targets check` ends any UI change. An id never changes with the wording or the
/// language.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'trust_ids_env.dart';

part 'trust_ids.g.dart';

/// Whether the controls carry their ids. Off only in test/trust_ids_semantics_test.dart, which
/// builds each screen with and without ids and expects a screen reader to get the same tree.
@visibleForTesting
bool trustIdsOn = true;

/// Whether an id also goes in its node's label, as `⟦id⟧`. Flutter's Linux embedder hands AT-SPI only
/// the label and the value, so `identifier` never reaches a Linux lane; its sandbox sets
/// WFE_TRUST_IDS=1 and tools/rellib/drivers/linux/atspi.py takes the mark back out. Off everywhere else.
@visibleForTesting
bool trustIdsInLabels = trustIdsEnv;

/// Names a control for the drivers: [id] joins the semantics node that [child]'s own semantics
/// end in, and changes nothing else. `Semantics(identifier:)` is not used for this: an identifier
/// there starts a node of its own, which splits a control from the tooltip, label or button it
/// shares a node with (a password field read as its "Show" button). Around a widget that makes
/// its own node (a Material button or list tile), the mark goes inside it, on the label or the
/// icon: outside, the id lands on the node around the control, or on none.
class TrustId extends StatelessWidget {
  const TrustId(this.id, {super.key, required this.child});

  final String? id;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (trustIdsOn ? id : null) {
    final id? => _TrustIdMark(id, child: child),
    // No id: nothing in between, so the control's own render object is still the top one.
    null => child,
  };
}

class _TrustIdMark extends SingleChildRenderObjectWidget {
  const _TrustIdMark(this.id, {required Widget super.child});

  final String id;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTrustId(id);

  @override
  void updateRenderObject(BuildContext context, _RenderTrustId renderObject) => renderObject.id = id;
}

class _RenderTrustId extends RenderProxyBox {
  _RenderTrustId(this._id);

  String _id;
  set id(String value) {
    if (value == _id) return;
    _id = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.identifier = _id;
    if (trustIdsInLabels) {
      config.label = '⟦$_id⟧';
      config.textDirection ??= TextDirection.ltr;
    }
  }
}

/// The id for a `Semantics(container: true, excludeSemantics: true)` node, which no [TrustId]
/// reaches: inside, the mark is dropped; around it, the mark lands on the node above.
String? trustNode(String id) => trustIdsOn ? id : null;

/// [TrustId] around [child].
Widget trustId(String id, Widget child) => TrustId(id, child: child);
