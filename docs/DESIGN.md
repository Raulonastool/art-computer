# Design choices

Why Art Computer is built the way it is. Every entry below is a decision that
could reasonably have gone the other way, so each one states the trade-off it
accepts and what would change it.

The one-line version: **the artwork is a small program you own, and Art Computer
is the smallest amount of machinery that gets you one.**

---

## The artwork is source, not an image

A generated PNG is a dead end. You cannot ask it why it looks like that, you
cannot move one number and see what happens, and you certainly cannot learn to
make the next one from it. A p5.js sketch is 150 lines you can read in a sitting.

Everything else follows from this. The gallery shows running canvases rather
than thumbnails. `art make` hands you a directory, not a file to download. The
house style caps sketches at ~150 lines and asks for named helpers and comments
that explain the idea — because the code is the deliverable, and unreadable code
is a failed deliverable even when the picture is nice.

**Trade-off.** There is no "export my art" button and no way to hand someone a
finished piece as a single file. You share a directory or a repository.

---

## Art Computer ships no AI

It runs whichever coding agent you already configured — through
`omarchy-default-agent`, which supports Claude Code, Codex, Gemini, Copilot,
OpenCode, Crush, Grok, Pi and Oh My Pi.

Bundling a model would mean API keys, billing, a vendor relationship, and an
opinion about which model is best that goes stale in a month. It would also make
this a product rather than a tool. The agent is the part of the stack that
changes fastest and that people have the strongest preferences about, so it is
the part to not own.

**Trade-off.** Output quality is entirely your agent's. A weaker agent makes
weaker art, and Art Computer cannot compensate. Nothing works at all until you
have set a default agent.

---

## p5.js 1.x, not 2.x

p5.js 2.0 removed `preload()` and made asset loading asynchronous. Almost every
tutorial a beginner will find — The Coding Train, the p5.js tutorials, community
sketches on OpenProcessing — is written against 1.x and does not run as-is on
2.x.

Art Computer exists to lower the barrier to creative coding. Shipping the
version that does not match the tutorials would raise it. The Processing
Foundation maintains 1.x under the npm `r1` tag, so this is a supported line and
not an abandoned one.

**Trade-off.** New p5 features land in 2.x and are unavailable here. This choice
gets revisited when the teaching material has moved.

---

## p5.js is vendored, not loaded from a CDN

One copy in `~/Art/lib/p5.min.js`, ~1 MB, installed once.

Artwork should run on a laptop with no network, five years from now, after the
CDN has reorganised its URLs. A sketch that needs the internet to draw a circle
is not something you own. Vendoring also pins the version: the same sketch draws
the same picture, which is the whole point of the seed.

**Trade-off.** ~1 MB in the repository, and version bumps are a manual commit
rather than a URL edit.

---

## A local server, not `file://`

`lib/art-serve.mjs` serves `~/Art` on `127.0.0.1:4242`.

Two reasons. First, `~/Art` as the web root is what lets every sketch load p5
with a relative `<script src="../lib/p5.min.js">` — one shared copy rather than
one per piece. Second, live reload needs a server to push from; browsers do not
watch the filesystem.

It binds to loopback only and serves exactly one directory.

**Trade-off.** A background process and a held port. `art serve --stop` when it
is in the way.

---

## Live reload is injected into the response

The reload snippet is added to the HTML as it is served. It is never written
into your `index.html`.

Your file on disk stays exactly what you wrote — no stray script tag, nothing to
strip before publishing, nothing that breaks when the server is not running. The
piece is portable to any static host as-is.

**Trade-off.** What runs in the browser is not byte-identical to what is on
disk, which is briefly surprising if you view source expecting a match.

---

## One plain directory per piece

```
~/Art/wind-field/
  index.html    loads p5 and sketch.js. Nothing else.
  sketch.js     the artwork
  art.json      title, seed, prompt, inspiration
  README.md     what it is, and who inspired it
```

No `package.json`, no bundler, no build step, no framework, no database, no
index file that has to stay in sync. The filesystem is the data model.

This means your sketchbook works with everything you already have: `ls`, `grep`,
a file manager, `git`, a backup tool, another editor. Nothing about a piece
depends on Art Computer being installed — the directory is a working static
site on its own.

**Trade-off.** Listing every piece means reading every `art.json`, which would
be slow at thousands of pieces. That is not a realistic sketchbook size.

---

## The seed is the reproducibility

