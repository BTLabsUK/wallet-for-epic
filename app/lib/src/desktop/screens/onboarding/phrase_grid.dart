import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// "13 words pasted; a phrase has 12, 15, 18, 21 or 24", until the next change.
  String? pasteError;

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
      return span == c && contiguous && _listed(c) ? check(words.take(c).toList()) : null;
    }
    final n = _typedLength;
    return n == null ? null : check(words.take(n).toList());
  }

  /// The length the phrase is taken to have: the pasted count, else the typed length when its
  /// checksum passes, else 24.
  int get length => count ?? (checksumOk == true ? span : max);

  /// A phrase typed to a shorter valid length whose checksum fails may still be on its way to
  /// a longer one; the verdict is firm once 24 fields are filled or a paste set the count.
  bool get checksumFirm => count != null || span == max;

  bool get complete => checksumOk == true;

  List<String> get phrase => words.take(length).toList();

  /// The first bad field, or null.
  int? get firstInvalid => invalid.isEmpty ? null : (invalid.toList()..sort()).first;

  static final _numbering = RegExp(r'(^|\s)\d+[.):]?(?=\s|$)');
  static final _separators = RegExp(r'[\s,;]+');

  /// Words of a pasted text: line breaks, commas and numbering like "1." or "1)" are dropped.
  static List<String> split(String text) => text
      .replaceAll(_numbering, ' ')
      .split(_separators)
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toList();

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
      pasteError = '${ws.length} words pasted; a phrase has 12, 15, 18, 21 or 24';
    }
    _notify();
    return ws;
  }

  /// A field's text changed by typing or a paste into it.
  void changed(int i, String text) {
    if (_separators.hasMatch(text.trim()) || _numbering.hasMatch(text)) {
      // Several words at once: a paste. It fills from field 1 whichever field took it.
      final ws = paste(text);
      _focusAfter(ws.length);
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
  void validate(int i) {
    final w = words[i];
    final bad = w.isNotEmpty && !bip39Words.contains(w);
    if (bad ? invalid.add(i) : invalid.remove(i)) _notify();
  }

  /// The dim completion for field [i]: the first list word starting with the typed letters, when
  /// two or more are typed and they are not a word already.
  String? suggestion(int i) {
    final typed = controllers[i].text.toLowerCase();
    if (typed.length < 2 || bip39Words.contains(typed)) return null;
    for (final w in bip39List) {
      if (w.startsWith(typed)) return w;
    }
    return null;
  }

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

/// Lower-cases and turns line breaks into spaces, so a pasted list arrives as one line.
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
/// completion; Enter on a complete phrase calls [onSubmit]. Fields past [PhraseEntry.length]
/// are dimmed, never marked.
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
      entry.accept(i);
      entry.validate(i);
      if (entry.complete) {
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
        final cols = box.maxWidth < 480.u ? 2 : (box.maxWidth < 560.u ? 3 : 4);
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
    required this.colors,
    required this.text,
  });

  final int index;
  final PhraseEntry entry;
  final bool focused, invalid, unused, autofocus;
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
      label: 'Word ${index + 1}',
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
                    TextField(
                      controller: controller,
                      focusNode: entry.focus[index],
                      autofocus: autofocus,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: const [_WordFormatter()],
                      style: style,
                      cursorColor: c.accent,
                      decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                      onChanged: (v) => entry.changed(index, v),
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
