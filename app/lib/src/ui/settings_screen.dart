// SPDX-License-Identifier: Apache-2.0
/// Settings on the phone: a search field and the places settings live in, each with one line of
/// what it holds now. Security, Payments, Appearance, Network & privacy, Advanced and This wallet
/// open a page each (`settings_sections.dart`); Linked devices and Help have their own screens.
/// The hub is a tab's root (no back link) and also opens over another screen (with one).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../devices/phone_devices.dart' show linkedDevicesOnProvider, phoneDevices;
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../trust_ids.dart';
import 'backup_screen.dart' show backedUpProvider;
import 'common.dart';
import 'devices/linked_devices_screen.dart' show LinkedDevicesScreen;
import 'help_screen.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_search_field.dart';
import 'kit/kit_settings.dart' show KitTag;
import 'kit/kit_connection_dot.dart';
import 'kit/kit_tokens.dart';
import 'network_mode_text.dart' show networkModeName;
import 'phone_frame.dart' show phoneFrameBreakpoint;
import 'restore_screen.dart' show ScanSlotLine;
import 'settings_phone.dart';
import 'settings_sections.dart';
import 'status.dart' show EpicboxState, NodeState, watchWalletStatus;
import 'theme/brand.dart' show EpicMark;
import 'theme/tokens.dart';

export 'settings_sections.dart';

/// Opens Settings at Network & privacy, where the Tor switch is: the page over the hub, so
/// Back lands on the hub.
Future<void> openPrivacySettings(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const SettingsScreen(privacy: true)),
);

/// The key of a hub row, for tests: `settingsGroupKey(SettingsSection.x)`.
Key settingsGroupKey(SettingsSection section) => ValueKey('settings-group-${section.name}');

/// The key of the hub's Help row, for tests.
const Key settingsHelpKey = ValueKey('settings-group-help');

/// The key of the hub's search field, for tests.
const Key settingsSearchKey = ValueKey('settings-search');

/// The key of a search result, for tests: `settings-result-<n>`, in the order shown.
Key settingsResultKey(int index) => ValueKey('settings-result-$index');