`sketch.js` opens with `const SEED = …` feeding `randomSeed()` and
`noiseSeed()`; `art.json` records the same number.

This gives generative work a vocabulary it usually lacks:

- Change the **seed** → a **variation**. Same idea, different roll of the dice.
- Change the **code** → a **revision**. A different idea.

Without it, "make me another one" is ambiguous and a piece you liked yesterday
is gone forever.

**Trade-off.** It only holds if the sketch draws all its randomness through p5's
seeded generators. A sketch that reads `Math.random()` or the wall clock is not
reproducible, and nothing enforces that beyond the house style.

---

## The desktop theme is the palette

`art palette` renders the active Omarchy theme to `~/Art/lib/palette.json` and
`palette.js`, and a `theme-set` hook regenerates it whenever you switch themes.

So "use my colors" is a fact rather than a guess, and artwork written that way
follows the desktop when it changes. It also gives an agent a real answer to a
question it otherwise has to invent one for, which measurably improves the
output.

**Trade-off.** Pieces that opt in are tied to a machine's theme; the same sketch
looks different on someone else's desktop. Opting out is one commented-out
script tag, which is why the tag ships commented rather than active.

---

## Bash and `jq`, no runtime for the CLI

`bin/art` is a bash script. `lib/art-serve.mjs` is plain Node with no
dependencies.

Omarchy already has bash, `jq` and `node`. A CLI that needs its own package
manager to install a thing that helps you avoid package managers would be a
joke. There is no `npm install` anywhere in this project.

**Trade-off.** Bash is a poor language for anything complicated, which is a real
ceiling on how clever the CLI can get. That ceiling is also a useful constraint.

---

## Omarchy-first, degrades elsewhere

The theme integration, the keybindings, the menu entries and the agent launcher
are all Omarchy. Everything else — the CLI, the server, the sketchbook, the
house style — is portable.

Building for one well-defined desktop means the integration is genuinely good
rather than lowest-common-denominator. `install.sh` skips any piece whose target
directory does not exist, so on another system you get the CLI and the
sketchbook without the desktop wiring.

**Trade-off.** The best experience needs Omarchy. Elsewhere you lose the
palette, the keybindings and the agent launcher — which is the part that makes
`art make` a single command.

---

## `AGENTS.md`, with `CLAUDE.md` as a symlink

The house style lives in `~/Art/AGENTS.md`. `~/Art/CLAUDE.md` is a symlink to
it, not an `@AGENTS.md` import line.

An agent launched for a piece works inside `~/Art/<piece>/`, so an import
pointing at `~/Art/AGENTS.md` resolves *outside* its working directory — and
Claude Code stops to ask about external file references. A symlink is the same
document under the other name, with nothing to resolve.

**Trade-off.** Two paths to one file, which is momentarily confusing in a
listing. The symlink is not the whole story either: see below.

---

## `art` pre-trusts the piece directory it just created

Every piece is a brand-new directory, and an agent meeting a directory for the
first time stops to ask whether it is trusted. Without intervention, `art make`
ends its first run on a modal dialog that defaults to *no* — on the very first
thing a new user does. The parent `~/Art/CLAUDE.md` raises a second prompt, for
the same reason the symlink exists: it is outside the piece directory.

So when your default agent is Claude Code, `art` records that consent in
`~/.claude.json` before launching. This is deliberately the narrowest possible
version:

- Only a directory **directly inside `~/Art`** that **carries an `art.json`** —
  that is, one `art` scaffolded itself, seconds ago, because you ran the command.
- Only those two flags. No permissions, no allowed tools, no other setting.
- `ART_NO_TRUST=1` keeps the prompt.

The consent is real — you asked for the directory by name — and recording it is
honest rather than a bypass. Anything broader would not be.

**Trade-off.** A tool writing to another tool's config file is a coupling, and
it can be lost if a running agent rewrites `~/.claude.json` at the wrong moment.
The cost of losing that race is one prompt, so the write is a
temp-file-and-rename rather than anything more elaborate. Only Claude Code is
implemented; the other agents fall through to a no-op rather than guess at a
config format nobody has verified.

---

## The canvas window is not forced fullscreen

Artwork opens in its own window with full opacity — it opts out of Omarchy's
browser transparency, because a piece composited over your terminal is not the
piece.

It is deliberately not forced fullscreen. That fights the tiler and traps people
in a window they cannot get out of. `SUPER + F` when you want it.
