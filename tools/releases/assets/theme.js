/* Before the first paint: the light look if this browser chose it before. External on purpose:
 * no inline script, so the page can be served under a strict Content-Security-Policy. */
try {
  if (localStorage.getItem('epic-cash-theme') === 'light') {
    document.documentElement.setAttribute('data-theme', 'light');
  }
} catch (e) {}
