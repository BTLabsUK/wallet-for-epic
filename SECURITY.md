# Security policy

## Reporting a vulnerability

Do not open a public issue. Email **support@btlabs.uk**, or open a *confidential* issue on GitLab
(New issue, then tick "Turn on confidentiality"); only the maintainers can see it.

Include the app and version (Settings › About shows it), the platform, what an attacker controls,
what happens, and the smallest reproduction you have. We answer within a few days and agree a
disclosure date with you once a fix is ready.

## Scope

In scope: anything in this repository that can lose or lock funds, leak a recovery phrase, keys,
PIN or wallet data, make the app accept or show a wrong payment, or crash it from untrusted input
(QR codes and payment links, slate files, backups, node and relay responses), and the update and
install paths (signed update manifests, downloaded installers).

The wallet engine is [LEPIC](https://gitlab.com/epic-cash-bt/lepic) and the Flutter binding is
[lepic-flutter](https://gitlab.com/epic-cash-bt/lepic-flutter); report engine issues there the same
way. Issues in the Epic Cash node, the reference wallet or the Epicbox relay belong to those
projects: report them to them privately and tell us only what we need to protect our users.

## What the app protects, and its limits

[THREAT_MODEL.md](THREAT_MODEL.md) says what the relay, a node, the network, another app, a phone thief and
desktop malware can and cannot do, and states the known limits. Among them: the 6-digit PIN against a
copied phone store, recovery-phrase screenshots being allowed, plain-`http://` sends, and the unencrypted
wallet database. There has been no external audit yet.

## Update signing keys

Update manifests are signed with Ed25519. Apps carry two keys: rank 1 signs releases, and rank 2 is the next
key, not kept on the build machine. If the rank-1 key is ever compromised, BT Labs signs a manifest with the
rank-2 key that revokes rank 1. Apps then drop rank 1 for good, and a stolen rank-1 key can neither revoke
rank 2 nor hide that revocation. The next app release ships a new pair. If both keys are lost, only an app
release with a new keyring can restore updates; installed apps keep working meanwhile. Android builds are
also tied to one signing certificate: an update signed with any other is refused by Android itself.

## Supported versions

Only the latest release of Epic Cash Desktop and Epic Cash Mobile receives fixes. The app tells
you when a newer version is available.
