document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 'l') {
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

    const result = links.length > 0 ? links.join('\n\n') : ' ';

    navigator.clipboard.writeText(result)
      .then(() => {
        if (links.length > 0) {
          alert("✅ Codeforces problem links copied to clipboard!");
        } else {
          alert("ℹ️ No links found. A space was copied to the clipboard.");
        }
      })
      .catch(err => {
        console.error("❌ Failed to copy:", err);
        alert("❌ Failed to copy links to clipboard.");
      });
  }
});
