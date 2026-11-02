// BT Wallet releases page: the Look picker, copy buttons for checksums and commands, and the
// platform the browser reports: the hero's big button downloads its primary file, its row in the
// list is marked. All of it is a nicety: without this file every download is still a link, every
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
        b.textContent = 'Copy';
        b.setAttribute('aria-label', 'Copy ' + (code.closest('.verify') ? 'the command' : 'the checksum'));
        b.addEventListener('click', function () {
          navigator.clipboard.writeText(code.textContent.trim()).then(function () {
            b.textContent = 'Copied';
            b.setAttribute('data-done', '');
            setTimeout(function () { b.textContent = 'Copy'; b.removeAttribute('data-done'); }, 1600);
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
  var key = platform();
  // a link to #dl-<key> or #before-<key> names the platform the visitor wants
  var m = /^#(?:dl|before)-([a-z]+)$/.exec(location.hash || '');
  if (m && $('dl-' + m[1])) key = m[1];
  var row = key && $('dl-' + key);
  var btn = row && row.querySelector('.r-get .btn.primary');
  if (!btn) return;

  var name = row.querySelector('h3').firstChild.textContent.trim();
  var preview = row.hasAttribute('data-preview');
  row.classList.add('is-mine');
  var tag = document.createElement('span');
  tag.className = 'mine-tag';
  tag.textContent = 'This device';
  row.querySelector('h3').appendChild(tag);
  var chip = document.querySelector('.also a[data-pick="' + key + '"]');
  if (chip) chip.setAttribute('aria-current', 'true');

  var dl = $('hero-dl');
  dl.href = btn.getAttribute('href');
  dl.setAttribute('download', '');
  $('hero-dl-text').textContent = 'Download for ' + name;
  $('hero-dl-sub').textContent = btn.getAttribute('data-label') + ' · ' + btn.getAttribute('data-size').replace(' ', ' ') + (preview ? ' · Preview' : '');
  var ico = row.querySelector('.ico svg');
  if (ico) { $('hero-dl-ico').textContent = ''; $('hero-dl-ico').appendChild(ico.cloneNode(true)); }
  $('hero-req').textContent = row.querySelector('.req').textContent + ' · ';

  var alt = $('hero-alt');
  alt.hidden = false;
  var before = $('before-' + key);
  if (before) {
    $('hero-before').href = '#before-' + key;
    $('hero-before').addEventListener('click', function () { before.open = true; });
  } else {
    $('hero-before').hidden = true;
  }
  var notor = row.querySelector('.r-get .alt');
  if (notor) {
    $('hero-notor').href = notor.getAttribute('href');
    $('hero-notor').hidden = false;
  }
  // a Before you install link (#before-<key>) opens its fold
  if (m && location.hash.indexOf('#before-') === 0 && before) before.open = true;
})();
