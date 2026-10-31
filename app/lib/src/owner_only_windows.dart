// SPDX-License-Identifier: Apache-2.0
/// Windows: keeps the desktop data folder to the account that runs the app ([ownerOnly] in
/// `data_folder_io.dart`). Plain `dart:io`, so a check can run it on Windows without Flutter.
///
/// The folder gets a protected access list of two entries, full control for the process's user
/// (by SID, from `whoami`, never by name) and for `SYSTEM`, both inherited by everything below;
/// the entries it inherited, such as `Administrators` from the profile folder, are dropped, and
/// Windows passes the new list down to the files that inherit theirs. LEPIC does the same for a
/// wallet database (`restrict_to_owner` in `lepic-store`).
///
/// Nothing can lock the app out of its folder: the grant runs first and the inherited entries go
/// only after it succeeded, a folder outside the user's profile is left alone (another account's
/// folder, a shared drive), and a folder without inherited entries is not touched again.
library;

import 'dart:io';

/// Runs a program; tests pass a fake.
typedef RunProcess = Future<ProcessResult> Function(String executable, List<String> arguments);

/// `SYSTEM`: Windows itself, backup and the file indexer run as it.
const String _systemSid = 'S-1-5-18';

/// What [restrictFolderToOwner] did.
enum OwnerOnlyResult {
  /// The access list was set now.
  restricted,

  /// It had no inherited entry: set before, or by the user.
  alreadyRestricted,

  /// Left as it was: outside the profile, or a step failed before anything changed.
  skipped,

  /// Granted, but the inherited entries could not be dropped: the user keeps access.
  partial,
}

/// Sets [path]'s access list as the library comment says, when [path] is inside [profile]
/// (`%USERPROFILE%`).
Future<OwnerOnlyResult> restrictFolderToOwner(String path, {required String? profile, String systemRoot = r'C:\Windows', RunProcess run = Process.run}) async {
  if (profile == null || profile.isEmpty || !_inside(path, profile)) return OwnerOnlyResult.skipped;
  final system32 = '$systemRoot\\System32';
  try {
    final listed = await run('$system32\\icacls.exe', [path]);
    if (listed.exitCode != 0) return OwnerOnlyResult.skipped;
    if (!inheritsEntries('${listed.stdout}')) return OwnerOnlyResult.alreadyRestricted;
    final who = await run('$system32\\whoami.exe', ['/user', '/fo', 'csv', '/nh']);
    final sid = who.exitCode == 0 ? sidFromWhoami('${who.stdout}') : null;
    if (sid == null) return OwnerOnlyResult.skipped;
    final grant = await run('$system32\\icacls.exe', [path, '/grant:r', '*$sid:(OI)(CI)F', '*$_systemSid:(OI)(CI)F', '/q']);
    if (grant.exitCode != 0) return OwnerOnlyResult.skipped;
    final cut = await run('$system32\\icacls.exe', [path, '/inheritance:r', '/q']);
    return cut.exitCode == 0 ? OwnerOnlyResult.restricted : OwnerOnlyResult.partial;
  } on ProcessException {
    return OwnerOnlyResult.skipped;
  }
}

/// Whether an `icacls` listing shows an inherited entry, marked `(I)` in every language.
bool inheritsEntries(String listing) => listing.contains('(I)');

/// The SID in `whoami /user /fo csv /nh` output (`"host\user","S-1-5-21-…"`); null for anything
/// else.
String? sidFromWhoami(String csv) {
  final sid = csv.trim().split(',').last.replaceAll('"', '');
  return RegExp(r'^S-1(-\d+){1,15}$').hasMatch(sid) ? sid : null;
}

bool _inside(String path, String profile) {
  String norm(String p) => p.replaceAll('/', r'\').replaceFirst(RegExp(r'\\+$'), '').toLowerCase();
  final base = norm(profile);
  return norm(path).startsWith('$base\\');
}
