# Person walk

A person walks each platform of the candidate once, on its test build or release file, before the
publish gate opens. Tests do not cover these. Record each platform:

    tools/rel walk <platform> ok|fail [--note "what you saw"]

The result sits on the gate note; a platform with no result shows "not walked yet".

## android
- Background: send the app away for a few minutes while a payment is due; come back. It is still
  connected and the payment shows.
- Unlock: lock the phone, open the app, unlock with PIN and with the fingerprint.
- Update: install over the last release. Wallets, history and settings are there.
- CPU: leave the app open on the home screen. The phone stays cool, the battery screen shows no spike.

## ios
- Background: leave the app, come back after a few minutes. It reconnects and shows new payments.
- Unlock: close and reopen the app, unlock with PIN and Face ID.
- Update: install over the last TestFlight build. Wallets, history and settings are there.
- CPU: leave the app open on the home screen. The phone stays cool.

## linux
- Background: minimise the window, restore it. It is still connected.
- Unlock: quit and reopen, unlock with the password.
- Update: take the update from inside the last release. Wallets and history are there.
- CPU: leave the app idle. `top` shows it near zero.

## windows
- Background: minimise to the taskbar, restore it. It is still connected.
- Unlock: quit and reopen, unlock with the password.
- Update: take the update from inside the last release. Wallets and history are there.
- CPU: leave the app idle. Task Manager shows it near zero.

## macos
- Background: hide the window, bring it back. It is still connected.
- Unlock: quit and reopen, unlock with the password.
- Update: install over the last release. Wallets and history are there.
- CPU: leave the app idle. Activity Monitor shows it near zero.
