// Extract XenForo posts (author, id, date, body-text) from a saved thread page.
const fs = require('fs');
const html = fs.readFileSync(process.argv[2], 'utf8');

function balancedDiv(s, openIdx) {
   // openIdx points at '<div'; walk forward tracking div depth.
   let depth = 0, i = openIdx;
   const re = /<\/?div\b[^>]*>/g;
   re.lastIndex = openIdx;
   let m;
   while ((m = re.exec(s))) {
      if (m[0][1] === '/') depth--; else depth++;
      if (depth === 0) return s.slice(openIdx, m.index + m[0].length);
   }
   return s.slice(openIdx);
}

function detag(s) {
   return s
      .replace(/<script[\s\S]*?<\/script>/gi, '')
      .replace(/<blockquote[^>]*>/gi, '\n[QUOTE]\n')
      .replace(/<\/blockquote>/gi, '\n[/QUOTE]\n')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n')
      .replace(/<li\b[^>]*>/gi, '\n - ')
      .replace(/<img[^>]*alt="([^"]*)"[^>]*>/gi, '($1)')
      .replace(/<a\b[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, '$2 <$1>')
      .replace(/<[^>]+>/g, '')
      .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"').replace(/&#0?39;/g, "'").replace(/&nbsp;/g, ' ')
      .replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
}

const out = [];
let idx = 0;
while ((idx = html.indexOf('<article class="message', idx)) !== -1) {
   const chunk = html.slice(idx, html.indexOf('<article class="message', idx + 1) === -1
      ? html.length
      : html.indexOf('<article class="message', idx + 1));
   const author = (chunk.match(/data-author="([^"]*)"/) || [])[1] || '?';
   const pid = (chunk.match(/data-content="(post-\d+)"/) || [])[1] || '?';
   const date = (chunk.match(/<time[^>]*datetime="([^"]*)"/) || [])[1] || '?';
   const bw = chunk.indexOf('<div class="bbWrapper">');
   if (bw !== -1) {
      const body = detag(balancedDiv(chunk, bw));
      out.push(`=== ${pid} | ${author} | ${date} ===\n${body}\n`);
   }
   idx += 1;
}
fs.writeFileSync(process.argv[3], out.join('\n'));
console.log(`${out.length} posts -> ${process.argv[3]}`);
