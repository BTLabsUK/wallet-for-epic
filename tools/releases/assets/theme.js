/* Before the first paint: the look this browser picked on the BT Wallet site (localStorage
 * btw-look: a Night, b Grid, c Day), Night when none. A browser that chose this page's old light
 * look (epic-cash-theme) gets Day. External on purpose: no inline script on this page. */
(function () {
  var d = document.documentElement, l = null;
  try {
    l = localStorage.getItem('btw-look');
    if (!l && localStorage.getItem('epic-cash-theme') === 'light') l = 'c';
  } catch (e) {}
  if (l !== 'b' && l !== 'c') l = 'a';
  d.setAttribute('data-look', l);
  var tc = document.querySelector('meta[name=theme-color]');
  if (tc) tc.setAttribute('content', l === 'b' ? '#0a0b0d' : l === 'c' ? '#fbf6ec' : '#08080a');
})();
