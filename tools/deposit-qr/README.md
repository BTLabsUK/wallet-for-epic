# Deposit QR

A QR code for an exchange's per-user deposit page. Epic Wallet scans it and opens Send with the address and the on-chain message filled in. The note stays editable: the wallet warns if it is emptied, and the user can still send. One file, no dependencies: `deposit-qr.js`.

The QR and the copy text hold this string:

```
epic:<key>@<relay>?message=<note>&require=message&min=<epic>&label=<text>
```

The "open with the wallet" link carries the same text with `epiccash:` as the scheme (desktop builds register only that one). `min` and `label` are optional; the wallet warns if the amount is under `min`.

`note` is required, at most 256 UTF-8 bytes. The generator refuses a bad address, an empty note or a malformed minimum. The code is level H, versions 1 to 20 (at most 382 bytes of text). With the sample address a plain ASCII note of 256 characters fits alone, with a label and a minimum 232. Long non-ASCII notes do not fit: each byte costs three characters.

## Command line (Node 22)

```
node deposit-qr.js --address ES...@HOST --note N [--minimum 0.1] [--label L] [--logo file.png|file.svg] [--out dir] [--name stem] [--size 1024]
```

Writes `<stem>.png` and `<stem>.svg` and prints the `epic:` string. A PNG logo must be 8-bit, not interlaced. An SVG logo goes into the SVG only.

## Web page

```html
<div id="deposit"></div>
<script src="deposit-qr.js"></script>
<script>
  DepositQr.depositPanel(document.getElementById('deposit'), {
    address: 'ES...@HOST', note: 'NOTE', minimum: '0.1', label: 'LABEL',
    logo: 'logo.svg', walletUrl: 'https://your-wallet-download-page'
  });
</script>
```

Also available: `depositUri(opts)` (`epic:`), `depositOpenLink(opts)` (`epiccash:`), `depositQrSvg(opts)`, `depositQrPng(opts)` (a Promise of a Blob). See `panel-demo.html` (serve the folder over http; it uses made-up values).

The panel shows the QR, an "Open with BT Wallet" link (a plain anchor, `epiccash:`), the `epic:` text in a read-only field with a Copy button (desktop Epic Wallet has no camera and reads a code by paste), and a hint. If the link opens nothing, a line appears saying so, with a link to `walletUrl` when you pass one. Texts are in one `STRINGS` object at the top of the file; pass `strings: {...}` to translate. Style through the `dq-` classes or the `--dq-accent` variables.

Notes:

- This QR must replace any address-only QR in that spot: only this one fills the note. A bare address scan is a normal send with no message.
- The address and note are made on your server for each deposit. Do not build them in the browser from user input.
- The panel writes inputs only with `textContent` and attributes, never `innerHTML`. A `walletUrl` that is not http or https is ignored.
