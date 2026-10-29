// Epic Cash releases page: the theme toggle, copy buttons for checksums and commands, and the
// platform the browser reports (its card first; Other platforms puts every card back). All of
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

  var mine = document.getElementById('mine'), mineText = document.getElementById('mine-text');
  var other = document.getElementById('other');
  var cards = document.querySelectorAll('.card[data-plat]');

  function pick(key) {
    var card = key && document.getElementById('dl-' + key);
    if (!card) { neutral(); return; }
    for (var i = 0; i < cards.length; i++) cards[i].classList.toggle('is-mine', cards[i] === card);
    var before = document.querySelectorAll('details[data-before]');
    for (var j = 0; j < before.length; j++) before[j].open = before[j].getAttribute('data-before') === key;
    root.setAttribute('data-plat', key);
    var name = card.querySelector('h3').firstChild.textContent.trim();
    var app = card.querySelector('.app').textContent;
    if (mineText) {
      mineText.textContent = '';
      var b = document.createElement('b');
      b.textContent = app + ' for ' + name;
      mineText.appendChild(document.createTextNode('This browser reports ' + name + ': '));
      mineText.appendChild(b);
      mineText.appendChild(document.createTextNode(' is first.'));
    }
    if (other) other.textContent = 'Other platforms';
    if (mine) mine.hidden = false;
  }
  function neutral() {
    root.removeAttribute('data-plat');
    for (var i = 0; i < cards.length; i++) cards[i].classList.remove('is-mine');
    var before = document.querySelectorAll('details[data-before]');
    for (var j = 0; j < before.length; j++) before[j].open = false;
    if (mineText) mineText.textContent = 'Every platform, in one list.';
    if (other && detected) other.textContent = 'Back to ' + detectedName;
  }

  var detected = platform(), detectedName = '';
  if (detected && document.getElementById('dl-' + detected)) {
    detectedName = document.getElementById('dl-' + detected).querySelector('h3').firstChild.textContent.trim();
    pick(detected);
    if (other) other.addEventListener('click', function () {
      if (root.hasAttribute('data-plat')) neutral(); else pick(detected);
    });
  }
})();
