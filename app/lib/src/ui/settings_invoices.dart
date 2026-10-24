import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../app_log.dart';
import '../contacts.dart' show RecipientKind, parseRecipient;
import '../errors.dart';
import '../l10n.dart';
import '../models.dart';
import '../providers.dart';
import '../scan/scan_checks.dart' show addressOfScan;
import 'common.dart';
import 'contacts_screen.dart' show LiveFieldError;
import 'scan_screen.dart';
import 'theme/advanced.dart';
import 'theme/tokens.dart';

/// Settings > Invoices: the invoice address the user hands to services, and the services
/// allowed to bill it (UP-14). Only reached when the open wallet supports invoices.
///
/// Nothing here pays. A trusted service may only send invoices; each one waits for the user
/// on the Invoices screen.
class InvoiceSettingsScreen extends ConsumerStatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  ConsumerState<InvoiceSettingsScreen> createState() =>
      _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends ConsumerState<InvoiceSettingsScreen> {
  bool _rotating = false;

  void _say(String message, {required NoticeLevel level}) =>
      ref.read(noticeProvider.notifier).show(message, level: level);

  Future<void> _add() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const TrustedServiceAddScreen()),
  );

  Future<void> _remove(TrustedService service) async {
    final name = _serviceName(service);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.invoiceSettingsRemoveTitle(name)),
          content: Text(l.invoiceSettingsRemoveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.invoiceSettingsKeep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.invoiceSettingsRemoveConfirm),
            ),
          ],
        );
      },
    );
    if (sure != true || !mounted) return;
    try {
      await ref.read(trustedServicesProvider.notifier).remove(service.address);
      if (mounted) {
        _say(
          context.l10n.invoiceSettingsRemoved(name),
          level: NoticeLevel.success,
        );
      }
    } catch (error) {
      logWarn('invoices', 'removing a trusted service failed: $error');
      if (mounted) {
        _say(describeError(context.l10n, error), level: NoticeLevel.error);
      }
    }
  }

  Future<void> _rotate() async {
    if (_rotating) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.invoiceSettingsRotateTitle),
          content: Text(l.invoiceSettingsRotateBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.invoiceSettingsKeep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.invoiceSettingsRotateConfirm),
            ),
          ],
        );
      },
    );
    if (sure != true || !mounted) return;
    setState(() => _rotating = true);
    try {
      await rotateInvoiceAddress(ref);
      if (mounted) {
        _say(context.l10n.invoiceSettingsRotated, level: NoticeLevel.success);
      }
    } catch (error) {
      logWarn('invoices', 'rotating the invoice address failed: $error');
      if (mounted) {
        _say(describeError(context.l10n, error), level: NoticeLevel.error);
      }
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }

  /// The user's label, or the short address when the label was lost.
  String _serviceName(TrustedService s) => s.label ?? shortAddress(s.address);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final address = ref.watch(invoiceAddressProvider);
    final services = ref.watch(trustedServicesProvider);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.invoiceSettingsTitle)),
      body: ScreenBody(
        children: [
          _SectionTitle(l.invoiceSettingsAddressTitle),
          Text(l.invoiceSettingsAddressBody),
          const SizedBox(height: 16),
          switch (address) {
            AsyncData(value: final a?) => _InvoiceAddress(address: a),
            AsyncError(:final error) => ErrorText(describeError(l, error)),
            AsyncData() => const SizedBox.shrink(),
            _ => const LinearProgressIndicator(),
          },
          const SizedBox(height: 24),
          _SectionTitle(l.invoiceSettingsServicesTitle),
          switch (services) {
            AsyncData(:final value) when value.isEmpty => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.invoiceSettingsNoServices),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final s in value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(_serviceName(s)),
                    subtitle: Text(
                      shortAddress(s.address),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: l.invoiceSettingsRemoveTooltip(_serviceName(s)),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(s),
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorText(describeError(l, error)),
            _ => const LinearProgressIndicator(),
          },
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(l.invoiceSettingsAddService),
          ),
          // Rotation and the dropped count are technical; the simple path never needs them.
          Advanced(
            feature: AdvancedFeature.technicalDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.autorenew),
                  title: Text(l.invoiceSettingsRotate),
                  subtitle: Text(l.invoiceSettingsRotateHint),
                  enabled: !_rotating,
                  onTap: _rotate,
                ),
                Readout(
                  l.invoiceSettingsDropped(
                    ref.watch(droppedInvoiceMessagesProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// The invoice address as a QR code in Receive's style, with the address and Copy.
class _InvoiceAddress extends ConsumerWidget {
  const _InvoiceAddress({required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Dark modules on white scan reliably in either theme, as on Receive.
              color: Colors.white,
              borderRadius: BorderRadius.circular(t.radiusSmall),
              border: Border.all(color: t.line),
            ),
            child: Semantics(
              label: l.invoiceSettingsQrLabel,
              image: true,
              child: SizedBox.square(
                dimension: 200,
                child: PrettyQrView.data(data: address),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Copy and the QR code always carry the full address; on screen it is short unless
        // Advanced options is on, as on Receive.
        SelectableText(
          AdvancedOptions.has(context, AdvancedFeature.serverDetails)
              ? address
              : shortAddress(address, ownServer: ownEpicboxServer(ref)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(fontFamily: t.monoFamily),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () =>
              copyText(context, address, l.invoiceSettingsAddressCopied),
          icon: const Icon(Icons.copy),
          label: Text(l.commonCopy),
        ),
      ],
    );
  }
}

/// Adds a trusted service: the full epicbox address it shows (pasted or scanned) and the
/// user's own label for it. Pops when saved.
class TrustedServiceAddScreen extends ConsumerStatefulWidget {
  const TrustedServiceAddScreen({super.key});

  @override
  ConsumerState<TrustedServiceAddScreen> createState() =>
      _TrustedServiceAddScreenState();
}

class _TrustedServiceAddScreenState
    extends ConsumerState<TrustedServiceAddScreen> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  String? _labelError;
  String? _addressError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _address.text = text;
    setState(() => _addressError = null);
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text == null || !mounted) return;
    _address.text = parseRecipient(
      addressOfScan(ref.read(walletServiceProvider), text),
    ).address;
    setState(() => _addressError = null);
  }

  /// Null for a full epicbox address, else why not. A wallet URL is no service address.
  String? _checkAddress(AppLocalizations l, String text) {
    if (text.trim().isEmpty) return l.invoiceSettingsAddressMissing;
    final recipient = parseRecipient(text);
    final valid =
        recipient.kind == RecipientKind.epicbox &&
        ref
            .read(walletServiceProvider)
            .validateEpicboxAddress(address: recipient.address);
    return valid
        ? null
        : l.contactsAddressInvalid('es5x…@epicbox.epiccash.com');
  }

  Future<void> _save() async {
    if (_busy) return;
    final l = context.l10n;
    final label = _label.text.trim();
    setState(() {
      _labelError = label.isEmpty ? l.invoiceSettingsLabelMissing : null;
      _addressError = _checkAddress(l, _address.text);
      _error = null;
    });
    if (_labelError != null || _addressError != null) return;
    setState(() => _busy = true);
    try {
      final added = await ref
          .read(trustedServicesProvider.notifier)
          .add(address: parseRecipient(_address.text).address, label: label);
      if (!mounted) return;
      ref
          .read(noticeProvider.notifier)
          .show(
            context.l10n.invoiceSettingsAdded(added.label ?? label),
            level: NoticeLevel.success,
          );
      Navigator.pop(context);
    } catch (error) {
      logWarn('invoices', 'adding a trusted service failed: $error');
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scan = offersQrScan(ref);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.invoiceSettingsAddTitle)),
      body: ScreenBody(
        bottom: BusyButton(
          label: l.invoiceSettingsAddButton,
          busy: _busy,
          onPressed: _save,
        ),
        children: [
          Text(l.invoiceSettingsAddExplanation),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _labelError = null),
            decoration: InputDecoration(
              labelText: l.invoiceSettingsLabelLabel,
              error: _labelError == null ? null : LiveFieldError(_labelError!),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: null,
            onChanged: (_) => setState(() => _addressError = null),
            decoration: InputDecoration(
              labelText: l.invoiceSettingsServiceAddressLabel,
              error: _addressError == null
                  ? null
                  : LiveFieldError(_addressError!),
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.commonPaste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                  if (scan)
                    IconButton(
                      tooltip: l.scanQrTooltip,
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
        ],
      ),
    );
  }
}
