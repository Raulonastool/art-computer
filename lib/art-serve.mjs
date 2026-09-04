// art-serve -- the little local server behind Art Computer.
//
// Serves ~/Art as the web root, so a sketch's <script src="../lib/p5.min.js">
// resolves and one server covers the home page, the gallery and every artwork.
//
// Live reload is injected into the HTML *response*, never written to your
// index.html. The file on disk stays small enough to read and learn from --
// which is the entire point of this project.
//
// Binds 127.0.0.1 only.

import http from 'node:http';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';

// ------------------------------------------------------------------ args --

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};

const ROOT    = path.resolve(arg('root', path.join(process.env.HOME, 'Art')));
const WEB     = path.resolve(arg('web', path.join(import.meta.dirname, '..', 'web')));
const RUNDIR  = arg('rundir', '/tmp/art-computer');
const ARTBIN  = path.join(import.meta.dirname, '..', 'bin', 'art');
let   PORT    = parseInt(arg('port', '4242'), 10);

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
  '.gif': 'image/gif', '.webp': 'image/webp', '.ico': 'image/x-icon',
  '.woff2': 'font/woff2', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.mp4': 'video/mp4',
  '.txt': 'text/plain; charset=utf-8', '.md': 'text/plain; charset=utf-8',
};

// --------------------------------------------------------- live reloading --

const clients = new Set();
let bump = null;

function reloadAll(why) {
  clearTimeout(bump);
  bump = setTimeout(() => {
    for (const res of clients) {
      try { res.write(`event: reload\ndata: ${JSON.stringify({ why })}\n\n`); } catch {}
    }
  }, 80);
}

function watch() {
  try {
    fs.watch(ROOT, { recursive: true }, (_e, file) => {
      if (!file) return reloadAll('change');
      // Ignore editor scratch files; they fire constantly and mean nothing.
      if (/(^|\/)\.|~$|\.swp$|\.tmp$|4913$/.test(file)) return;
      reloadAll(file);
    });
  } catch (err) {
    console.error('fs.watch failed, polling instead:', err.message);
    let seen = 0;
    setInterval(async () => {
      let newest = 0;
      const stack = [ROOT];
      while (stack.length) {
        const dir = stack.pop();
        let entries = [];
        try { entries = await fsp.readdir(dir, { withFileTypes: true }); } catch { continue; }
        for (const e of entries) {
          if (e.name.startsWith('.')) continue;
          const p = path.join(dir, e.name);
          if (e.isDirectory()) { stack.push(p); continue; }
          try { newest = Math.max(newest, (await fsp.stat(p)).mtimeMs); } catch {}
        }
      }
      if (seen && newest > seen) reloadAll('poll');
      seen = newest;
    }, 1000);
  }
}

const RELOAD_SNIPPET = `
<script>
// Injected by art-serve while you are working. Not part of your artwork.
new EventSource('/_art/events').addEventListener('reload', () => location.reload());
</script>
`;

// -------------------------------------------------------------- metadata --

async function sketches() {
  let entries = [];
  try { entries = await fsp.readdir(ROOT, { withFileTypes: true }); } catch { return []; }
  const out = [];
  for (const e of entries) {
    if (!e.isDirectory() || e.name.startsWith('.') || e.name === 'lib') continue;
    const meta = path.join(ROOT, e.name, 'art.json');
    try {
      const json = JSON.parse(await fsp.readFile(meta, 'utf8'));
      const st = await fsp.stat(path.join(ROOT, e.name));
      let thumbnail = null;
      try { await fsp.access(path.join(ROOT, e.name, 'thumbnail.png')); thumbnail = `/${e.name}/thumbnail.png`; } catch {}
      out.push({ ...json, slug: e.name, url: `/${e.name}/`, thumbnail, mtime: st.mtimeMs });
    } catch {}
  }
  return out.sort((a, b) => b.mtime - a.mtime);
}

// ---------------------------------------------------------------- static --