/// The Settings hub. With [section] (or [privacy], the Network & privacy page), that page
/// opens over the hub on arrival.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.privacy = false, this.section});

  /// Opens the Network & privacy page at once.
  final bool privacy;

  /// The page to open at once.
  final SettingsSection? section;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final section = widget.section ?? (widget.privacy ? SettingsSection.privacyNetwork : null);
    if (section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openSettingsSection(context, section);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDevices() => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const LinkedDevicesScreen()));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final scan = ref.watch(scanProvider);
    final walletOpen = ref.watch(sessionProvider) != null;
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final biometrics = ref.watch(biometricsProvider).value;
    final mode = ref.watch(networkModeProvider);
    final status = watchWalletStatus(ref);
    final linkedOn = walletOpen && ref.watch(linkedDevicesOnProvider);
    final deviceLinked = ref.watch(phoneDevices.view)?.book.linked != null;
    final pushed = Navigator.of(context).canPop();
    final query = _search.text.trim();

    // The wallet is "connected" with the node up and Epicbox up or not asked for by the mode.
    final connected = status.node.state == NodeState.online && (mode.restricted || status.epicbox == null || status.epicbox == EpicboxState.online);

    // One line under each place: what it holds now.
    final lockLine = [
      if (biometrics?.enabled ?? false) l.phoneSettingsBiometrics else l.phoneSettingsPinWord,
      if (s.autoLockMinutes case final m?) l.phoneSettingsLocksAfter(autoLockDuration(l, m)),
    ].join(' · ');
    final payments = s.payments;
    final ways = [
      if (payments.offers(MethodKind.epicbox)) MethodIcons.groupName(l, MethodKind.epicbox),
      if (payments.offers(MethodKind.directQr)) l.phoneSettingsHubInPerson,
      if (payments.offers(MethodKind.directFile)) l.phoneSettingsHubFile,
      if (payments.offers(MethodKind.linkTor)) l.phoneSettingsHubTor,
    ].join(', ');
    final lookLine = [
      themeLabel(l, s.themeMode),
      languageLabel(l, s.language),
      s.fiatCurrency.toUpperCase(),
    ].join(' · ');

    Widget place(SettingsSection section, {Widget? sub, String? line, Widget? trailing}) => KitRow(
      key: settingsGroupKey(section),
      size: KitRowSize.list,
      leading: KitIconWell(settingsSectionIcon(section), color: t.accent, iconSize: 20),
      title: settingsSectionTitle(l, section),
      subtitle: line,
      subtitleWidget: sub,
      trailing: trailing,
      chevron: true,
      semanticsId: TrustIds.settingsSection(section.name),
      onTap: () => openSettingsSection(context, section),
    );

    final children = <Widget>[
      if (!scan.running && scan.error != null)
        Padding(padding: const EdgeInsets.all(Kit.gutter), child: ErrorText(describeError(l, scan.error!))),
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: KitSearchField(
          key: settingsSearchKey,
          controller: _search,
          hint: l.phoneSettingsSearchHint,
          onChanged: (_) => setState(() {}),
          semanticsId: TrustIds.settingsSearch,
        ),
      ),
      if (query.isNotEmpty)
        ..._results(l, query, walletOpen: walletOpen, linkedOn: linkedOn)
      else ...[
        if (walletOpen) ...[
          KitGroup(
            children: [
              KitRow(
                key: settingsGroupKey(SettingsSection.wallet),
                size: KitRowSize.list,
                minHeight: 72,
                leading: KitIconWell.child(EpicMark(size: 28, color: t.accent), size: 46, radius: 15),
                title: settingsSectionTitle(l, SettingsSection.wallet),
                subtitleWidget: _PhraseLine(backedUp: backedUp),
                chevron: true,
                semanticsId: TrustIds.settingsSection(SettingsSection.wallet.name),
                onTap: () => openSettingsSection(context, SettingsSection.wallet),
              ),
            ],
          ),
          const SizedBox(height: 14),
          KitGroup(
            children: [
              place(SettingsSection.security, line: lockLine),
              place(SettingsSection.transactions, line: ways),
              place(SettingsSection.display, line: lookLine),
            ],
          ),
          const SizedBox(height: 14),
        ],
        KitGroup(
          children: [
            if (!walletOpen) place(SettingsSection.display, line: lookLine),
            place(SettingsSection.privacyNetwork, sub: _NetworkLine(mode: mode, connected: connected)),
            if (linkedOn)
              KitRow(
                key: settingsLinkedDevicesKey,
                size: KitRowSize.list,
                leading: KitIconWell(KitIcons.devices, color: t.accent, iconSize: 20),
                title: l.expLinkedDevices,
                subtitle: deviceLinked ? l.phoneSettingsOneLinked : l.phoneSettingsNoneLinked,
                trailing: KitTag(l.settingsExperimentTag),
                chevron: true,
                semanticsId: TrustIds.settingsLinkedDevices,
                onTap: _openDevices,
              ),
          ],
        ),
        const SizedBox(height: 14),
        KitGroup(
          children: [
            KitRow(
              key: settingsHelpKey,
              size: KitRowSize.list,
              leading: KitIconWell(KitIcons.help, color: t.accent, iconSize: 20),
              title: l.settingsSectionHelpFeedback,
              subtitle: l.phoneSettingsHelpLine,
              chevron: true,
              semanticsId: TrustIds.settingsHelp,
              onTap: () => openHelp(context, null, null, l.settingsTitle),
            ),
            place(SettingsSection.advanced, line: l.phoneSettingsAdvancedLine),
          ],
        ),
      ],
    ];

    return SlotScaffold(
      idle: scan.running ? ScanSlotLine(scan: scan) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: phoneFrameBreakpoint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pushed)
                  KitPageHeader(
                    backLabel: l.phoneKitBack,
                    onBack: () => Navigator.of(context).maybePop(),
                    title: l.settingsTitle,
                    backId: TrustIds.settingsPageBack,
                  )
                else
                  KitTabTitle(l.settingsTitle),
                Expanded(
                  child: Builder(
                    builder: (context) => ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: DockSlack.pad(context, const EdgeInsets.only(bottom: Kit.gutter * 2)),
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The rows whose names hold [query]: each opens the page it is on.
  List<Widget> _results(AppLocalizations l, String query, {required bool walletOpen, required bool linkedOn}) {
    final q = query.toLowerCase();
    final hits = <(String, SettingsSection)>[
      for (final (title, section) in _index(l, walletOpen))
        if (title.toLowerCase().contains(q) || settingsSectionTitle(l, section).toLowerCase().contains(q)) (title, section),
    ];
    final devices = linkedOn && l.expLinkedDevices.toLowerCase().contains(q);
    if (hits.isEmpty && !devices) {
      return [KitEmptyState(icon: KitIcons.search, title: l.phoneSettingsNoMatch)];
    }
    var i = 0;
    return [
      KitGroup(
        children: [
          for (final (title, section) in hits)
            KitRow(
              key: settingsResultKey(i++),
              size: KitRowSize.list,
              title: title,
              subtitle: settingsSectionTitle(l, section),
              chevron: true,
              semanticsId: TrustIds.settingsResult,
              onTap: () => openSettingsSection(context, section),
            ),
          if (devices)
            KitRow(
              key: settingsResultKey(i++),
              size: KitRowSize.list,
              title: l.expLinkedDevices,
              chevron: true,
              semanticsId: TrustIds.settingsResult,
              onTap: _openDevices,
            ),
        ],
      ),
    ];
  }

  /// Every row of the pages, by name and page: what the search looks through.
  List<(String, SettingsSection)> _index(AppLocalizations l, bool walletOpen) => [
    if (walletOpen) ...[
      (l.backupTitle, SettingsSection.security),
      (l.phoneSettingsBiometrics, SettingsSection.security),
      (l.settingsAutoLock, SettingsSection.security),
      (l.settingsChangePin, SettingsSection.security),
      (l.phoneSettingsPassphrase, SettingsSection.security),
      (l.phoneSettingsLockNow, SettingsSection.security),
      (MethodIcons.groupName(l, MethodKind.epicbox), SettingsSection.transactions),
      (l.phoneSettingsInPerson, SettingsSection.transactions),
      (l.phoneSettingsWithFile, SettingsSection.transactions),
      (l.phoneSettingsTorAddress, SettingsSection.transactions),
      (l.outputsStrategy, SettingsSection.transactions),
      (l.settingsInvoices, SettingsSection.transactions),
      (l.phoneSettingsExport, SettingsSection.wallet),
      (l.phoneSettingsImport, SettingsSection.wallet),
      (l.phoneSettingsCsv, SettingsSection.wallet),
      (l.settingsRescan, SettingsSection.wallet),
      (l.outputsTitle, SettingsSection.wallet),
      (l.phoneSettingsRestore, SettingsSection.wallet),
      (l.settingsDeleteWallet, SettingsSection.wallet),
    ],
    (l.settingsTheme, SettingsSection.display),
    (l.languageSetting, SettingsSection.display),
    (l.settingsCurrency, SettingsSection.display),
    (l.settingsShowPrices, SettingsSection.display),
    (l.phoneSettingsHideAmounts, SettingsSection.display),
    (l.serverEpicboxTitle, SettingsSection.privacyNetwork),
    (l.serverNodeTitle, SettingsSection.privacyNetwork),
    (l.advNodeFailover, SettingsSection.privacyNetwork),
    for (final m in NetworkMode.values) (networkModeName(l, m), SettingsSection.privacyNetwork),
    (l.advOutputs, SettingsSection.advanced),
    (l.advTechnical, SettingsSection.advanced),
    (l.advSendOptions, SettingsSection.advanced),
    (l.advServerDetails, SettingsSection.advanced),
    (l.advRecheckHeight, SettingsSection.advanced),
    (l.advBalanceHeader, SettingsSection.advanced),
  ];
}

/// "✓ Recovery phrase backed up" in green, or the warning in its colour with a mark.
class _PhraseLine extends StatelessWidget {
  const _PhraseLine({required this.backedUp});

  final bool backedUp;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final color = backedUp ? t.ok : t.warn;
    final text = backedUp ? l.phoneSettingsPhraseBackedUp : l.settingsStateBackUp;
    return Row(
      children: [
        ExcludeSemantics(child: Icon(backedUp ? KitIcons.check : Icons.error_outline, size: 16, color: color)),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: KitType.rowSub.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// "● Normal · connected": the mode, with the dot of the Home status pill.
class _NetworkLine extends StatelessWidget {
  const _NetworkLine({required this.mode, required this.connected});

  final NetworkMode mode;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Row(
      children: [
        KitConnectionDot(ready: connected),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${networkModeName(l, mode)} · ${connected ? l.phoneSettingsConnected : l.phoneSettingsNotConnected}',
            style: KitType.rowSub.copyWith(color: t.dim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
