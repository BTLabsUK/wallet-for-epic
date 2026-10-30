// Epic Cash releases page: the theme toggle, copy buttons for checksums and commands, and the
// platform the browser reports (the hero's button and its card first; a tile or the section's switch
// picks another in place, nothing scrolls). All of
// it is a nicety: without this file every download is still a link and every fold a <details>.
// Nothing is fetched, nothing is tracked. The changelog and restore pages share the toggle.
(function () {
  'use strict';
  var root = document.documentElement;
  var KEY = 'epic-cash-theme';

  // ---- theme -------------------------------------------------------------------------
  function theme() { return root.getAttribute('data-theme') === 'light' ? 'light' : 'dark'; }
  function setTheme(t) {
    if (t === 'light') root.setAttribute('data-theme', 'light'); else root.removeAttribute('data-theme');
    try { localStorage.setItem(KEY, t); } catch (e) { /* private window: lasts the page view */ }
    var tc = document.querySelector('meta[name=theme-color]');
    if (tc) tc.setAttribute('content', t === 'light' ? '#f7f7f8' : '#08080a');
    var b = document.getElementById('theme');
    if (b) b.setAttribute('aria-label', t === 'light' ? 'Switch to the dark look' : 'Switch to the light look');
    syncDiagrams();
  }
  function syncDiagrams() { // the restore page's dark/light SVGs
    var dark = theme() === 'dark';
    var links = document.querySelectorAll('figure.diagram a[data-light]');
    for (var i = 0; i < links.length; i++) {
      var a = links[i], src = a.getAttribute(dark ? 'data-dark' : 'data-light');
      a.href = src;
      var img = a.querySelector('img');
      if (img && img.getAttribute('src') !== src) img.src = src;
    }
  }
  var tb = document.getElementById('theme');
  if (tb) {
    tb.addEventListener('click', function () { setTheme(theme() === 'light' ? 'dark' : 'light'); });
    setTheme(theme());
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
  var heroDl = $('hero-dl'), heroText = $('hero-dl-text'), heroSub = $('hero-dl-sub'), heroIco = $('hero-dl-ico');
  var heroBefore = $('hero-before');
  var availMine = $('avail-mine'), availRest = $('avail-rest'), availBack = $('avail-back');
  var cards = document.querySelectorAll('.card[data-plat]');
  var tiles = document.querySelectorAll('.tile[data-pick]');
  var picks = document.querySelectorAll('[data-pick]'); // the hero's tiles and the section's switch
  var detected = platform(), detectedName = '', current = '';

  function nameOf(card) { return card.querySelector('h3').firstChild.textContent.trim(); }
  function join(a) { return a.length < 2 ? a.join('') : a.slice(0, -1).join(', ') + ' and ' + a[a.length - 1]; }
  // "Windows and Android; macOS and iOS preview": every platform but key
  function rest(key) {
    var norm = [], prev = [];
    for (var i = 0; i < tiles.length; i++) {
      var t = tiles[i];
      if (t.getAttribute('data-pick') === key) continue;
      (t.querySelector('.t-note') ? prev : norm).push(t.querySelector('.t-name').textContent);
    }
    var s = join(norm);
    if (prev.length) s += (s ? '; ' : '') + join(prev) + ' preview';
    return s;
  }

  // One state for the whole page: the hero's button downloads key's primary file, Before you
  // install leads to key's fold (open), key's card goes first and wide, key is marked on the
  // tiles and on the section's switch. Nothing scrolls: the page stays where the visitor is.
  function pick(key) {
    var card = key && document.getElementById('dl-' + key);
    if (!card || key === current) return;
    current = key;
    for (var i = 0; i < cards.length; i++) cards[i].classList.toggle('is-mine', cards[i] === card);
    var before = document.querySelectorAll('details[data-before]');
    for (var j = 0; j < before.length; j++) before[j].open = before[j].getAttribute('data-before') === key;
    for (var k = 0; k < picks.length; k++) {
      var on = picks[k].getAttribute('data-pick') === key;
      picks[k].classList.toggle('is-mine', on);
      if (on) picks[k].setAttribute('aria-current', 'true'); else picks[k].removeAttribute('aria-current');
    }
    root.setAttribute('data-plat', key);
    var name = nameOf(card), app = card.querySelector('.app').textContent;
    var btn = card.querySelector('.btn.primary');
    if (heroDl && btn) {
      heroDl.href = btn.getAttribute('href');
      heroDl.setAttribute('download', '');
      heroText.textContent = 'Download for ' + name;
      var parts = btn.querySelector('small').textContent.split(' · ');
      heroSub.textContent = app + ' · ' + parts[0] + ' · ' + parts[1] + (card.querySelector('h3 .pill') ? ' · Preview' : '');
      var ico = card.querySelector('.ico svg');
      if (ico && heroIco) { heroIco.textContent = ''; heroIco.appendChild(ico.cloneNode(true)); }
    }
    if (heroBefore) heroBefore.href = '#before-' + key;
    // the line under the buttons keeps its text and size: the Back link only hides, so the
    // tiles below never move (no wrap change, with or without scroll anchoring)
    if (availBack && detected) availBack.style.visibility = key === detected ? 'hidden' : '';
  }

  // The hash names the platform (#dl-<key>, #before-<key>) and follows the pick, without a jump.
  function keyOfHash() {
    var m = /^#(?:dl|before)-([a-z]+)$/.exec(location.hash || '');
    return m && document.getElementById('dl-' + m[1]) ? m[1] : '';
  }
  function remember(key) {
    var h = '#dl-' + key;
    if (location.hash === h) return;
    try { history.replaceState(null, '', h); } catch (e) { /* file: or a sandbox: the URL stays */ }
  }

  if (detected && !document.getElementById('dl-' + detected)) detected = '';
  if (detected) detectedName = nameOf(document.getElementById('dl-' + detected));
  if (availMine) availMine.textContent = detected ? 'This browser reports ' + detectedName + '.' : '';
  if (availRest) availRest.textContent = (detected ? 'Also for ' : 'For ') + rest(detected) + '.';
  if (availBack && detected) {
    var back = document.createElement('button');
    back.type = 'button'; back.className = 'link'; back.textContent = 'Back to ' + detectedName;
    back.addEventListener('click', function () { pick(detected); remember(detected); });
    availBack.appendChild(back);
  }
  pick(keyOfHash() || detected);
  for (var t = 0; t < picks.length; t++) {
    picks[t].addEventListener('click', function (e) {
      var key = this.getAttribute('data-pick');
      if (!document.getElementById('dl-' + key)) return; // let the anchor work
      e.preventDefault();
      pick(key);
      remember(key);
    });
  }
  window.addEventListener('hashchange', function () { var k = keyOfHash(); if (k) pick(k); });
  if (heroBefore) heroBefore.addEventListener('click', function () {
    var d = document.getElementById(heroBefore.getAttribute('href').slice(1));
    if (d && d.tagName === 'DETAILS') d.open = true;
  });
})();
