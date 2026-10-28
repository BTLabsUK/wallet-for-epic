# Security policy

## Reporting a vulnerability

Do not open a public issue. Email **support@btlabs.uk**, or use GitHub's private vulnerability
reporting: the "Security" tab of this repository, then "Report a vulnerability".

Include the app and version (Settings › About shows it), the platform, what an attacker controls,
what happens, and the smallest reproduction you have. We answer within a few days and agree a
disclosure date with you once a fix is ready.

## Scope

In scope: anything in this repository that can lose or lock funds, leak a recovery phrase, keys,
PIN or wallet data, make the app accept or show a wrong payment, or crash it from untrusted input
(QR codes and payment links, slate files, backups, node and relay responses), and the update and
install paths (signed update manifests, downloaded installers).

The wallet engine is [LEPIC](https://github.com/BTLabs-EPIC/lepic) and the Flutter binding is
[lepic-flutter](https://github.com/BTLabs-EPIC/lepic-flutter); report engine issues there the same
way. Issues in the Epic Cash node, the reference wallet or the Epicbox relay belong to those
projects: report them to them privately and tell us only what we need to protect our users.

## Supported versions

Only the latest release of Epic Cash Desktop and Epic Cash Mobile receives fixes. The app tells
you when a newer version is available.
