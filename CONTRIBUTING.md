# Contributing

Thank you for helping. Bug reports, translations and code are all welcome.

## Before you start

- Wallet engine changes (slates, keys, transactions, Epicbox, the node client) belong in
  [LEPIC](https://github.com/BTLabsUK/lepic), and binding changes in
  [lepic-flutter](https://github.com/BTLabsUK/lepic-flutter). This repository is the app.
- For anything larger than a small fix, open an issue first so we can agree on the approach.
- Security problems go to support@btlabs.uk, never to a public issue ([SECURITY.md](SECURITY.md)).

## Making a change

1. Build the app as the [README](README.md#build-from-source) describes.
2. Keep each commit to one logical change and stage files by name.
3. Before you open a pull request, run `tools/check.sh` from the repository root: it checks
   LEPIC at the pin, runs the analyzer and the tests your change reaches (`tools/t`, which you
   can also run alone; `tools/t --list` shows which and why). See [docs/TESTING.md](docs/TESTING.md). How a release runs: [docs/HOW-A-RELEASE-RUNS.md](docs/HOW-A-RELEASE-RUNS.md).
4. User-facing text goes through the ARB files in `app/lib/l10n/` (English in `app_en.arb`); run
   `tools/l10n sync` after editing them. It adds your keys to the other languages in English and
   lists them in `app/lib/l10n/untranslated.json`; `l10n_quality_test` stays red until they are
   translated, which a maintainer may do.
5. Tests that need the network stay opt-in (they skip without their environment variables).
   Never add a test that reaches a real node, relay or Tor to the default test run.

## Commit messages

One plain sentence or two that say what changed and why, in the present tense, for example
`Send: the fee line shows before the amount is typed`. Sign your commits off (`git commit -s`):
by adding `Signed-off-by` you certify the [DCO 1.1](https://developercertificate.org/), that you
wrote the change or have the right to submit it under the project's licence (Apache-2.0).

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
