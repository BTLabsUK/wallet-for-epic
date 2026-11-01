# Live Stack Wallet check

Run once on the release candidate, by a tester agent, before the release. Stack Wallet is wallet B;
the candidate build is wallet A; wallet P funds both. Mainnet, small amounts only. It proves that
Stack Wallet, which never acknowledges a message that is not a slate, keeps its queue intact when
our build pays it, answers a slate that carries the new marker key, and pays a listing address.

## Set-up (nothing here creates or funds a wallet)

- Emulator `wfe_sw` (android-36 google_apis x86_64, pixel_7, port 5560; the other QA emulators are
  never touched). `sw-apk.sh fetch && sw-apk.sh start && sw-apk.sh install`. The APK is pinned in
  `apk.lock` (official GitHub release, version, sha256, signer); the script refuses anything else.
  Stack Wallet 2.7.1 is already installed on `wfe_sw` (no wallet in it); `sw-apk.sh status` shows it.
- Candidate A: the release candidate's Linux AppImage in a sandbox (as `trust-linux.sh` does), or the
  candidate APK on `wfe_qa`. A has its own new wallet.
- Wallet P: its service as in `docs/RELEASING.md` ("Test wallets"). Before and after, check P keeps
  8–20 outputs (`p_outputs`); never leave it below 8.
- Servers, in this order, in A and in Stack Wallet: node https://node.btlabs.uk, then
  node.epicnet.us:3413, then node.epiccash.com last; Epicbox epicbox.stackwallet.com, then
  epicbox.epicnet.us, then epiccash.com last. Read the chain tip first. Record which were used.
- In Stack Wallet (by hand through the emulator's screen, `adb shell input` or the tester's
  UI driver): create a wallet on Epic Cash mainnet, write down nothing outside the run folder, set the Epicbox
  server as above. Total funds in B and A together stay under 0.3 EPIC for the whole check.
- After each step run `SW_OUT=<run folder> ./sw-evidence.sh <step>`: screenshot, the app's log lines,
  and the count of "unable to parse" lines (must stay 0).

## 1. The queue survives

1. P pays B 0.05 over Epicbox; wait until B shows it spendable. P pays A 0.1; wait likewise.
2. A pays B 0.01 over Epicbox. Before A's send is finished (A offline for the finalize, or paused
   by the tester), a second sender (P's CLI, a different key from A's) pays B 0.01. Then A comes back
   and finalizes.
3. A pays B three more times, 0.01 each, one after the other.
4. Assert: B received all four of A's payments and the second sender's; B's history has no
   failed or stuck receive; the "unable to parse" count in B's log stays 0 at every evidence point; each of
   A's payments shows as finished on A. A must not have sent B any message that is not a slate:
   A's transaction rows for B show no "posted" or "cancelled" notice sent, and A's log has no line for one
   (the build sends those only to a wallet its record marks as ours; B is not).
5. Record, for each payment, A's amount, B's received amount and the time.

## 2. Stack Wallet answers a slate with the marker key

1. With A at the candidate and B never paid by this A before (use a second Epicbox address in B if
   needed, or the first payment of step 1), A pays B 0.01. The first slate A sends carries the
   marker key `f`; check it in A's log or the relay-side capture when the tester has one.
2. Assert: B answers (the transaction completes on both sides, amounts right, one confirmation
   reached), B's log has no parse error, and A records B as "answered by another wallet app", not as one of ours.
3. A pays B once more; assert the same, and that A still sends nothing but slates.

## 3. Stack Wallet pays a listing address

1. In A create a listing address as the candidate offers it (Receive); copy it as shown.
2. In B send 0.01 to that address over Epicbox. Wait for the receive to finish on A.
3. Assert: A shows the payment received at the listing address; B shows the send finished;
   amounts right. If the candidate offers a proof request step, a request to a listing address is refused
   (expected, record the wording B shows).
4. B sends 0.01 once more; assert the same.

## Finish

- Send what is left in B and A back to P; confirm P's output count (8–20).
- `sw-apk.sh stop`. If B's wallet is to be removed, uninstall the app (`adb -s emulator-5560 uninstall
  com.cypherstack.stackwallet`) and run `sw-apk.sh install` again for a clean image.
- Report: candidate commit, Stack Wallet version and sha256 (from `apk.lock`), servers used, per
  step pass/fail with the evidence file names, B's and A's final balances, P's output count.
