import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
export 'help_topics.dart' show pairingHelpSection, pairingHelpTopics;

/// Opens Help at a section: scrolls to it and opens its first topic.
class HelpAt {
  const HelpAt(this.section, {this.topic = 0});

  final String section;

  /// Which topic of the section opens.
  final int topic;

  @override
  bool operator ==(Object other) => other is HelpAt && other.section == section && other.topic == topic;

  @override
  int get hashCode => Object.hash(section, topic);
}

String pairingHelpTitle(AppLocalizations l) => l.helpPairingSection;
String pairingHelpLede(AppLocalizations l) => l.helpPairingLede;

/// The Pairing section's art, the size of HelpArt: the verified shield in a ticked tile.
class PairingHelpMark extends StatelessWidget {
  const PairingHelpMark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 96 / 160,
        child: Center(
          child: ETicked(
            child: SizedBox.square(
              dimension: width * 0.45,
              child: Icon(EIcons.trusted, size: width * 0.24, color: c.accentText),
            ),
          ),
        ),
      ),
    );
  }
}
