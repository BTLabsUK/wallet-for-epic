// SPDX-License-Identifier: Apache-2.0
/// The 256 entries of the pairing word table, LEPIC's `testdata/sas/emoji-v1.txt` (RFC 0002
/// 7.5), in its order: byte value `i` is entry `i`. The four words of a check and the five
/// pairing words are entries of it; the Enter link or words field completes names from it.
/// The table is LEPIC's: a new version comes with the binding, never edited here.
library;

import 'models.dart' show SasWord;

const List<SasWord> sasTable = [
  SasWord('🐱', 'kitty'),
  SasWord('🐰', 'bunny'),
  SasWord('🦊', 'vixen'),
  SasWord('🐻', 'bear'),
  SasWord('🐯', 'tigress'),
  SasWord('🐮', 'heifer'),
  SasWord('🐷', 'piggy'),
  SasWord('🐸', 'froggy'),
  SasWord('🐵', 'chimp'),
  SasWord('🐧', 'penguin'),
  SasWord('🦆', 'mallard'),
  SasWord('🦉', 'owlet'),
  SasWord('🦇', 'bat'),
  SasWord('🐗', 'warthog'),
  SasWord('🐝', 'bumble'),
  SasWord('🐛', 'grub'),
  SasWord('🐌', 'snail'),
  SasWord('🐞', 'beetle'),
  SasWord('🐍', 'viper'),
  SasWord('🦎', 'gecko'),
  SasWord('🦖', 'rex'),
  SasWord('🦕', 'bronto'),
  SasWord('🐙', 'kraken'),
  SasWord('🦑', 'squid'),
  SasWord('🦐', 'prawn'),
  SasWord('🦀', 'crab'),
  SasWord('🐡', 'puffer'),
  SasWord('🐠', 'guppy'),
  SasWord('🐬', 'porpoise'),
  SasWord('🐳', 'humpback'),
  SasWord('🦈', 'shark'),
  SasWord('🐊', 'gator'),
  SasWord('🐘', 'jumbo'),
  SasWord('🦛', 'hippo'),
  SasWord('🦏', 'rhino'),
  SasWord('🐪', 'camel'),
  SasWord('🦘', 'roo'),
  SasWord('🐂', 'ox'),
  SasWord('🐑', 'ewe'),
  SasWord('🦙', 'llama'),
  SasWord('🐐', 'billy'),
  SasWord('🦌', 'buck'),
  SasWord('🐩', 'poodle'),
  SasWord('🐓', 'rooster'),
  SasWord('🦚', 'peacock'),
  SasWord('🦜', 'polly'),
  SasWord('🦢', 'swan'),
  SasWord('🦨', 'skunk'),
  SasWord('🦡', 'badger'),
  SasWord('🦦', 'otter'),
  SasWord('🦥', 'sloth'),
  SasWord('🐀', 'rodent'),
  SasWord('🐉', 'wyvern'),
  SasWord('🐾', 'paws'),
  SasWord('🌲', 'spruce'),
  SasWord('🌱', 'sprout'),
  SasWord('🌿', 'herb'),
  SasWord('🌾', 'sheaf'),
  SasWord('🍀', 'clover'),
  SasWord('🍂', 'leaves'),
  SasWord('🍄', 'toadstool'),
  SasWord('💐', 'bouquet'),
  SasWord('🌷', 'tulip'),
  SasWord('🌹', 'rosebud'),
  SasWord('🥀', 'wilted'),
  SasWord('🌼', 'daisy'),
  SasWord('🌛', 'crescent'),
  SasWord('⭐', 'star'),
  SasWord('⚡', 'zap'),
  SasWord('💥', 'boom'),
  SasWord('🌈', 'rainbow'),
  SasWord('☔', 'brolly'),
  SasWord('⛄', 'snowman'),
  SasWord('💧', 'droplet'),
  SasWord('🌊', 'surf'),
  SasWord('🍉', 'melon'),
  SasWord('🍇', 'grapes'),
  SasWord('🍓', 'berry'),
  SasWord('🍒', 'cherries'),
  SasWord('🍑', 'peach'),
  SasWord('🍆', 'eggplant'),
  SasWord('🥬', 'kale'),
  SasWord('🥒', 'pickle'),
  SasWord('🥕', 'carrot'),
  SasWord('🥔', 'spud'),
  SasWord('🍠', 'yam'),
  SasWord('🥐', 'croissant'),
  SasWord('🍞', 'loaf'),
  SasWord('🥖', 'baguette'),
  SasWord('🥨', 'pretzel'),
  SasWord('🥞', 'pancake'),
  SasWord('🍗', 'drumstick'),
  SasWord('🌭', 'hotdog'),
  SasWord('🍟', 'fries'),
  SasWord('🥪', 'sandwich'),
  SasWord('🌮', 'taco'),
  SasWord('🍿', 'popcorn'),
  SasWord('🥫', 'tin'),
  SasWord('🍱', 'bento'),
  SasWord('🍘', 'cracker'),
  SasWord('🍛', 'curry'),
  SasWord('🍜', 'ramen'),
  SasWord('🍝', 'pasta'),
  SasWord('🍣', 'sushi'),
  SasWord('🥟', 'dumpling'),
  SasWord('🥡', 'takeout'),
  SasWord('🍦', 'cone'),
  SasWord('🍩', 'donut'),
  SasWord('🍪', 'cookie'),
  SasWord('🎂', 'birthday'),
  SasWord('🧁', 'cupcake'),
  SasWord('🥧', 'pie'),
  SasWord('🍫', 'choc'),
  SasWord('🍭', 'lollipop'),
  SasWord('🍮', 'custard'),
  SasWord('🍼', 'bottle'),
  SasWord('🍵', 'tea'),
  SasWord('🍶', 'sake'),
  SasWord('🍾', 'bubbly'),
  SasWord('🍹', 'cocktail'),
  SasWord('🍺', 'pint'),
  SasWord('🥂', 'cheers'),
  SasWord('🥃', 'whisky'),
  SasWord('🥢', 'chopsticks'),
  SasWord('🏺', 'urn'),
  SasWord('🗻', 'fuji'),
  SasWord('🏠', 'house'),
  SasWord('⛲', 'fountain'),
  SasWord('🌁', 'misty'),
  SasWord('🎡', 'ferris'),
  SasWord('🎢', 'coaster'),
  SasWord('💈', 'barber'),
  SasWord('🎪', 'circus'),
  SasWord('🚂', 'steam'),
  SasWord('🚓', 'cop'),
  SasWord('🚕', 'taxicab'),
  SasWord('🚚', 'lorry'),
  SasWord('🚜', 'tractor'),
  SasWord('🛵', 'scooter'),
  SasWord('⛵', 'sailboat'),
  SasWord('🚢', 'liner'),
  SasWord('🚁', 'chopper'),
  SasWord('🛸', 'saucer'),
  SasWord('🪂', 'chute'),
  SasWord('⌛', 'hourglass'),
  SasWord('🎈', 'balloon'),
  SasWord('🎀', 'bow'),
  SasWord('🥎', 'softball'),
  SasWord('🏀', 'hoops'),
  SasWord('🏈', 'football'),
  SasWord('🥏', 'frisbee'),
  SasWord('🎳', 'bowling'),
  SasWord('🏏', 'wicket'),
  SasWord('🏓', 'pingpong'),
  SasWord('🏸', 'shuttle'),
  SasWord('🥊', 'boxing'),
  SasWord('🥋', 'judo'),
  SasWord('🥅', 'goalnet'),
  SasWord('⛳', 'golf'),
  SasWord('🎣', 'fishing'),
  SasWord('🎽', 'jersey'),
  SasWord('🎿', 'skis'),
  SasWord('🛷', 'sled'),
  SasWord('🥌', 'curling'),
  SasWord('🎯', 'bullseye'),
  SasWord('🎱', 'eightball'),
  SasWord('🎮', 'joystick'),
  SasWord('🎰', 'jackpot'),
  SasWord('🧩', 'jigsaw'),
  SasWord('🧸', 'teddy'),
  SasWord('🎭', 'masks'),
  SasWord('🎨', 'palette'),
  SasWord('🧵', 'thread'),
  SasWord('🧶', 'yarn'),
  SasWord('👓', 'glasses'),
  SasWord('👔', 'necktie'),
  SasWord('👕', 'shirt'),
  SasWord('🧣', 'scarf'),
  SasWord('🧤', 'gloves'),
  SasWord('🧥', 'coat'),
  SasWord('🧦', 'socks'),
  SasWord('👜', 'handbag'),
  SasWord('🎒', 'backpack'),
  SasWord('👞', 'loafer'),
  SasWord('👟', 'sneaker'),
  SasWord('👠', 'heels'),
  SasWord('👑', 'crown'),
  SasWord('🎩', 'tophat'),
  SasWord('🎓', 'grad'),
  SasWord('💄', 'lipstick'),
  SasWord('💎', 'gem'),
  SasWord('🔔', 'bell'),
  SasWord('🎵', 'tune'),
  SasWord('🎤', 'mic'),
  SasWord('🎧', 'headset'),
  SasWord('🎹', 'keys'),
  SasWord('🎻', 'fiddle'),
  SasWord('🥁', 'drums'),
  SasWord('📟', 'pager'),
  SasWord('📠', 'fax'),
  SasWord('💾', 'floppy'),
  SasWord('💿', 'disc'),
  SasWord('📺', 'telly'),
  SasWord('💡', 'lightbulb'),
  SasWord('🔦', 'flashlight'),
  SasWord('🏮', 'lantern'),
  SasWord('📜', 'scroll'),
  SasWord('💰', 'loot'),
  SasWord('📦', 'parcel'),
  SasWord('📫', 'mailbox'),
  SasWord('📝', 'memo'),
  SasWord('💼', 'briefcase'),
  SasWord('📁', 'folder'),
  SasWord('📌', 'pushpin'),
  SasWord('📏', 'ruler'),
  SasWord('🔒', 'padlock'),
  SasWord('🔧', 'wrench'),
  SasWord('🔩', 'bolt'),
  SasWord('🧪', 'testtube'),
  SasWord('💉', 'syringe'),
  SasWord('🚿', 'shower'),
  SasWord('🛁', 'bathtub'),
  SasWord('🧴', 'lotion'),
  SasWord('🧽', 'sponge'),
  SasWord('🧼', 'suds'),
  SasWord('🛒', 'trolley'),
  SasWord('🗿', 'moai'),
  SasWord('🚩', 'pennant'),
  SasWord('🪀', 'yoyo'),
  SasWord('🪐', 'saturn'),
  SasWord('🪓', 'axe'),
  SasWord('🪕', 'banjo'),
  SasWord('🪄', 'wand'),
  SasWord('🪘', 'bongo'),
  SasWord('🪚', 'saw'),
  SasWord('🪝', 'hook'),
  SasWord('🪣', 'bucket'),
  SasWord('🪥', 'toothbrush'),
  SasWord('🪨', 'rock'),
  SasWord('🪵', 'log'),
  SasWord('🪶', 'feather'),
  SasWord('🦤', 'dodo'),
  SasWord('🦭', 'seal'),
  SasWord('🦣', 'mammoth'),
  SasWord('🦫', 'beaver'),
  SasWord('🦟', 'gnat'),
  SasWord('🪳', 'roach'),
  SasWord('🦠', 'microbe'),
  SasWord('🫓', 'flatbread'),
  SasWord('🫕', 'fondue'),
  SasWord('🫖', 'teapot'),
  SasWord('🧇', 'waffle'),
  SasWord('🥜', 'nuts'),
  SasWord('🌰', 'chestnut'),
  SasWord('🥥', 'coco'),
  SasWord('🧋', 'boba'),
];

