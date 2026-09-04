---
name: art-computer
description: >
  Make, run and remix computational artwork with Art Computer — p5.js sketches
  that live as plain source in ~/Art. Use when the user asks to make art, a
  sketch, a generative or computational piece, a screensaver-ish animation, a
  visualiser, "something pretty", or to change, vary, remix or explain an
  existing piece. Triggers: art, artwork, sketch, p5, p5.js, generative,
  creative coding, canvas, flow field, particles, `art make`, `art new`,
  `art run`, ~/Art, "use my theme colors" for a sketch. Not for design mockups,
  charts, or images — this makes running programs.
---

# Art Computer

Artwork here is **code the user owns**: one directory per piece under `~/Art`,
each a plain `index.html` + `sketch.js` running p5.js 1.x. A PNG is an export;
the program is the artwork.

`~/Art/AGENTS.md` is the full house style and it is the authority. **Read it
before writing a sketch.** This skill is only the outer loop.

## Making a piece

Use the CLI — it handles the slug, the scaffold, the seed and `art.json`.

```bash
art new "wind field"      # creates ~/Art/wind-field, prints the slug
art run wind-field        # opens it in its own window
art list                  # everything made so far
art path wind-field       # prints the directory
```

Then edit `sketch.js`. **A server is already running and the canvas reloads
itself on save.** Never start a server, run `npm install`, open a browser, or
ask the user to refresh — all four are wrong here.

If `art` is not on PATH, Art Computer is not installed; say so rather than
hand-rolling a sketch directory.

## Writing the sketch

Follow `~/Art/AGENTS.md`. The short version:

- Global-mode p5 (`function setup()`, `function draw()`), p5 **1.x** only.
- No React, no bundler, no build step, no `package.json`, no ES modules.
- Under ~150 lines, named helpers over clever one-liners, comments that explain
  the idea rather than the syntax.
- `createCanvas(windowWidth, windowHeight)` plus a `windowResized()`.
- Keep `SEED` in `sketch.js` and `seed` in `art.json` in sync.
- The person reading this code may be learning JavaScript. Write for them.

## Their colors

"my colors" / "my theme" / "Omarchy colors" means: run `art palette`, uncomment
the `palette.js` script tag already sitting in `index.html`, then use the
`PALETTE` global (`background`, `foreground`, `accent`, `muted`, `highlight`,
`selection`, `colors[]`). It regenerates on theme change, so the artwork
follows the desktop.

## Variations and remixes

- New **seed** = a variation. New **code** = a revision.
- To base a piece on an existing one: `art new`, copy it across, change it
  *there*, and record the parent in the new piece's `inspiration`.
- **Never overwrite or delete existing artwork.** If the user really means to
  replace something, say what would be lost and ask first.

## Credit

Working from someone's sketch, tutorial or technique? Put the URL and their
name in `art.json`'s `inspiration` and in the piece's `README.md`. Learning
from artists is the point; passing their work off as new is not.

## Don't

- Edit `~/Art/lib/p5.min.js`, or copy p5 into a sketch directory.
- Add a framework, bundler or `package.json`.
- Start a second web server.
- Touch `~/.config` or `/usr/share/omarchy` (that is the `omarchy` skill's job).
