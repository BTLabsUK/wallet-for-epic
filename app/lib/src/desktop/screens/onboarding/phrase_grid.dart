// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../desk_l10n.dart';
import '../../../bip39_words.dart';
import '../../data/phrase_check.dart' show bip39List;
import '../../widgets/kit.dart';

/// Phrase lengths a wallet accepts.
const phraseLengths = [12, 15, 18, 21, 24];

/// The words typed or pasted into the restore grid, and what they add up to. The grid shows
/// [max] numbered fields; a paste sets [count], typing never does. Words are checked against the
/// list when a field loses focus or a word is committed (Space, Comma, Tab, Enter), never while
/// it is being typed. The checksum ([check]) runs once the first 12, 15, 18, 21 or 24 fields are
/// filled and the rest are empty.
class PhraseEntry extends ChangeNotifier {
  PhraseEntry({required this.check});

  static const max = 24;

  /// Checksum of a phrase of a valid length (the wallet core's `validateMnemonic`).
  final bool Function(List<String> words) check;

  final controllers = [for (var i = 0; i < max; i++) TextEditingController()];
  final focus = [for (var i = 0; i < max; i++) FocusNode(debugLabel: 'Word ${i + 1}')];

  /// The word count a paste set; null while the typed words decide.
  int? count;

  /// How many words a paste had when that is not a phrase length (12, 15, 18, 21 or 24), until the next change.
  int? pasteError;

