// BT Wallet releases page: the Look picker, copy buttons for checksums and commands, and the
// platform the browser reports: the hero's big button downloads its primary file, its row in the
// list is marked This device; the All platforms pills and a #dl-/#before- link show another
// platform in the hero, in place. All of it is a nicety: without this file every download is still a link, every
// fold a <details>, and the hero's button leads to the platform list.
// Nothing is fetched, nothing is tracked. The changelog shares the picker.
(function () {
  'use strict';
  var root = document.documentElement;
  var KEY = 'btw-look'; // the landing page's key (epiccash.btlabs.uk/look/pick.js)

  // ---- the Look picker ---------------------------------------------------------------
  // The landing page's three quiet text buttons at the end of the footer. Here they switch the
  // look in place (the page is one document in three looks) and save it for the landing page too.
  var LOOKS = [['a', 'Night', '#08080a'], ['b', 'Grid', '#0a0b0d'], ['c', 'Day', '#fbf6ec']];
  var foot = document.querySelector('footer');
  if (foot) {
    var nav = document.createElement('nav');
    nav.className = 'look-pick';
    nav.setAttribute('aria-label', 'Page look');
    var label = document.createElement('span');
    label.textContent = 'Look';
    nav.appendChild(label);
    var lookBtns = LOOKS.map(function (l) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = l[1];
      b.setAttribute('aria-pressed', String(root.getAttribute('data-look') === l[0]));
      b.addEventListener('click', function () {
        root.setAttribute('data-look', l[0]);
        try { localStorage.setItem(KEY, l[0]); } catch (e) { /* private window: lasts the page view */ }
        var tc = document.querySelector('meta[name=theme-color]');
        if (tc) tc.setAttribute('content', l[2]);
        lookBtns.forEach(function (o, i) { o.setAttribute('aria-pressed', String(LOOKS[i][0] === l[0])); });
      });
      nav.appendChild(b);
      return b;
    });
    foot.appendChild(nav);
  }

  // ---- copy buttons ------------------------------------------------------------------
  if (navigator.clipboard && window.isSecureContext) {
    var codes = document.querySelectorAll('code[data-copy]');
    for (var c = 0; c < codes.length; c++) {
      (function (code) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'copy';
        // data-copy names what is copied: "SHA-256", "fingerprint" or "command".
        var what = code.getAttribute('data-copy') || 'command';
        var text = what === 'command' ? 'Copy command' : what === 'SHA-256' ? 'Copy SHA-256' : 'Copy ' + what;
        b.textContent = text;
        b.setAttribute('aria-label', text);
        b.addEventListener('click', function () {
          navigator.clipboard.writeText(code.textContent.trim()).then(function () {
            b.textContent = 'Copied';
            b.setAttribute('data-done', '');
            setTimeout(function () { b.textContent = text; b.removeAttribute('data-done'); }, 1600);
          }, function () { b.textContent = 'Select it'; });
        });
        code.parentNode.insertBefore(b, code.nextSibling);
      })(codes[c]);
    }
  }

  // ---- the browser's platform --------------------------------------------------------
  // User-Agent Client Hints first (Chromium; Windows, macOS, Linux, Android, Chrome OS by
  // name), then the user agent. iPadOS 13+ reports itself as a Mac: touch points tell.
  function platform() {
    var p = '';
    try {
      var d = navigator.userAgentData;
      if (d && d.platform) p = String(d.platform).toLowerCase();
    } catch (e) {}
    var ua = (navigator.userAgent || '').toLowerCase();
    var touch = navigator.maxTouchPoints > 1;
    if (!p) {
      if (/iphone|ipad|ipod/.test(ua)) return 'ios';
      if (/android/.test(ua)) return 'android';
      if (/cros/.test(ua)) return '';
      if (/windows/.test(ua)) return 'windows';
      if (/mac os x|macintosh/.test(ua)) return touch ? 'ios' : 'macos';
      if (/linux|x11/.test(ua)) return 'linux';
      return '';
    }
    if (p === 'windows') return 'windows';
    if (p === 'android') return 'android';
    if (p === 'ios' || p === 'iphone' || p === 'ipad') return 'ios';
    if (p === 'macos') return touch ? 'ios' : 'macos';
    if (p === 'linux') return 'linux';
    return ''; // Chrome OS, unknown: the neutral layout
  }

  var $ = function (id) { return document.getElementById(id); };
  var dl = $('hero-dl');
  if (!dl) return;
  var chips = document.querySelectorAll('.also a[data-pick]');
  // The page's own version and date, for a platform whose row carries none.
  var pageVer = $('hero-ver').textContent, pageDate = $('hero-date').getAttribute('datetime'),
      pageWhen = $('hero-date').textContent;

  // The browser's own platform: its row is marked This device, once, whatever is shown later.
  var mine = platform();
  var mineRow = mine && $('dl-' + mine);
  if (mineRow && mineRow.querySelector('.r-get .btn.primary')) {
    mineRow.classList.add('is-mine');
    var tag = document.createElement('span');
    tag.className = 'mine-tag';
    tag.textContent = 'This device';
    mineRow.querySelector('h3').appendChild(tag);
  } else {
    mine = '';
  }

  // The hero for one platform: the big button downloads its primary file, the line under it
  // has its requirement, version and date, the links its Install guide and its build without
  // Tor. Callable any number of times: whatever the previous platform set is set again or reset.
  var before = null;
  function show(key) {
    var row = key && $('dl-' + key);
    var btn = row && row.querySelector('.r-get .btn.primary');
    if (!btn) return false;
    var name = row.querySelector('h3').firstChild.textContent.trim();
    var preview = row.hasAttribute('data-preview');
    dl.href = btn.getAttribute('href');
    dl.setAttribute('download', '');
    $('hero-dl-text').textContent = 'Download for ' + name;
    $('hero-dl-sub').textContent = btn.getAttribute('data-label') + ' · ' + btn.getAttribute('data-size').replace(' ', ' ') + (preview ? ' · Preview' : '');
    var ico = row.querySelector('.ico svg');
    if (ico) { $('hero-dl-ico').textContent = ''; $('hero-dl-ico').appendChild(ico.cloneNode(true)); }
    $('hero-req').textContent = row.querySelector('.req').textContent + ' · ';
    var own = row.hasAttribute('data-version');
    $('hero-ver').textContent = own ? row.getAttribute('data-version') : pageVer;
    $('hero-date').setAttribute('datetime', own ? row.getAttribute('data-date') : pageDate);
    $('hero-date').textContent = own ? row.getAttribute('data-when') : pageWhen;

    $('hero-alt').hidden = false;
    before = $('before-' + key);
    $('hero-before').hidden = !before;
    $('hero-before').href = before ? '#before-' + key : '#latest';
    var notor = row.querySelector('.r-get .alt');
    $('hero-notor').hidden = !notor;
    $('hero-notor').href = notor ? notor.getAttribute('href') : '#latest';

    for (var i = 0; i < chips.length; i++) {
      if (chips[i].getAttribute('data-pick') === key) chips[i].setAttribute('aria-current', 'true');
      else chips[i].removeAttribute('aria-current');
    }
    return true;
  }
  $('hero-before').addEventListener('click', function () { if (before) before.open = true; });

  // A link to #dl-<key> or #before-<key> names the platform the visitor wants; #before- also
  // opens its fold. Read at load and on every hash change (the landing page's links, back and
  // forward).
  function fromHash() {
    var m = /^#(dl|before)-([a-z]+)$/.exec(location.hash || '');
    if (!m || !show(m[2])) return false;
    if (m[1] === 'before' && before) before.open = true;
    return true;
  }
  if (!fromHash()) show(mine);
  window.addEventListener('hashchange', fromHash);

  // The All platforms pills switch the hero in place: no scroll, the URL names the platform.
  for (var p = 0; p < chips.length; p++) {
    chips[p].addEventListener('click', function (e) {
      var key = this.getAttribute('data-pick');
      if (!show(key)) return; // no download for it: the plain link
      e.preventDefault();
      try { history.replaceState(null, '', '#dl-' + key); } catch (err) { /* file: or a sandbox */ }
    });
  }
})();
