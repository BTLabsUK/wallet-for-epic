// SPDX-License-Identifier: Apache-2.0
/// The desktop's side of the settings file (`settings_file/`, docs/settings-file.md): its
/// notices as toasts (a bad line, a conflict, a broken file saved aside), each shown once, and
/// a hand edit of the node or Epicbox server every wallet uses applied live: the open wallet
/// reconnects to the new node, or moves its address and listener to the new Epicbox server.
/// The app's own changes switch where they are made.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../log.dart';
import '../../settings_file/settings_notice.dart';
import '../../settings_file/settings_notice_text.dart';
import '../../settings_file/settings_providers.dart';
import '../data/desk_errors.dart' show deskErrorText;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;

/// Wraps the app below its localizations.
class DeskSettingsFileWatch extends ConsumerStatefulWidget {
  const DeskSettingsFileWatch({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeskSettingsFileWatch> createState() => _DeskSettingsFileWatchState();
}

class _DeskSettingsFileWatchState extends ConsumerState<DeskSettingsFileWatch> {
  StreamSubscription<UseChange>? _uses;

  @override
  void initState() {
    super.initState();
    _uses = hostUseChanges.listen((c) {
      if (!c.fromApp) unawaited(_apply(c));
    });
    ref.listenManual(settingsNoticesProvider, (_, notices) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(notices));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    unawaited(_uses?.cancel());
    super.dispose();
  }

  /// A hand edit of `node.use` or `epicbox.use`: the same switch the settings pages make.
  Future<void> _apply(UseChange c) async {
    final desk = ref.read(deskProvider.notifier);
    try {
      if (c.isNode) {
        await desk.useNode(c.to);
      } else {
        await desk.useEpicbox(c.to);
        _toast((l) => l.deskSendEpicboxSwitched(c.to), ETone.ok);
      }
    } on Object catch (e) {
      logWarn('settings', 'hand-edited ${c.key} not applied: ${e.runtimeType}');
      _toast((l) => l.deskSetRecvServerNotChanged, ETone.risk, text: (l) => deskErrorText(e, l));
    }
  }

  /// A toast on the navigator's page, the app's notice standard; false before it is up.
  bool _toast(String Function(AppLocalizations l) title, ETone tone, {String Function(AppLocalizations l)? text}) {
    final context = deskNavigatorKey.currentContext;
    if (context == null || !context.mounted) return false;
    final l = context.l10n;
    showEToast(context, title(l), text: text?.call(l), tone: tone);
    return true;
  }

  void _show(List<SettingsNotice> notices) {
    if (notices.isEmpty || !mounted) return;
    final shown = <SettingsNotice>[];
    for (final n in notices) {
      final error = n.kind == SettingsNoticeKind.syntaxError ||
          n.kind == SettingsNoticeKind.readFailed ||
          n.kind == SettingsNoticeKind.writeFailed;
      if (!_toast((l) => settingsNoticeText(l, n), error ? ETone.risk : ETone.warn)) break;
      shown.add(n);
    }
    final notifier = ref.read(settingsNoticesProvider.notifier);
    shown.forEach(notifier.dismiss);
    // The navigator was not up yet (the first frame): the rest come on the next one.
    if (shown.length < notices.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(ref.read(settingsNoticesProvider)));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
