// Deposit QR generator for exchanges. No dependencies.
// Browser: <script src="deposit-qr.js"></script>, then DepositQr.depositQrSvg({...}).
// Node 22:  node deposit-qr.js --address A --note N [--minimum 0.1] [--label L]
//           [--logo file.png|file.svg] [--out dir] [--name stem] [--size 1024]
(function (root) {
  'use strict';

  var INK = '#211a11'; // Epic Wallet light theme text colour
  var PAPER = '#ffffff';
  var QUIET = 4; // quiet zone, in modules
  var KEY_RE = /^es[1-9A-HJ-NP-Za-km-z]{50}$/;
  var RELAY_RE = /^[a-z0-9.\-]+(:\d{1,5})?$/;
  var MINIMUM_RE = /^\d+(\.\d{1,8})?$/;
  var CONTROL_RE = /[\u0000-\u001f\u007f-\u009f]/;
  var LONE_SURROGATE_RE = /[\ud800-\udbff](?![\udc00-\udfff])|(?:[^\ud800-\udbff]|^)[\udc00-\udfff]/;
  var MAX_NOTE_BYTES = 256;
  var MAX_LABEL_CHARS = 64;

  // ---- URI ---------------------------------------------------------------

  function utf8(s) {
    return new TextEncoder().encode(s);
  }

  function pct(s) {
    var out = '';
    var bytes = utf8(s);
    for (var i = 0; i < bytes.length; i++) {
      var b = bytes[i];
      if ((b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) ||
          b === 45 || b === 46 || b === 95 || b === 126) {
        out += String.fromCharCode(b);
      } else {
        out += '%' + (b < 16 ? '0' : '') + b.toString(16).toUpperCase();
      }
    }
    return out;
  }

  // One payload, two schemes: `epic:` for the QR and the copy field, `epiccash:` for the open link
  // (the desktop builds register only `epiccash:`).
  function depositUri(o, scheme) {
    o = o || {};
    var address = typeof o.address === 'string' ? o.address.trim() : '';
    var at = address.indexOf('@');
    var key = at < 0 ? address : address.slice(0, at);
    var relay = at < 0 ? '' : address.slice(at + 1).toLowerCase();
    if (at < 0 || !KEY_RE.test(key) || !RELAY_RE.test(relay)) {
      throw new Error('address must be an Epicbox address: es<50 characters>@<relay host>[:port]');
    }
    var note = o.note;
    if (typeof note !== 'string' || note.trim() === '') throw new Error('note is required and must not be empty');
    if (CONTROL_RE.test(note) || LONE_SURROGATE_RE.test(note)) throw new Error('note must not contain control characters');
    if (utf8(note).length > MAX_NOTE_BYTES) {
      throw new Error('note is over ' + MAX_NOTE_BYTES + ' UTF-8 bytes; the wallet would not fill it');
    }
    var uri = (scheme || 'epic') + ':' + key + '@' + relay + '?message=' + pct(note) + '&require=message';
    if (o.minimum !== undefined && o.minimum !== null && o.minimum !== '') {
      var min = String(o.minimum).trim();
      if (!MINIMUM_RE.test(min) || !/[1-9]/.test(min)) {
        throw new Error('minimum must be a plain decimal above 0 with up to 8 decimals, like 0.1 (pass it as a string)');
      }
      uri += '&min=' + min;
    }
    if (typeof o.label === 'string' && o.label.trim() !== '') {
      if (CONTROL_RE.test(o.label) || LONE_SURROGATE_RE.test(o.label)) throw new Error('label must not contain control characters');
      if (Array.from(o.label).length > MAX_LABEL_CHARS) throw new Error('label is over ' + MAX_LABEL_CHARS + ' characters');
      uri += '&label=' + pct(o.label);
    }
    return uri;
  }

  function depositOpenLink(o) { return depositUri(o, 'epiccash'); }

  // ---- QR encoder: byte mode, level H, versions 1 to 20 -------------------

  // Per version: [EC codewords per block, blocks in group 1, data in group 1, blocks in group 2, data in group 2]
  var EC_H = [
    [17, 1, 9, 0, 0], [28, 1, 16, 0, 0], [22, 2, 13, 0, 0], [16, 4, 9, 0, 0],
    [22, 2, 11, 2, 12], [28, 4, 15, 0, 0], [26, 4, 13, 1, 14], [26, 4, 14, 2, 15],
    [24, 4, 12, 4, 13], [28, 6, 15, 2, 16], [24, 3, 12, 8, 13], [28, 7, 14, 4, 15],
    [22, 12, 11, 4, 12], [24, 11, 12, 5, 13], [24, 11, 12, 7, 13], [30, 3, 15, 13, 16],
    [28, 2, 14, 17, 15], [28, 2, 14, 19, 15], [26, 9, 13, 16, 14], [28, 15, 15, 10, 16]
  ];
  var ALIGN = [
    [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34], [6, 22, 38], [6, 24, 42], [6, 26, 46],
    [6, 28, 50], [6, 30, 54], [6, 32, 58], [6, 34, 62], [6, 26, 46, 66], [6, 26, 48, 70],
    [6, 26, 50, 74], [6, 30, 54, 78], [6, 30, 56, 82], [6, 30, 58, 86], [6, 34, 62, 90]
  ];

  var EXP = new Array(512);
  var LOG = new Array(256);
  (function () {
    var x = 1;
    for (var i = 0; i < 255; i++) {
      EXP[i] = x;
      LOG[x] = i;
      x <<= 1;
      if (x & 256) x ^= 0x11d;
    }
    for (var j = 255; j < 512; j++) EXP[j] = EXP[j - 255];
  })();

  function rsGenerator(n) {
    var g = [1];
    for (var i = 0; i < n; i++) {
      var next = new Array(g.length + 1).fill(0);
      for (var j = 0; j < g.length; j++) {
        next[j] ^= g[j];
        next[j + 1] ^= g[j] ? EXP[LOG[g[j]] + i] : 0;
      }
      g = next;
    }
    return g;
  }

  function rsRemainder(data, n) {
    var gen = rsGenerator(n);
    var rem = new Array(n).fill(0);
    for (var i = 0; i < data.length; i++) {
      var f = data[i] ^ rem.shift();
      rem.push(0);
      if (f) for (var j = 0; j < n; j++) rem[j] ^= EXP[LOG[gen[j + 1]] + LOG[f]];
    }
    return rem;
  }

  function dataCapacity(v) {
    var e = EC_H[v - 1];
    return e[1] * e[2] + e[3] * e[4];
  }

  function bchFormat(data) { // data: 5 bits
    var rem = data;
    for (var i = 0; i < 10; i++) rem = (rem << 1) ^ ((rem >>> 9) * 0x537);
    return ((data << 10) | rem) ^ 0x5412;
  }

  function bchVersion(v) {
    var rem = v;
    for (var i = 0; i < 12; i++) rem = (rem << 1) ^ ((rem >>> 11) * 0x1f25);
    return (v << 12) | rem;
  }

  function maskBit(m, r, c) {
    switch (m) {
      case 0: return (r + c) % 2 === 0;
      case 1: return r % 2 === 0;
      case 2: return c % 3 === 0;
      case 3: return (r + c) % 3 === 0;
      case 4: return (((r / 2) | 0) + ((c / 3) | 0)) % 2 === 0;
      case 5: return ((r * c) % 2) + ((r * c) % 3) === 0;
      case 6: return (((r * c) % 2) + ((r * c) % 3)) % 2 === 0;
      default: return (((r + c) % 2) + ((r * c) % 3)) % 2 === 0;
    }
  }

  function penalty(m, n) {
    var score = 0, r, c, i;
    for (var pass = 0; pass < 2; pass++) { // rows, then columns
      for (r = 0; r < n; r++) {
        var run = 1;
        var line = [];
        for (c = 0; c < n; c++) line.push(pass ? m[c][r] : m[r][c]);
        for (c = 1; c < n; c++) {
          if (line[c] === line[c - 1]) {
            run++;
            if (run === 5) score += 3;
            else if (run > 5) score++;
          } else run = 1;
        }
        // finder-like 1:1:3:1:1 with 4 light modules on a side
        for (c = 0; c + 11 <= n; c++) {
          var a = [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0];
          var b = [0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1];
          var ma = true, mb = true;
          for (i = 0; i < 11; i++) {
            var bit = line[c + i] ? 1 : 0;
            if (bit !== a[i]) ma = false;
            if (bit !== b[i]) mb = false;
          }
          if (ma) score += 40;
          if (mb) score += 40;
        }
      }
    }
    for (r = 0; r < n - 1; r++) {
      for (c = 0; c < n - 1; c++) {
        var v = m[r][c];
        if (v === m[r][c + 1] && v === m[r + 1][c] && v === m[r + 1][c + 1]) score += 3;
      }
    }
    var dark = 0;
    for (r = 0; r < n; r++) for (c = 0; c < n; c++) if (m[r][c]) dark++;
    score += 10 * Math.floor(Math.abs(Math.floor(dark * 100 / (n * n)) - 50) / 5);
    return score;
  }

  // Returns an array of rows of booleans (true = dark), without quiet zone.
  function qrMatrix(text) {
    var bytes = utf8(String(text));
    var ver = 0;
    for (var v = 1; v <= 20; v++) {
      var lenBits = v < 10 ? 8 : 16;
      if (4 + lenBits + bytes.length * 8 <= dataCapacity(v) * 8) { ver = v; break; }
    }
    if (!ver) {
      throw new Error('text is ' + bytes.length + ' bytes: too long for a level H code up to version 20 (limit 382 bytes); shorten the note or drop the label or minimum');
    }
    var ec = EC_H[ver - 1];
    var cap = dataCapacity(ver);

    // bit stream
    var bits = [];
    function put(val, len) { for (var i = len - 1; i >= 0; i--) bits.push((val >>> i) & 1); }
    put(4, 4);
    put(bytes.length, ver < 10 ? 8 : 16);
    for (var i = 0; i < bytes.length; i++) put(bytes[i], 8);
    put(0, Math.min(4, cap * 8 - bits.length));
    while (bits.length % 8) bits.push(0);
    var data = [];
    for (i = 0; i < bits.length; i += 8) {
      var byte = 0;
      for (var k = 0; k < 8; k++) byte = (byte << 1) | bits[i + k];
      data.push(byte);
    }
    for (var pad = 0xec; data.length < cap; pad ^= 0xec ^ 0x11) data.push(pad);

    // blocks
    var blocks = [], pos = 0;
    for (var g = 0; g < 2; g++) {
      for (var b = 0; b < ec[1 + g * 2]; b++) {
        var d = data.slice(pos, pos + ec[2 + g * 2]);
        pos += d.length;
        blocks.push({ d: d, e: rsRemainder(d, ec[0]) });
      }
    }
    var words = [];
    var maxD = ec[3] ? ec[4] : ec[2];
    for (i = 0; i < maxD; i++) blocks.forEach(function (bl) { if (i < bl.d.length) words.push(bl.d[i]); });
    for (i = 0; i < ec[0]; i++) blocks.forEach(function (bl) { words.push(bl.e[i]); });
    var stream = [];
    words.forEach(function (w) { put2(w); });
    function put2(w) { for (var j = 7; j >= 0; j--) stream.push((w >>> j) & 1); }

    // function patterns
    var n = ver * 4 + 17;
    var mod = [], fn = [];
    for (var r = 0; r < n; r++) { mod.push(new Array(n).fill(false)); fn.push(new Array(n).fill(false)); }
    function setf(r, c, dark) { mod[r][c] = dark; fn[r][c] = true; }
    function finder(r0, c0) {
      for (var dr = -1; dr <= 7; dr++) {
        for (var dc = -1; dc <= 7; dc++) {
          var rr = r0 + dr, cc = c0 + dc;
          if (rr < 0 || cc < 0 || rr >= n || cc >= n) continue;
          var inside = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
          var dark = inside && (dr === 0 || dr === 6 || dc === 0 || dc === 6 || (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4));
          setf(rr, cc, dark);
        }
      }
    }
    finder(0, 0); finder(0, n - 7); finder(n - 7, 0);
    for (i = 8; i < n - 8; i++) { setf(6, i, i % 2 === 0); setf(i, 6, i % 2 === 0); }
    var al = ALIGN[ver - 1];
    al.forEach(function (ar) {
      al.forEach(function (ac) {
        var last = al[al.length - 1];
        if ((ar === 6 && (ac === 6 || ac === last)) || (ar === last && ac === 6)) return; // overlaps a finder
        for (var dr = -2; dr <= 2; dr++) {
          for (var dc = -2; dc <= 2; dc++) {
            setf(ar + dr, ac + dc, Math.max(Math.abs(dr), Math.abs(dc)) !== 1);
          }
        }
      });
    });
    setf(n - 8, 8, true); // dark module
    for (i = 0; i < 9; i++) { // reserve format areas
      if (!fn[8][i]) setf(8, i, false);
      if (!fn[i][8]) setf(i, 8, false);
    }
    for (i = 0; i < 8; i++) { setf(8, n - 1 - i, false); setf(n - 1 - i, 8, false); }
    setf(n - 8, 8, true);
    if (ver >= 7) {
      var vi = bchVersion(ver);
      for (i = 0; i < 18; i++) {
        var bit = ((vi >>> i) & 1) === 1;
        var a = Math.floor(i / 3), b2 = i % 3 + n - 11;
        setf(a, b2, bit);
        setf(b2, a, bit);
      }
    }

    // place data, zigzag
    var idx = 0, up = true;
    var placeR = [], placeC = [];
    for (var col = n - 1; col > 0; col -= 2) {
      if (col === 6) col = 5;
      for (var t = 0; t < n; t++) {
        var rr = up ? n - 1 - t : t;
        for (var dx = 0; dx < 2; dx++) {
          var cc = col - dx;
          if (!fn[rr][cc]) { placeR.push(rr); placeC.push(cc); }
        }
      }
      up = !up;
    }
    var best = null, bestScore = Infinity, bestMask = 0;
    for (var mask = 0; mask < 8; mask++) {
      var m = mod.map(function (row) { return row.slice(); });
      for (idx = 0; idx < placeR.length; idx++) {
        var bitv = idx < stream.length ? stream[idx] === 1 : false;
        m[placeR[idx]][placeC[idx]] = bitv !== maskBit(mask, placeR[idx], placeC[idx]);
      }
      // format info, level H = 0b10
      var f = bchFormat((2 << 3) | mask);
      for (i = 0; i < 15; i++) {
        var fb = ((f >>> i) & 1) === 1;
        if (i < 6) m[i][8] = fb; else if (i < 7) m[7][8] = fb; else if (i < 8) m[8][8] = fb; else if (i < 9) m[8][7] = fb; else m[8][14 - i] = fb;
        if (i < 8) m[8][n - 1 - i] = fb; else m[n - 15 + i][8] = fb;
      }
      m[n - 8][8] = true;
      var s = penalty(m, n);
      if (s < bestScore) { bestScore = s; best = m; bestMask = mask; }
    }
    best.version = ver;
    best.mask = bestMask;
    return best;
  }

  // ---- shared geometry (Epic Wallet's smooth symbol, roundFactor 1) ---------

  var TILE = 0.2, TILE_RADIUS = 0.18, LOGO_IN_TILE = 0.58;

  function layout(n) {
    var total = n + QUIET * 2;
    var tile = TILE * n;
    var t0 = QUIET + (n - tile) / 2;
    return { n: n, total: total, tile: tile, t0: t0, radius: tile * TILE_RADIUS, logo: tile * LOGO_IN_TILE, l0: t0 + (tile - tile * LOGO_IN_TILE) / 2 };
  }

  function num(x) { return String(Math.round(x * 1000) / 1000); }

  // Path data for every dark module and every filled inner corner, one subpath each, all clockwise.
  function smoothPath(m) {
    var n = m.length;
    function on(r, c) { return r >= 0 && c >= 0 && r < n && c < n && m[r][c]; }
    var d = [];
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        var x = c + QUIET, y = r + QUIET;
        if (m[r][c]) {
          var t = on(r - 1, c), b = on(r + 1, c), l = on(r, c - 1), rt = on(r, c + 1);
          var any = t || b || l || rt;
          var tl = !any ? 0.25 : (t || l ? 0 : 0.5);
          var tr = !any ? 0.25 : (t || rt ? 0 : 0.5);
          var br = !any ? 0.25 : (b || rt ? 0 : 0.5);
          var bl = !any ? 0.25 : (b || l ? 0 : 0.5);
          var s = 'M' + num(x + tl) + ' ' + y + 'H' + num(x + 1 - tr);
          if (tr) s += 'A' + tr + ' ' + tr + ' 0 0 1 ' + (x + 1) + ' ' + num(y + tr);
          s += 'V' + num(y + 1 - br);
          if (br) s += 'A' + br + ' ' + br + ' 0 0 1 ' + num(x + 1 - br) + ' ' + (y + 1);
          s += 'H' + num(x + bl);
          if (bl) s += 'A' + bl + ' ' + bl + ' 0 0 1 ' + x + ' ' + num(y + 1 - bl);
          s += 'V' + num(y + tl);
          if (tl) s += 'A' + tl + ' ' + tl + ' 0 0 1 ' + num(x + tl) + ' ' + y;
          d.push(s + 'Z');
        } else {
          [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(function (q) {
            var dr = q[0], dc = q[1];
            if (!(on(r + dr, c) && on(r, c + dc) && on(r + dr, c + dc))) return;
            var cx = x + (dc < 0 ? 0 : 1), cy = y + (dr < 0 ? 0 : 1);
            var sx = dc < 0 ? 1 : -1, sy = dr < 0 ? 1 : -1;
            var px = cx + sx * 0.5, py = cy, qx = cx, qy = cy + sy * 0.5;
            // C -> along x -> curve (control C) -> along y -> C; flip order when mirrored once
            if (sx * sy > 0) d.push('M' + num(cx) + ' ' + num(cy) + 'L' + num(px) + ' ' + num(py) + 'Q' + num(cx) + ' ' + num(cy) + ' ' + num(qx) + ' ' + num(qy) + 'Z');
            else d.push('M' + num(cx) + ' ' + num(cy) + 'L' + num(qx) + ' ' + num(qy) + 'Q' + num(cx) + ' ' + num(cy) + ' ' + num(px) + ' ' + num(py) + 'Z');
          });
        }
      }
    }
    return d.join('');
  }

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function depositQrSvg(o) {
    var m = qrMatrix(depositUri(o));
    var L = layout(m.length);
    var size = o.size || 1024;
    var s = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 ' + L.total + ' ' + L.total +
      '" width="' + size + '" height="' + size + '" role="img" aria-label="Deposit QR code">' +
      '<rect width="' + L.total + '" height="' + L.total + '" fill="' + PAPER + '"/>' +
      '<path fill="' + INK + '" d="' + smoothPath(m) + '"/>';
    if (o.logo) {
      s += '<rect x="' + num(L.t0) + '" y="' + num(L.t0) + '" width="' + num(L.tile) + '" height="' + num(L.tile) +
        '" rx="' + num(L.radius) + '" fill="' + PAPER + '"/>' +
        '<image x="' + num(L.l0) + '" y="' + num(L.l0) + '" width="' + num(L.logo) + '" height="' + num(L.logo) +
        '" preserveAspectRatio="xMidYMid meet" href="' + esc(o.logo) + '" xlink:href="' + esc(o.logo) + '"/>';
    }
    return s + '</svg>';
  }

  function blobToDataUri(blob) {
    return new Promise(function (resolve, reject) {
      var fr = new FileReader();
      fr.onload = function () { resolve(fr.result); };
      fr.onerror = function () { reject(new Error('could not read the logo')); };
      fr.readAsDataURL(blob);
    });
  }

  // Browser only. An SVG drawn as an image never loads outside links, so a logo URL is inlined first.
  function depositQrPng(o) {
    var size = o.size || 1024;
    var logo = o.logo && !/^data:/i.test(o.logo)
      ? fetch(o.logo).then(function (r) { return r.blob(); }).then(blobToDataUri)
      : Promise.resolve(o.logo);
    return logo.then(function (logoUri) {
      var svg = depositQrSvg(Object.assign({}, o, { logo: logoUri, size: size }));
      var url = URL.createObjectURL(new Blob([svg], { type: 'image/svg+xml' }));
      return new Promise(function (resolve, reject) {
        var img = new Image();
        img.onload = function () {
          var canvas = document.createElement('canvas');
          canvas.width = canvas.height = size;
          var ctx = canvas.getContext('2d');
          ctx.fillStyle = PAPER;
          ctx.fillRect(0, 0, size, size);
          ctx.drawImage(img, 0, 0, size, size);
          URL.revokeObjectURL(url);
          canvas.toBlob(function (b) { b ? resolve(b) : reject(new Error('PNG export failed')); }, 'image/png');
        };
        img.onerror = function () { URL.revokeObjectURL(url); reject(new Error('could not draw the SVG')); };
        img.src = url;
      });
    });
  }


  // ---- Browser: a panel for the deposit page -----------------------------------

  var STRINGS = {
    open: 'Open with BT Wallet',
    fieldLabel: 'Deposit text',
    copy: 'Copy',
    copied: 'Copied',
    copyFailed: 'Copy failed, select the text and copy it',
    hint: 'No camera? Paste this text into the address field on Send in the wallet. It fills the note for you.',
    notOpened: 'No wallet opened. Copy the text above.',
    notOpenedGet: 'No wallet opened. Copy the text above, or get the wallet:',
    getWallet: 'Get the wallet',
    qrLabel: 'Deposit QR code'
  };

  var PANEL_CSS = '.dq-panel{box-sizing:border-box;max-width:22rem;width:100%;margin:0 auto;display:flex;flex-direction:column;gap:.75rem;color-scheme:light dark;font:inherit}' +
    '.dq-panel *{box-sizing:border-box}' +
    '.dq-qr{display:block;width:100%;max-width:20rem;margin:0 auto;border-radius:.75rem;overflow:hidden;background:#fff}' +
    '.dq-qr svg{display:block;width:100%;height:auto}' +
    '.dq-open{display:block;text-align:center;padding:.8rem 1rem;min-height:2.75rem;border-radius:.6rem;background:var(--dq-accent,light-dark(#211a11,#f3ece0));color:var(--dq-accent-text,light-dark(#fff,#211a11));text-decoration:none;font-weight:600;outline:2px solid transparent}' +
    '.dq-open:focus-visible,.dq-copy:focus-visible,.dq-field:focus-visible,.dq-get:focus-visible{outline:2px solid currentColor;outline-offset:2px}' +
    '.dq-open:hover{filter:brightness(1.15)}' +
    '.dq-row{display:flex;gap:.5rem;align-items:stretch}' +
    '.dq-field{flex:1 1 auto;min-width:0;padding:.6rem .7rem;font:.8rem/1.3 ui-monospace,Menlo,Consolas,monospace;color:CanvasText;background:Canvas;border:1px solid color-mix(in srgb,CanvasText 40%,transparent);border-radius:.5rem}' +
    '.dq-copy{flex:0 0 auto;min-width:5.5rem;min-height:2.75rem;padding:0 .9rem;font:inherit;font-weight:600;color:CanvasText;background:Canvas;border:1px solid color-mix(in srgb,CanvasText 40%,transparent);border-radius:.5rem;cursor:pointer}' +
    '.dq-hint,.dq-fallback,.dq-status{margin:0;font-size:.875rem;line-height:1.4}' +
    '.dq-status{min-height:1.2em;opacity:.85}' +
    '.dq-fallback a{color:inherit;text-decoration:underline}';

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  // Renders the QR, an open link, the same text in a copy field and a not-installed hint into `container`.
  // Inputs reach the page only through textContent, attributes and a parsed SVG, never innerHTML.
  function depositPanel(container, o) {
    var t = Object.assign({}, STRINGS, o.strings || {});
    var uri = depositUri(o);
    var svg = depositQrSvg(o);
    if (!document.getElementById('dq-style')) {
      var st = el('style');
      st.id = 'dq-style';
      st.textContent = PANEL_CSS;
      document.head.appendChild(st);
    }
    var panel = el('div', 'dq-panel');
    var qr = el('div', 'dq-qr');
    var doc = new DOMParser().parseFromString(svg, 'image/svg+xml');
    qr.appendChild(document.importNode(doc.documentElement, true));
    qr.firstChild.setAttribute('aria-label', t.qrLabel);

    var open = el('a', 'dq-open', t.open);
    open.href = depositOpenLink(o);

    var id = 'dq-field-' + Math.random().toString(36).slice(2, 8);
    var label = el('label', 'dq-hint', t.fieldLabel);
    label.htmlFor = id;
    var field = el('input', 'dq-field');
    field.id = id; field.type = 'text'; field.readOnly = true; field.value = uri;
    field.setAttribute('spellcheck', 'false'); field.setAttribute('autocomplete', 'off');
    field.addEventListener('focus', function () { field.select(); });
    var copy = el('button', 'dq-copy', t.copy);
    copy.type = 'button';
    var row = el('div', 'dq-row');
    row.appendChild(field); row.appendChild(copy);
    var status = el('p', 'dq-status');
    status.setAttribute('role', 'status');
    status.setAttribute('aria-live', 'polite');
    var hint = el('p', 'dq-hint', t.hint);

    var fallback = el('p', 'dq-fallback');
    fallback.hidden = true;
    var walletUrl = typeof o.walletUrl === 'string' && /^https?:\/\//i.test(o.walletUrl) ? o.walletUrl : '';
    fallback.appendChild(document.createTextNode(walletUrl ? t.notOpenedGet + ' ' : t.notOpened));
    if (walletUrl) {
      var get = el('a', 'dq-get', t.getWallet);
      get.href = walletUrl; get.rel = 'noopener';
      fallback.appendChild(get);
    }

    var resetTimer = null;
    function flash(text, ms) {
      status.textContent = text;
      copy.textContent = text === t.copied ? t.copied : t.copy;
      clearTimeout(resetTimer);
      resetTimer = setTimeout(function () { status.textContent = ''; copy.textContent = t.copy; }, ms);
    }
    function fallbackCopy() {
      field.focus(); field.select();
      var done = false;
      try { done = document.execCommand('copy'); } catch (e) { done = false; }
      flash(done ? t.copied : t.copyFailed, done ? 2000 : 5000);
    }
    copy.addEventListener('click', function () {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(uri).then(function () { flash(t.copied, 2000); }, fallbackCopy);
      } else fallbackCopy();
    });

    // If the page keeps focus after the click, no app took over.
    open.addEventListener('click', function () {
      var timer = setTimeout(function () { stop(); fallback.hidden = false; }, 1500);
      function stop() {
        clearTimeout(timer);
        window.removeEventListener('blur', stop);
        window.removeEventListener('pagehide', stop);
        document.removeEventListener('visibilitychange', stop);
      }
      window.addEventListener('blur', stop);
      window.addEventListener('pagehide', stop);
      document.addEventListener('visibilitychange', stop);
    });

    [qr, open, label, row, status, hint, fallback].forEach(function (n) { panel.appendChild(n); });
    container.textContent = '';
    container.appendChild(panel);
    return { uri: uri, svg: svg };
  }

  var api = { depositUri: depositUri, qrMatrix: qrMatrix, depositQrSvg: depositQrSvg, depositQrPng: depositQrPng, depositPanel: depositPanel, depositOpenLink: depositOpenLink };

  // ---- Node: PNG writer, PNG logo reader, CLI ---------------------------------

  var isNode = typeof module !== 'undefined' && module.exports && typeof require === 'function';
  if (!isNode) {
    root.DepositQr = api;
    return;
  }
  module.exports = api;

  var zlib = require('node:zlib');
  var fs = require('node:fs');
  var path = require('node:path');

  var CRC = new Uint32Array(256);
  for (var ci = 0; ci < 256; ci++) {
    var cv = ci;
    for (var ck = 0; ck < 8; ck++) cv = cv & 1 ? 0xedb88320 ^ (cv >>> 1) : cv >>> 1;
    CRC[ci] = cv >>> 0;
  }
  function crc32(buf) {
    var c = 0xffffffff;
    for (var i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 255] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  }
  function chunk(type, data) {
    var out = Buffer.alloc(12 + data.length);
    out.writeUInt32BE(data.length, 0);
    out.write(type, 4, 'latin1');
    data.copy(out, 8);
    out.writeUInt32BE(crc32(out.subarray(4, 8 + data.length)), 8 + data.length);
    return out;
  }
  function encodePng(w, h, rgb) {
    var raw = Buffer.alloc((w * 3 + 1) * h);
    for (var y = 0; y < h; y++) rgb.copy(raw, y * (w * 3 + 1) + 1, y * w * 3, (y + 1) * w * 3);
    var ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
    ihdr[8] = 8; ihdr[9] = 2;
    return Buffer.concat([
      Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
      chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))
    ]);
  }

  // Returns {w, h, px: Float32Array RGBA premultiplied, 0..1}
  function decodePng(buf) {
    var refuse = 'the PNG logo must be 8-bit grey, grey+alpha, RGB, RGBA or palette, and not interlaced';
    if (buf.length < 33 || buf.readUInt32BE(0) !== 0x89504e47) throw new Error('logo is not a PNG file');
    var pos = 8, w = 0, h = 0, depth = 0, type = 0, inter = 0, plte = null, trns = null, idat = [];
    while (pos + 8 <= buf.length) {
      var len = buf.readUInt32BE(pos), name = buf.toString('latin1', pos + 4, pos + 8);
      var body = buf.subarray(pos + 8, pos + 8 + len);
      if (name === 'IHDR') { w = body.readUInt32BE(0); h = body.readUInt32BE(4); depth = body[8]; type = body[9]; inter = body[12]; }
      else if (name === 'PLTE') plte = body;
      else if (name === 'tRNS') trns = body;
      else if (name === 'IDAT') idat.push(body);
      else if (name === 'IEND') break;
      pos += 12 + len;
    }
    if (depth !== 8 || inter !== 0 || [0, 2, 3, 4, 6].indexOf(type) < 0) throw new Error(refuse);
    if (type === 3 && !plte) throw new Error('logo PNG has no palette');
    var bpp = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[type];
    var raw = zlib.inflateSync(Buffer.concat(idat));
    var stride = w * bpp, cur = Buffer.alloc(stride), prev = Buffer.alloc(stride);
    var px = new Float32Array(w * h * 4);
    for (var y = 0; y < h; y++) {
      var ft = raw[y * (stride + 1)];
      var src = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
      for (var x = 0; x < stride; x++) {
        var a = x >= bpp ? cur[x - bpp] : 0, b = prev[x], c = x >= bpp ? prev[x - bpp] : 0, v = src[x];
        if (ft === 1) v += a;
        else if (ft === 2) v += b;
        else if (ft === 3) v += (a + b) >> 1;
        else if (ft === 4) {
          var p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
          v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
        } else if (ft !== 0) throw new Error('logo PNG is corrupt');
        cur[x] = v & 255;
      }
      for (x = 0; x < w; x++) {
        var o = (y * w + x) * 4, r, g, bl, al = 255;
        if (type === 0) { r = g = bl = cur[x]; if (trns && trns.length >= 2 && cur[x] === trns[1]) al = 0; }
        else if (type === 4) { r = g = bl = cur[x * 2]; al = cur[x * 2 + 1]; }
        else if (type === 2) { r = cur[x * 3]; g = cur[x * 3 + 1]; bl = cur[x * 3 + 2]; }
        else if (type === 6) { r = cur[x * 4]; g = cur[x * 4 + 1]; bl = cur[x * 4 + 2]; al = cur[x * 4 + 3]; }
        else { var pi = cur[x]; r = plte[pi * 3]; g = plte[pi * 3 + 1]; bl = plte[pi * 3 + 2]; if (trns && pi < trns.length) al = trns[pi]; }
        var af = al / 255;
        px[o] = r / 255 * af; px[o + 1] = g / 255 * af; px[o + 2] = bl / 255 * af; px[o + 3] = af;
      }
      var t = prev; prev = cur; cur = t;
    }
    return { w: w, h: h, px: px };
  }

  // Premultiplied RGBA of the logo scaled to fit a box of side `box` px; box average when shrinking, bilinear when enlarging.
  function scaleLogo(img, box) {
    var s = Math.min(box / img.w, box / img.h);
    var dw = Math.max(1, Math.round(img.w * s)), dh = Math.max(1, Math.round(img.h * s));
    var out = new Float32Array(dw * dh * 4);
    for (var y = 0; y < dh; y++) {
      for (var x = 0; x < dw; x++) {
        var o = (y * dw + x) * 4, k;
        if (s < 1) {
          var x0 = x / s, x1 = (x + 1) / s, y0 = y / s, y1 = (y + 1) / s, acc = [0, 0, 0, 0], wt = 0;
          for (var sy = Math.floor(y0); sy < Math.ceil(y1) && sy < img.h; sy++) {
            var wy = Math.min(sy + 1, y1) - Math.max(sy, y0);
            for (var sx = Math.floor(x0); sx < Math.ceil(x1) && sx < img.w; sx++) {
              var wgt = wy * (Math.min(sx + 1, x1) - Math.max(sx, x0));
              for (k = 0; k < 4; k++) acc[k] += img.px[(sy * img.w + sx) * 4 + k] * wgt;
              wt += wgt;
            }
          }
          for (k = 0; k < 4; k++) out[o + k] = acc[k] / wt;
        } else {
          var fx = Math.min(img.w - 1, Math.max(0, (x + 0.5) / s - 0.5)), fy = Math.min(img.h - 1, Math.max(0, (y + 0.5) / s - 0.5));
          var ix = Math.floor(fx), iy = Math.floor(fy), jx = Math.min(img.w - 1, ix + 1), jy = Math.min(img.h - 1, iy + 1);
          var ax = fx - ix, ay = fy - iy;
          for (k = 0; k < 4; k++) {
            out[o + k] = (img.px[(iy * img.w + ix) * 4 + k] * (1 - ax) + img.px[(iy * img.w + jx) * 4 + k] * ax) * (1 - ay) +
              (img.px[(jy * img.w + ix) * 4 + k] * (1 - ax) + img.px[(jy * img.w + jx) * 4 + k] * ax) * ay;
          }
        }
      }
    }
    return { w: dw, h: dh, px: out };
  }

  // Is the point (u, v), in module units inside one module's local square [0,1)^2, covered by ink?
  function inkAt(m, n, r, c, u, v) {
    if (!m[r][c]) {
      // filled inner corners of a light module: sqrt(2x) + sqrt(2y) <= 1 from the corner
      var cr = v < 0.5 ? -1 : 1, cc = u < 0.5 ? -1 : 1;
      var nr = r + cr, nc = c + cc;
      if (nr < 0 || nc < 0 || nr >= n || nc >= n) return false;
      if (!(m[nr][c] && m[r][nc] && m[nr][nc])) return false;
      var x = u < 0.5 ? u : 1 - u, y = v < 0.5 ? v : 1 - v;
      return Math.sqrt(2 * x) + Math.sqrt(2 * y) <= 1;
    }
    var t = r > 0 && m[r - 1][c], b = r < n - 1 && m[r + 1][c], l = c > 0 && m[r][c - 1], rt = c < n - 1 && m[r][c + 1];
    var any = t || b || l || rt;
    var rad = any ? 0.5 : 0.25;
    var left = u < 0.5, top = v < 0.5;
    var zero = any && (top ? t : b) || any && (left ? l : rt);
    if (zero) return true;
    var dx = (left ? rad : 1 - rad) - u, dy = (top ? rad : 1 - rad) - v;
    if ((left ? dx > 0 : dx < 0) && (top ? dy > 0 : dy < 0)) return dx * dx + dy * dy <= rad * rad;
    return true;
  }

  function renderPng(o, logoImg) {
    var m = qrMatrix(depositUri(o));
    var n = m.length, L = layout(n);
    var size = o.size || 1024, SS = 4;
    var ppm = size / L.total; // pixels per module
    var tile = null;
    if (logoImg) tile = scaleLogo(logoImg, Math.round(L.logo * ppm));
    var rgb = Buffer.alloc(size * size * 3);
    var inkRgb = [0x21, 0x1a, 0x11];
    var rad = L.radius;
    function inTile(X, Y) { // module units
      if (X < L.t0 || Y < L.t0 || X >= L.t0 + L.tile || Y >= L.t0 + L.tile) return false;
      var cx = X < L.t0 + rad ? L.t0 + rad : X > L.t0 + L.tile - rad ? L.t0 + L.tile - rad : X;
      var cy = Y < L.t0 + rad ? L.t0 + rad : Y > L.t0 + L.tile - rad ? L.t0 + L.tile - rad : Y;
      return (X - cx) * (X - cx) + (Y - cy) * (Y - cy) <= rad * rad;
    }
    var lx0 = tile ? Math.round((L.l0 + (L.logo - tile.w / ppm) / 2) * ppm) : 0;
    var ly0 = tile ? Math.round((L.l0 + (L.logo - tile.h / ppm) / 2) * ppm) : 0;
    for (var py = 0; py < size; py++) {
      for (var px = 0; px < size; px++) {
        var hit = 0;
        for (var sy = 0; sy < SS; sy++) {
          for (var sx = 0; sx < SS; sx++) {
            var X = (px + (sx + 0.5) / SS) / ppm - QUIET, Y = (py + (sy + 0.5) / SS) / ppm - QUIET;
            if (X < 0 || Y < 0 || X >= n || Y >= n) continue;
            if (logoImg && inTile(X + QUIET, Y + QUIET)) continue;
            var c = Math.floor(X), r = Math.floor(Y);
            if (inkAt(m, n, r, c, X - c, Y - r)) hit++;
          }
        }
        var cov = hit / (SS * SS);
        var R = 255 + (inkRgb[0] - 255) * cov, G = 255 + (inkRgb[1] - 255) * cov, B = 255 + (inkRgb[2] - 255) * cov;
        if (tile && px >= lx0 && py >= ly0 && px < lx0 + tile.w && py < ly0 + tile.h) {
          var lo = ((py - ly0) * tile.w + (px - lx0)) * 4, al = tile.px[lo + 3];
          R = tile.px[lo] * 255 + R * (1 - al); G = tile.px[lo + 1] * 255 + G * (1 - al); B = tile.px[lo + 2] * 255 + B * (1 - al);
        }
        var oi = (py * size + px) * 3;
        rgb[oi] = Math.round(R); rgb[oi + 1] = Math.round(G); rgb[oi + 2] = Math.round(B);
      }
    }
    return encodePng(size, size, rgb);
  }

  function cli(argv) {
    var opt = { out: '.', name: 'deposit', size: 1024 };
    var flags = { '--address': 'address', '--note': 'note', '--minimum': 'minimum', '--label': 'label', '--logo': 'logo', '--out': 'out', '--name': 'name', '--size': 'size' };
    for (var i = 0; i < argv.length; i++) {
      var key = flags[argv[i]];
      if (!key || i + 1 >= argv.length) {
        throw new Error('usage: node deposit-qr.js --address A --note N [--minimum 0.1] [--label L] [--logo file.png|file.svg] [--out dir] [--name stem] [--size 1024]');
      }
      opt[key] = argv[++i];
    }
    opt.size = Number(opt.size);
    if (!(opt.size >= 128 && opt.size <= 8192) || opt.size !== Math.floor(opt.size)) throw new Error('size must be a whole number from 128 to 8192');
    var uri = depositUri(opt); // validates first
    qrMatrix(uri);
    var logoFile = opt.logo, svgLogo = false, logoImg = null, dataUri = null;
    if (logoFile) {
      var bytes = fs.readFileSync(logoFile);
      svgLogo = /\.svg$/i.test(logoFile);
      dataUri = 'data:' + (svgLogo ? 'image/svg+xml' : 'image/png') + ';base64,' + bytes.toString('base64');
      if (!svgLogo) logoImg = decodePng(bytes);
    }
    fs.mkdirSync(opt.out, { recursive: true });
    var stem = path.join(opt.out, opt.name);
    fs.writeFileSync(stem + '.svg', depositQrSvg({ address: opt.address, note: opt.note, minimum: opt.minimum, label: opt.label, logo: dataUri, size: opt.size }));
    if (svgLogo) {
      process.stderr.write('note: the PNG needs a PNG logo (an SVG logo is not drawn in a PNG), so only ' + stem + '.svg was written\n');
    } else {
      fs.writeFileSync(stem + '.png', renderPng(opt, logoImg));
    }
    process.stdout.write(uri + '\n');
  }

  if (require.main === module) {
    try {
      cli(process.argv.slice(2));
    } catch (e) {
      process.stderr.write('error: ' + e.message + '\n');
      process.exit(1);
    }
  }
})(typeof globalThis !== 'undefined' ? globalThis : this);
