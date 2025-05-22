document.addEventListener('keydown', (e) => {
  if (e.altKey && e.shiftKey && e.key.toLowerCase() === 'a') {
    const links = Array.from(document.querySelectorAll('a'))
      .map(a => a.href)
      .filter(href =>
        href.startsWith('https://codeforces.com/') &&
        (
          href.includes('/problemset/problem/') ||
          (href.includes('/contest/') && href.includes('/problem/')) ||
          (href.includes('/gym/') && href.includes('/problem/'))
        )
      );

    const result = links.join('\n\n');

    navigator.clipboard.writeText(result)
      .catch(err => {
        alert("❌ Failed to copy links to clipboard.");
      });
  }
});