/// The words in [text] as typed or pasted, one part per word: table names (any case) and
/// emoji, with or without spaces between them; punctuation, new lines and extra spaces are
/// ignored. An emoji next to its own name ("🐱 kitty" or "kitty 🐱", as a copy with both
/// carries) is one word. A part that names an entry reads as its name; anything else stays as
/// typed, so the field can still complete or mark it.
List<String> pairingWordParts(String text) {
  final raw = <String>[];
  final word = StringBuffer();
  void endWord() {
    if (word.isNotEmpty) raw.add(word.toString());
    word.clear();
  }

  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (_letter.hasMatch(ch)) {
      word.write(ch);
    } else {
      endWord();
      if (!_gap.hasMatch(ch)) raw.add(ch);
    }
  }
  endWord();
  final parts = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final here = sasWordNamed(raw[i]) ?? sasWordOfEmoji(raw[i]);
    if (here != null && i + 1 < raw.length) {
      final emoji = sasWordOfEmoji(raw[i]) != null;
      final next = sasWordNamed(raw[i + 1]) ?? sasWordOfEmoji(raw[i + 1]);
      // One emoji and one name of the same entry side by side: a word copied with its emoji.
      if (next == here && emoji != (sasWordOfEmoji(raw[i + 1]) != null)) {
        parts.add(here.name);
        i++;
        continue;
      }
    }
    parts.add(here?.name ?? raw[i]);
  }
  return parts;
}

final _letter = RegExp(r'\p{L}', unicode: true);

/// Space, punctuation and the joiners and selectors emoji carry: what separates words.
final _gap = RegExp(r'^[\s\p{P}\u{FE0E}\u{FE0F}\u{200D}]$', unicode: true);

/// The entry named [name] (any case, surrounding space ignored), or null.
SasWord? sasWordNamed(String name) {
  final wanted = name.trim().toLowerCase();
  for (final w in sasTable) {
    if (w.name == wanted) return w;
  }
  return null;
}

/// The entry whose emoji is [emoji], or null.
SasWord? sasWordOfEmoji(String emoji) {
  final wanted = emoji.trim();
  for (final w in sasTable) {
    if (w.emoji == wanted) return w;
  }
  return null;
}

/// Entries whose name starts with [prefix] (two letters or more), at most [limit], in table order.
List<SasWord> sasCompletions(String prefix, {int limit = 3}) {
  final p = prefix.trim().toLowerCase();
  if (p.length < 2) return const [];
  return [
    for (final w in sasTable)
      if (w.name.startsWith(p)) w,
  ].take(limit).toList();
}
