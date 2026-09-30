// Crude text extraction for text-based PDFs: inflate FlateDecode streams,
// pull text-showing operators (Tj/TJ/'). No layout fidelity; good enough to grep.
const fs = require('fs');
const zlib = require('zlib');

const buf = fs.readFileSync(process.argv[2]);
const out = [];
let i = 0;
while ((i = buf.indexOf('stream', i)) !== -1) {
   let s = i + 6;
   if (buf[s] === 0x0d) s++;
   if (buf[s] === 0x0a) s++;
   const e = buf.indexOf('endstream', s);
   if (e === -1) break;
   let inflated = null;
   try { inflated = zlib.inflateSync(buf.slice(s, e)); } catch {}
   if (inflated) {
      const txt = inflated.toString('latin1');
      if (/\b(Tj|TJ)\b/.test(txt)) out.push(extractText(txt));
   }
   i = e + 9;
}

function decodePdfString(str) {
   return str
      .replace(/\\([0-7]{1,3})/g, (_, o) => String.fromCharCode(parseInt(o, 8)))
      .replace(/\\([nrtbf()\\])/g, (_, c) => ({ n: '\n', r: '\r', t: '\t', b: '', f: '', '(': '(', ')': ')', '\\': '\\' }[c]));
}

function extractText(content) {
   const parts = [];
   // (string) Tj  |  [(a) -250 (b)] TJ  |  (string) '
   const re = /\((?:[^()\\]|\\.)*\)\s*(?:Tj|')|\[((?:[^\]\\]|\\.)*)\]\s*TJ|\bT\*|\bTd\b|\bTD\b|\bBT\b/g;
   let m;
   for (m of content.matchAll(re)) {
      const tok = m[0];
      if (tok === 'BT' || tok === 'T*' || /T[dD]$/.test(tok)) { parts.push('\n'); continue; }
      if (tok.endsWith('TJ')) {
         const inner = m[1] || '';
         for (const sm of inner.matchAll(/\((?:[^()\\]|\\.)*\)|(-?\d+(?:\.\d+)?)/g)) {
            if (sm[0].startsWith('(')) parts.push(decodePdfString(sm[0].slice(1, -1)));
            else if (parseFloat(sm[1]) < -150) parts.push(' ');
         }
      } else {
         parts.push(decodePdfString(tok.replace(/\)\s*(?:Tj|')$/, '').slice(1)));
      }
   }
   return parts.join('').replace(/\n{2,}/g, '\n');
}

fs.writeFileSync(process.argv[3], out.join('\n--- stream ---\n'));
console.log(`${out.length} text streams -> ${process.argv[3]}`);
