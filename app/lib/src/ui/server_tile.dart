// SPDX-License-Identifier: Apache-2.0
/// A server's tile, shared by the phone's sheets and the desktop's panels: the operator's icon
/// from status.btlabs.uk (initials on a muted tint while there is none, or it fails), and the
/// health as a dot in the corner. Each app passes its own colours ([ServerTileColors]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../relay_directory.dart' show NodeHealthState, ServerIcon;
import '../server_icons.dart';
import '../server_list.dart' show serverInitials;

/// The colours a tile is painted in, from the app's theme.
@immutable
class ServerTileColors {
  const ServerTileColors({
    required this.surface,
    required this.line,
    required this.initials,
    required this.tints,
    required this.ok,
    required this.warn,
    required this.risk,
    required this.unknown,
    required this.ring,
  });

  /// The tile's ground and its hairline.
  final Color surface, line;

  /// The initials' colour.
  final Color initials;

  /// Muted tints for the initials' ground, one per operator by its name.
  final List<Color> tints;

  /// The dot: healthy, degraded, down; [unknown] is the hollow dot's line.
  final Color ok, warn, risk, unknown;

  /// The ring around a filled dot: the colour behind the tile.
  final Color ring;
}

class ServerTileView extends ConsumerWidget {
  const ServerTileView({
    super.key,
    required this.operator,
    required this.host,
    required this.icon,
    required this.state,
    required this.colors,
    this.dimmed = false,
    this.size = 36,
    this.radius = 6,
    this.fontFamily,
  });

  final String? operator;
  final String host;
  final ServerIcon? icon;

  /// The monitor's health, or null when it has nothing on the server: the dot is hollow.
  final NodeHealthState? state;
  final ServerTileColors colors;
  final bool dimmed;
  final double size;
  final double radius;
  final String? fontFamily;

  /// The key of a tile's image once its icon has loaded, for tests.
  static const Key imageKey = ValueKey('server-tile-image');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final known = state != null && state != NodeHealthState.unknown;
    final dot = switch (state) {
      NodeHealthState.healthy => c.ok,
      NodeHealthState.degraded => c.warn,
      NodeHealthState.down => c.risk,
      _ => c.unknown,
    };
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final url = icon?.forPixels(size * dpr);
    final bytes = url == null ? null : ref.watch(serverIconProvider(url)).value;
    // One operator keeps its tint everywhere: picked by the name.
    final seed = (operator ?? host).toLowerCase().codeUnits.fold<int>(
      17,
      (a, ch) => (a * 31 + ch) & 0x7fffffff,
    );
    final tint = c.tints.isEmpty
        ? c.surface
        : Color.alphaBlend(c.tints[seed % c.tints.length], c.surface);
    final initials = Center(
      child: Text(
        serverInitials(operator, host),
        style: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.33,
          letterSpacing: 0.5,
          color: c.initials,
          height: 1,
        ),
      ),
    );
    final inner = BorderRadius.circular((radius - 1).clamp(0, radius));
    return ExcludeSemantics(
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bytes != null ? c.surface : tint,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: bytes == null
                    ? initials
                    : ClipRRect(
                        borderRadius: inner,
                        child: Image.memory(
                          bytes,
                          key: imageKey,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          cacheWidth: (size * dpr).round(),
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => initials,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: known ? dot : c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: known ? c.ring : c.unknown, width: known ? 2 : 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