  /// Fields holding a word that is not in the list (checked on blur or commit).
  final Set<int> invalid = {};

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focus) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get words => [for (final c in controllers) c.text.trim().toLowerCase()];

  /// Non-empty fields.
  int get filled => words.where((w) => w.isNotEmpty).length;

  /// One past the last non-empty field.
  int get span {
    final ws = words;
    for (var i = max - 1; i >= 0; i--) {
      if (ws[i].isNotEmpty) return i + 1;
    }
    return 0;
  }

  /// No empty field before the last filled one.
  bool get contiguous => words.take(span).every((w) => w.isNotEmpty);

  /// Whether the first [n] words are in the list.
  bool _listed(int n) => words.take(n).every(bip39Words.contains);

  /// The typed length when it is one a wallet accepts, every field up to it is filled and in
  /// the list, and nothing follows; null otherwise.
  int? get _typedLength {
    final n = span;
    return phraseLengths.contains(n) && contiguous && _listed(n) ? n : null;
  }

  /// The checksum verdict: for a pasted count, once its fields are filled and in the list; while
  /// typing, whenever the typed words make a phrase of a valid length. Null before that.
  bool? get checksumOk {
    final c = count;
    if (c != null) {
      return span == c && contiguous && _listed(c) ? _check(words.take(c).toList()) : null;
    }
    final n = _typedLength;
    return n == null ? null : _check(words.take(n).toList());
  }

  /// [check] of the last word list asked about, kept: the grid asks on every rebuild.
  String? _checked;
  bool _checkedOk = false;

  bool _check(List<String> ws) {
    final key = ws.join(' ');
    if (key != _checked) {
      _checked = key;
      _checkedOk = check(ws);
    }
    return _checkedOk;
  }

  /// The length the phrase is taken to have: the pasted count, else the typed length when its
  /// checksum passes, else 24.
  int get length => count ?? (checksumOk == true ? span : max);

  /// A phrase typed to a shorter valid length whose checksum fails may still be on its way to
  /// a longer one; the verdict is firm once 24 fields are filled or a paste set the count.
  bool get checksumFirm => count != null || span == max;

  bool get complete => checksumOk == true;

  /// Whether the last filled field is still being typed (no paste set the count): its word
  /// may be a prefix of the one meant ("fat" of "fatigue"), so no checksum verdict shows yet.
  bool get typingLast => count == null && span > 0 && focus[span - 1].hasFocus;

  /// Whether Enter may leave the phrase step: a pasted phrase that checks out, or all 24
  /// fields typed and checking out. A shorter typed phrase goes on with the Continue button,
  /// so Enter after each word of a 24-word phrase never stops at a 12-word prefix that happens
  /// to pass the checksum.
  bool get submittable => complete && (count != null || span == max);

  List<String> get phrase => words.take(length).toList();

  /// Every bad field as (place from 1, word), in field order.
  List<(int, String)> get unknownWords => [for (final i in invalid.toList()..sort()) (i + 1, words[i])];

  /// The first bad field, or null.
  int? get firstInvalid => invalid.isEmpty ? null : (invalid.toList()..sort()).first;

  static final _separators = RegExp(r'[\s,;]+');
  static final _numbering = RegExp(r'^\d+[.):-]?');
  static final _letter = RegExp('[a-z]');

  /// Words of a pasted text: line breaks, commas and numbering like "1.", "2)ability" or
  /// "3 - able" are dropped, and a full stop after a word; a piece with no letter is no word.
  static List<String> split(String text) => [
    for (final piece in text.toLowerCase().split(_separators))
      if (_word(piece) case final w when _letter.hasMatch(w)) w,
  ];

  static String _word(String piece) {
    final w = piece.replaceFirst(_numbering, '');
    return w.endsWith('.') ? w.substring(0, w.length - 1) : w;
  }

  /// A paste: fills from field 1 and sets [count] when the number of words is one a wallet
  /// accepts. Every pasted word is checked at once. Returns the words placed.
  List<String> paste(String text) {
    final ws = split(text);
    if (ws.isEmpty) return ws;
    for (var i = 0; i < max; i++) {
      controllers[i].text = i < ws.length ? ws[i] : '';
    }
    invalid.clear();
    for (var i = 0; i < max && i < ws.length; i++) {
      if (!bip39Words.contains(ws[i])) invalid.add(i);
    }
    if (phraseLengths.contains(ws.length)) {
      count = ws.length;
      pasteError = null;
    } else {
      count = null;
      pasteError = ws.length;
    }
    _notify();
    return ws;
  }

  /// The clipboard's [text] pasted into field [i], in place of what the field held: several
  /// words fill from field 1 ([paste]), one word goes into field [i].
  void pasteInto(int i, String text) {
    final ws = split(text);
    if (ws.isEmpty) return;
    if (ws.length > 1) {
      paste(text);
      _focusAfter(ws.length);
      return;
    }
    controllers[i].value = TextEditingValue(text: ws.first, selection: TextSelection.collapsed(offset: ws.first.length));
    changed(i, ws.first);
    validate(i);
  }

  /// A field's text changed by typing (or text arriving some other way than the clipboard).
  void changed(int i, String text) {
    // Several words at once: a paste. It fills from field 1 whichever field took it. A digit
    // or a single word is typing and leaves the focus where it is.
    if (split(text).length > 1) {
      _focusAfter(paste(text).length);
      return;
    }
    final c = count;
    if (c != null && i >= c && text.trim().isNotEmpty) count = null;
    pasteError = null;
    if (invalid.contains(i) && (text.trim().isEmpty || bip39Words.contains(text.trim().toLowerCase()))) {
      invalid.remove(i);
    }
    _notify();
  }

  /// Checks field [i] against the list (blur or commit).
  /// Tells listeners the focus moved between fields (see [typingLast]).
  void focusMoved() => _notify();

  void validate(int i) {
    final w = words[i];
    final bad = w.isNotEmpty && !bip39Words.contains(w);
    if (bad ? invalid.add(i) : invalid.remove(i)) _notify();
  }

  /// The dim completion for field [i]: the first list word starting with the typed letters, when
  /// two or more are typed and they are not a word already. Tab takes it; Enter only from four
  /// letters on ([acceptsOnEnter]).
  String? suggestion(int i) {
    final typed = controllers[i].text.toLowerCase();
    if (typed.length < 2 || bip39Words.contains(typed)) return null;
    for (final w in bip39List) {
      if (w.startsWith(typed)) return w;
    }
    return null;
  }

  /// Whether Enter takes field [i]'s completion: four letters start one BIP-39 word only.
  bool acceptsOnEnter(int i) => controllers[i].text.trim().length >= 4;

  /// Puts the suggestion into field [i]; false when there is none.
  bool accept(int i) {
    final s = suggestion(i);
    if (s == null) return false;
    controllers[i].text = s;
    invalid.remove(i);
    _notify();
    return true;
  }

  void clear() {
    for (final c in controllers) {
      c.clear();
    }
    invalid.clear();
    count = null;
    pasteError = null;
    _notify();
  }

  /// [text] pasted from outside a field (the Paste button): fills like a paste and puts the
  /// focus in the grid (the first marked word, else after the last word), so Enter goes on
  /// from there instead of pressing the button again.
  void pasteAndFocus(String text) => _focusAfter(paste(text).length);

  void focusField(int i) {
    if (i < 0 || i >= max) return;
    focus[i].requestFocus();
    final c = controllers[i];
    c.selection = TextSelection.collapsed(offset: c.text.length);
  }

  void _focusAfter(int n) {
    final bad = firstInvalid;
    if (bad != null) {
      focusField(bad);
    } else if (n < max) {
      focusField(n);
    } else {
      focusField(max - 1);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// Lower-cases and turns line breaks and tabs into spaces (text from the keyboard; a paste reads
/// the clipboard itself).
class _WordFormatter extends TextInputFormatter {
  const _WordFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[\r\n\t]+'), ' ').toLowerCase();
    if (text == newValue.text) return newValue;
    return newValue.copyWith(text: text, composing: TextRange.empty);
  }
}

/// Twenty-four numbered word fields, as the phrase is written on paper. Space, Comma, Tab and
/// Enter commit a word and move on; Backspace in an empty field goes back; Tab takes the dim
/// completion, Enter from four letters; Enter on a [PhraseEntry.submittable] phrase calls
/// [onSubmit]. A paste (keys or menu) takes the clipboard, never the field's text joined with
/// it. Fields past [PhraseEntry.length] are dimmed, never marked.
class PhraseGrid extends StatefulWidget {
  const PhraseGrid({super.key, required this.entry, this.onSubmit, this.autofocus = false});

  final PhraseEntry entry;
  final VoidCallback? onSubmit;
  final bool autofocus;

  @override
  State<PhraseGrid> createState() => _PhraseGridState();
}

class _PhraseGridState extends State<PhraseGrid> {
  PhraseEntry get entry => widget.entry;
  final _listeners = <int, VoidCallback>{};

  @override
  void initState() {
    super.initState();
    _attach();
    entry.addListener(_changed);
  }

  @override
  void didUpdateWidget(PhraseGrid old) {
    super.didUpdateWidget(old);
    if (old.entry != entry) {
      _detach(old.entry);
      _attach();
      old.entry.removeListener(_changed);
      entry.addListener(_changed);
    }
  }

  void _attach() {
    for (var i = 0; i < PhraseEntry.max; i++) {
      final f = entry.focus[i];
      void onFocus() {
        if (!f.hasFocus) entry.validate(i);
        // The status line ([PhraseEntry.typingLast]) depends on which field has the focus.
        entry.focusMoved();
        if (mounted) setState(() {});
      }

      _listeners[i] = onFocus;
      f.addListener(onFocus);
      f.onKeyEvent = (node, event) => _key(i, event);
    }
  }

  void _detach(PhraseEntry e) {
    for (var i = 0; i < PhraseEntry.max; i++) {
      final l = _listeners[i];
      if (l != null) e.focus[i].removeListener(l);
      e.focus[i].onKeyEvent = null;
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detach(entry);
    entry.removeListener(_changed);
    super.dispose();
  }

  KeyEventResult _key(int i, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final c = entry.controllers[i];
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.comma) {
      if (c.text.trim().isEmpty) return KeyEventResult.handled;
      _commit(i);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
      entry.accept(i);
      _commit(i);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (entry.acceptsOnEnter(i)) entry.accept(i);
      entry.validate(i);
      if (entry.submittable) {
        widget.onSubmit?.call();
      } else if (c.text.trim().isNotEmpty) {
        _next(i);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && event is KeyDownEvent && c.text.isEmpty && i > 0) {
      entry.focusField(i - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _paste(int i) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    entry.pasteInto(i, data?.text ?? '');
  }

  void _commit(int i) {
    entry.validate(i);
    _next(i);
  }

  void _next(int i) {
    if (i + 1 < PhraseEntry.max) {
      entry.focusField(i + 1);
    } else {
      entry.focus[i].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final length = entry.length;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth < Lay.sm ? 2 : (box.maxWidth < Lay.md ? 3 : 4);
        final w = (box.maxWidth - (cols - 1) * Sp.x2) / cols;
        return Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (var i = 0; i < PhraseEntry.max; i++)
              SizedBox(
                width: w,
                child: _Cell(
                  index: i,
                  entry: entry,
                  focused: entry.focus[i].hasFocus,
                  invalid: entry.invalid.contains(i),
                  unused: i >= length,
                  autofocus: widget.autofocus && i == 0,
                  onPaste: () => _paste(i),
                  colors: c,
                  text: ts,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.entry,
    required this.focused,
    required this.invalid,
    required this.unused,
    required this.autofocus,
    required this.onPaste,
    required this.colors,
    required this.text,
  });

  final int index;
  final PhraseEntry entry;
  final bool focused, invalid, unused, autofocus;
  final VoidCallback onPaste;
  final DeskColors colors;
  final DeskText text;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final ts = text;
    final border = invalid
        ? c.risk
        : focused
        ? c.accent
        : c.line;
    final style = ts.mono(size: Fs.md);
    final controller = entry.controllers[index];
    final typed = controller.text;
    final suggestion = focused ? entry.suggestion(index) : null;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: context.l10n.deskOnbWordN(index + 1),
      child: Opacity(
        opacity: unused && !focused ? 0.45 : 1,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : Dur.fast,
          height: 40.u,
          padding: EdgeInsets.symmetric(horizontal: Sp.x3),
          decoration: BoxDecoration(
            color: c.s2,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: border),
            boxShadow: focused ? [BoxShadow(color: invalid ? c.riskSoft : c.accentSoft, spreadRadius: 2.u)] : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20.u,
                child: Text('${index + 1}', textAlign: TextAlign.right, style: ts.mono(size: 11, color: invalid ? c.risk : c.faint)),
              ),
              SizedBox(width: Sp.x2),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (suggestion != null)
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: typed, style: style.copyWith(color: Colors.transparent)),
                                TextSpan(text: suggestion.substring(typed.length), style: style.copyWith(color: c.faint)),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ),
                    // Ctrl+V and the menu's Paste read the clipboard themselves.
                    Actions(
                      actions: {
                        PasteTextIntent: CallbackAction<PasteTextIntent>(
                          onInvoke: (_) {
                            onPaste();
                            return null;
                          },
                        ),
                      },
                      child: TextField(
                        controller: controller,
                        selectionControls: desktopTextSelectionControls,
                        focusNode: entry.focus[index],
                        autofocus: autofocus,
                        maxLines: 1,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: const [_WordFormatter()],
                        style: style,
                        cursorColor: c.accent,
                        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        contextMenuBuilder: (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: state.contextMenuAnchors,
                          buttonItems: [
                            for (final b in state.contextMenuButtonItems)
                              b.type == ContextMenuButtonType.paste
                                  ? b.copyWith(
                                      onPressed: () {
                                        state.hideToolbar();
                                        onPaste();
                                      },
                                    )
                                  : b,
                          ],
                        ),
                        onChanged: (v) => entry.changed(index, v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