// Keep every resolved path inside a root we own. `..` in a URL must not escape.
function safeJoin(base, urlPath) {
  const p = path.normalize(path.join(base, decodeURIComponent(urlPath)));
  return p.startsWith(base) ? p : null;
}

async function serveFile(res, file, { injectReload = false } = {}) {
  let st;
  try { st = await fsp.stat(file); } catch { return false; }
  if (st.isDirectory()) return false;

  const type = MIME[path.extname(file).toLowerCase()] || 'application/octet-stream';

  if (injectReload && type.startsWith('text/html')) {
    let html = await fsp.readFile(file, 'utf8');
    html = html.includes('</body>')
      ? html.replace('</body>', RELOAD_SNIPPET + '</body>')
      : html + RELOAD_SNIPPET;
    res.writeHead(200, { 'content-type': type, 'cache-control': 'no-store' });
    res.end(html);
    return true;
  }

  res.writeHead(200, {
    'content-type': type,
    'content-length': st.size,
    'cache-control': type.startsWith('text/') ? 'no-store' : 'public, max-age=3600',
  });
  fs.createReadStream(file).pipe(res);
  return true;
}

const json = (res, code, body) => {
  res.writeHead(code, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
};

// ----------------------------------------------------------------- make ----

// This endpoint starts a coding agent, so it is the one real security surface
// in the program. It is reachable from localhost only, must come from our own
// page, and the prompt is handed over as a single argv element -- never
// interpolated into a shell string.
function makeArtwork(prompt) {
  runArt(['make', prompt]);
}

// Opening a piece goes through the CLI too, so a click in the gallery lands in
// exactly the window `art run` would give you -- right title, right window
// rules, and the home page stays where it is. A target="_blank" out of a
// Chromium --app window gets you a blank popup instead.
function openArtwork(slug) {
  runArt(['run', slug]);
}

function runArt(args) {
  const child = spawn(ARTBIN, args, {
    detached: true,
    stdio: 'ignore',
    env: { ...process.env, ART_HOME: ROOT },
  });
  child.unref();
}

// A slug is a directory name we made. Anything else never reaches the CLI.
const SLUG = /^[a-z0-9][a-z0-9-]{0,59}$/;

async function isArtwork(slug) {
  if (!SLUG.test(slug)) return false;
  try { await fsp.access(path.join(ROOT, slug, 'art.json')); return true; } catch { return false; }
}

const LOCAL_HOSTS = new Set(['127.0.0.1', 'localhost', '[::1]', '::1']);

// A page in the user's ordinary browser must not be able to reach this and
// start an agent. Binding to loopback stops the network; pinning Host stops
// DNS rebinding, where a hostile name resolves to 127.0.0.1.
function callerOk(req) {
  const host = String(req.headers.host || '');
  const hostname = host.replace(/:\d+$/, '');
  if (!LOCAL_HOSTS.has(hostname)) return false;
  if (host.includes(':') && !host.endsWith(`:${PORT}`)) return false;

  const origin = req.headers.origin;
  if (!origin) return true; // curl and friends; still loopback-only
  try {
    const u = new URL(origin);
    return LOCAL_HOSTS.has(u.hostname) && u.port === String(PORT);
  } catch { return false; }
}

function readBody(req, limit = 64 * 1024) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (c) => {
      size += c.length;
      if (size > limit) { reject(new Error('too large')); req.destroy(); return; }
      chunks.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

// ---------------------------------------------------------------- routes ----

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${PORT}`);
  const pathname = url.pathname;

  try {
    if (pathname === '/_art/ping') return json(res, 200, { ok: true, root: ROOT, port: PORT });

    if (pathname === '/_art/events') {
      res.writeHead(200, {
        'content-type': 'text/event-stream',
        'cache-control': 'no-store',
        connection: 'keep-alive',
      });
      res.flushHeaders?.();
      res.write('retry: 500\n\n');
      clients.add(res);
      // Idle streams get dropped by intermediaries and by the browser's own
      // bookkeeping; a comment every 25s keeps them honest.
      const ka = setInterval(() => { try { res.write(':ka\n\n'); } catch {} }, 25000);
      req.on('close', () => { clearInterval(ka); clients.delete(res); });
      return;
    }

    if (pathname === '/_art/sketches') return json(res, 200, await sketches());

    if (pathname === '/_art/make') {
      if (req.method !== 'POST') return json(res, 405, { error: 'POST only' });
      if (!callerOk(req)) return json(res, 403, { error: 'bad origin' });
      let prompt;
      try { prompt = JSON.parse(await readBody(req)).prompt; }
      catch { return json(res, 400, { error: 'bad body' }); }
      if (typeof prompt !== 'string' || !prompt.trim()) return json(res, 400, { error: 'empty prompt' });
      makeArtwork(prompt.trim().slice(0, 2000));
      return json(res, 202, { ok: true });
    }

    if (pathname === '/_art/open') {
      if (req.method !== 'POST') return json(res, 405, { error: 'POST only' });
      if (!callerOk(req)) return json(res, 403, { error: 'bad origin' });
      let slug;
      try { slug = JSON.parse(await readBody(req)).slug; }
      catch { return json(res, 400, { error: 'bad body' }); }
      if (typeof slug !== 'string' || !(await isArtwork(slug))) {
        return json(res, 404, { error: 'no such artwork' });
      }
      openArtwork(slug);
      return json(res, 202, { ok: true });
    }

    // Home page and its assets come from the repo's web/ directory.
    if (pathname === '/' || pathname === '/index.html') {
      if (await serveFile(res, path.join(WEB, 'index.html'))) return;
      return json(res, 500, { error: 'home page missing' });
    }
    if (pathname.startsWith('/_art/')) {
      const f = safeJoin(WEB, pathname.slice('/_art/'.length));
      if (f && await serveFile(res, f)) return;
      return json(res, 404, { error: 'not found' });
    }

    // Everything else is your artwork, served out of ~/Art.
    const file = safeJoin(ROOT, pathname);
    if (!file) { res.writeHead(403); return res.end('no'); }

    if (pathname.endsWith('/')) {
      if (await serveFile(res, path.join(file, 'index.html'), { injectReload: true })) return;
    } else {
      if (await serveFile(res, file, { injectReload: true })) return;
      // /wind-field -> /wind-field/
      try {
        if ((await fsp.stat(file)).isDirectory()) {
          res.writeHead(302, { location: pathname + '/' });
          return res.end();
        }
      } catch {}
    }

    res.writeHead(404, { 'content-type': 'text/html; charset=utf-8' });
    res.end(`<!doctype html><meta charset=utf-8><title>nothing here</title>
      <style>body{background:#141414;color:#888;font:14px ui-monospace,monospace;
      display:grid;place-content:center;height:100vh;margin:0}a{color:#7aa2f7}</style>
      <p>nothing at <code>${pathname.replace(/[<&]/g, '')}</code> &middot; <a href="/">art computer</a>`);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) json(res, 500, { error: 'server error' });
  }
});

// ----------------------------------------------------------------- boot ----

function listen(port, attemptsLeft = 20) {
  server.once('error', (err) => {
    if (err.code === 'EADDRINUSE' && attemptsLeft > 0) return listen(port + 1, attemptsLeft - 1);
    console.error(err.message);
    process.exit(1);
  });
  server.listen(port, '127.0.0.1', async () => {
    PORT = server.address().port;
    await fsp.mkdir(RUNDIR, { recursive: true });
    await fsp.writeFile(path.join(RUNDIR, 'port'), String(PORT));
    await fsp.writeFile(path.join(RUNDIR, 'pid'), String(process.pid));
    console.log(`art-serve  ${ROOT}  ->  http://127.0.0.1:${PORT}`);
    watch();
  });
}

for (const sig of ['SIGINT', 'SIGTERM']) {
  process.on(sig, async () => {
    try { await fsp.rm(path.join(RUNDIR, 'port'), { force: true }); } catch {}
    process.exit(0);
  });
}

await fsp.mkdir(ROOT, { recursive: true });
listen(PORT);
