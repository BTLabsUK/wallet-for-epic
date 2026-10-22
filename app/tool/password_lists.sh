#!/usr/bin/env bash
# Rebuilds the word lists behind the password crack-time hint (lib/src/password_estimate.dart)
# from zxcvbn-ts's npm packages: assets/passwords/<lang>.txt.gz and assets/passwords/NOTICE.txt.
#
# Usage: tool/password_lists.sh
#
# Each .gz holds lines of words; a line "@<dictionary>" starts a new list of that kind
# (passwords, diceware, commonWords, names, wikipedia), ranked by its order. Needs node and
# network access. The versions are pinned below; change them on purpose, then re-run the tests.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$app_dir/assets/passwords"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

packages=(
  language-common@4.1.3 language-en@4.1.1 language-de@4.1.1 language-pl@4.1.1
  language-ru@4.1.0 language-zh@4.1.1 dictionary-compression@3.0.1
)
for p in "${packages[@]}"; do
  name="${p%@*}" version="${p#*@}"
  mkdir -p "$work/node_modules/@zxcvbn-ts/$name"
  curl -fsSL "https://registry.npmjs.org/@zxcvbn-ts/$name/-/$name-$version.tgz" \
    | tar xz -C "$work/node_modules/@zxcvbn-ts/$name" --strip-components=1
done

mkdir -p "$out"
cat > "$work/dump.cjs" <<'JS'
// Prints one package's lists in the asset format. Word sequences have no zxcvbnm matcher: left out.
const [, , lang] = process.argv;
const { dictionary } = require(`@zxcvbn-ts/language-${lang}`);
const kinds = [
  [/^passwords-/, 'passwords'], [/^diceware-/, 'diceware'], [/^commonWords-/, 'commonWords'],
  [/[fF]irstnames-|[lL]astnames-/, 'names'], [/^wikipedia-/, 'wikipedia'],
];
const lines = [];
for (const [key, words] of Object.entries(dictionary)) {
  const kind = kinds.find(([re]) => re.test(key));
  if (!kind) continue;
  lines.push(`@${kind[1]}`);
  for (const w of words) {
    if (!w || w.startsWith('@') || w.includes('\n')) continue;
    lines.push(w);
  }
}
process.stdout.write(lines.join('\n') + '\n');
JS
for lang in common en de pl ru zh; do
  (cd "$work" && node dump.cjs "$lang") | gzip -9n > "$out/$lang.txt.gz"
done

{
  echo 'Word lists for the password estimate: zxcvbn-ts language packages'
  echo '(https://github.com/zxcvbn-ts/zxcvbn), MIT. Their notices follow.'
  for lang in common en de pl ru zh; do
    dir="$work/node_modules/@zxcvbn-ts/language-$lang"
    echo; echo "=== @zxcvbn-ts/language-$lang ==="
    cat "$dir/LICENSE.txt"
    for f in NOTICE.md THIRD_PARTY_LICENSES.md; do
      [[ -f "$dir/$f" ]] && { echo; cat "$dir/$f"; }
    done
  done
} > "$out/NOTICE.txt"
ls -l "$out"
