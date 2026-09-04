# Art Computer

**Make computational art by talking to your coding agent.**

Art Computer turns a prompt into a running p5.js sketch that lives as plain
source in `~/Art` — a directory you own, can read, can edit, and can learn from.

```bash
art make "a field of grass where every blade follows invisible wind"
```

That scaffolds the piece, opens it in its own window, and hands it to whichever
coding agent you already use. You watch the canvas redraw as it writes.

**The artwork is code, not an image.** A PNG is an export. The program is the
thing, and it is small enough to read.

## What you get

```
~/Art/
  lib/p5.min.js       p5.js 1.11.13, vendored once, works offline
  lib/palette.js      your Omarchy theme as colors, regenerated on theme change
  AGENTS.md           the house style your agent follows
  wind-field/
    index.html        loads p5 and sketch.js. Nothing else.
    sketch.js         the artwork. ~150 lines of plain JavaScript.
    art.json          title, seed, the prompt that started it, inspiration
    README.md         what it is, and who inspired it
```

No `package.json`. No bundler. No framework. No build step. If you can read
JavaScript you can read every line of your own artwork — which is the point.

## Install

Requires: `bash`, `jq`, and `node` (or `python3` for a no-live-reload fallback).
Built for [Omarchy](https://omarchy.org), degrades gracefully elsewhere.

```bash
git clone https://github.com/Raulonastool/art-computer.git
cd art-computer
./install.sh          # add --menu to also add Omarchy menu entries
```

Then:

```bash
art make "a thousand dots that remember where they have been"
art home              # or SUPER + A
```

## Commands

```
art make "<prompt>"    scaffold it, show it, hand it to your agent
art home               the home page: make, your gallery, learn, explore
art list               everything you have made
art run [name]         show a piece in its own window
art open [name]        talk to your agent about a piece
art new [name]         an empty sketch, no agent
art path [name]        print its directory
art palette            refresh colors from your Omarchy theme
art serve [--stop|--status|--log]
```

Every command takes the piece you are standing in, or the most recent one, when
you leave the name off.

## How it works

- **One local server** (`lib/art-serve.mjs`, ~300 lines) serves `~/Art` on
  `127.0.0.1:4242`. It is why a sketch can say `<script src="../lib/p5.min.js">`.
- **Live reload is injected into the response**, never written into your
  `index.html`. Your file on disk stays clean.
- **Your agent, not ours.** Art Computer ships no AI. It runs whichever agent
  Omarchy is configured to use.
- **The seed is the reproducibility.** `SEED` in `sketch.js` and `seed` in
  `art.json` stay in sync: same seed, same picture. Change the seed for a
  variation, change the code for a revision.
- **Your theme is the palette.** `art palette` renders the active Omarchy theme
  to `~/Art/lib/palette.json` and `palette.js`, and a theme-set hook keeps it
  current, so "use my colors" is always true.

## What it touches

Everything, and nothing else:

| Path | What |
| --- | --- |
| `~/.local/bin/art` | symlink to the CLI |
| `~/Art/` | your sketchbook (p5.js, palette, `AGENTS.md`, `CLAUDE.md`) |
| `~/.claude/skills/art-computer` (and `.agents`, `.codex`) | symlinked agent skill |
| `~/.config/hypr/art-computer.lua` | SUPER+A, SUPER+ALT+A, full-opacity canvas windows |
| `~/.config/hypr/bindings.lua` | one `require()` line, between markers, backed up first |
| `~/.config/omarchy/hooks/theme-set.d/10-art-palette` | symlink; regenerates the palette |
| `~/.local/share/applications/art-computer.desktop` | launcher entry |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | only with `--menu`, backed up first |

Nothing under `/usr/share/omarchy` is written.

```bash
./uninstall.sh            # removes all of the above
./uninstall.sh --purge    # also removes ~/Art/lib and the agent instructions
```

**Your artwork is never touched by either script.**

## Credit

p5.js is made by the [Processing Foundation](https://processingfoundation.org)
and the p5.js community; Art Computer merely bundles it. The learning material
this points at belongs to [Daniel Shiffman / The Coding
Train](https://thecodingtrain.com), the Processing Foundation,
[OpenProcessing](https://openprocessing.org), [Shadertoy](https://shadertoy.com)
and [Olivia Jack / Hydra](https://hydra.ojack.xyz). See [NOTICE](NOTICE).

Independent project. Not affiliated with, endorsed by, or sponsored by any of
them, or by Omarchy.

## License

MIT — see [LICENSE](LICENSE). p5.js is LGPL-2.1 and is bundled unmodified.
