# ~/Art — an Art Computer sketchbook

This directory holds computational artwork. Every piece is a small, readable
program the person who made it owns, can edit, and can learn from.

**The artwork is code, not an image.** A PNG is an export. The program is the
thing. Keep it readable.

## Layout

```
~/Art/
  lib/p5.min.js       p5.js 1.11.13, vendored once. Never edit it.
  lib/palette.js      the user's Omarchy theme as colors. Generated.
  lib/palette.json    the same, for tools.
  wind-field/         one directory per artwork
    index.html        loads p5 and sketch.js. Nothing else.
    sketch.js         the artwork. This is the file that matters.
    art.json          metadata
    README.md         what it is, and who inspired it
```

Sketches load p5 with a relative `<script src="../lib/p5.min.js">`. That works
because the local server serves `~/Art` as its web root. Do not change it to a
CDN, and do not copy p5 into individual sketch directories.

## Making something

Use the CLI. It handles the scaffold, the metadata and the seed.

```bash
art new "wind field"       # creates ~/Art/wind-field, prints the slug
art run wind-field         # opens it in its own window
art path wind-field        # prints the directory
art list                   # everything made so far
```

Then edit `sketch.js`. **A server is already running and the canvas reloads by
itself when you save.** Do not start a server, do not run `npm install`, do not
open a browser, do not ask the user to refresh.

New artwork always goes at the top level of `~/Art`, never nested inside
another piece.

## House style for generated sketches

The person reading this code may be learning JavaScript. Write for them.

- Plain HTML + JavaScript + p5.js. **No React, no bundler, no build step, no
  `package.json`, no ES modules, no TypeScript.**
- Prefer a named helper function over a clever one-liner.
- Comments explain *the idea* ("each blade leans with the wind"), not the
  syntax ("increment i").
- Aim under ~150 lines. If an idea needs more, it probably needs a better idea.
- Global-mode p5 (`function setup()`, `function draw()`), because that is what
  every tutorial the user will find is written in.
- Target p5.js **1.x**: `preload()` exists, `loadImage`/`loadFont` are
  synchronous. Do not write 2.x-style `async setup()`.
- Always include `windowResized()` with `resizeCanvas(windowWidth, windowHeight)`.
- `createCanvas(windowWidth, windowHeight)` — artwork fills the window.

## Seeds

`art.json` carries a `seed`, and `sketch.js` opens with `const SEED = …` feeding
`randomSeed(SEED)` and `noiseSeed(SEED)`. That is what makes a piece reproduce.

- Changing the **seed** is a *variation* — same idea, different roll.
- Changing the **code** is a *revision* — a different idea.

Keep the two in sync: if you change `SEED` in `sketch.js`, change `seed` in
`art.json` to match.

## art.json

```json
{
  "title": "Wind Field",
  "medium": "p5js",
  "created": "2026-09-03T19:00:00Z",
  "modified": "2026-09-03T19:20:00Z",
  "seed": 12345,
  "prompt": "make a field of grass where every blade follows invisible wind",
  "inspiration": [],
  "tags": [],
  "p5": "1.11.13"
}
```

After editing an artwork, update `modified` to the current UTC time. **Never
drop `prompt`, `created`, or `inspiration`** — they are the history of the
piece. Add fields freely; nothing validates against a fixed schema.

## Remixing — never destroy the original

If asked to make a variant, or to base something on an existing piece:

1. `art new "<new name>"`
2. Copy the source across and change it there.
3. Record the parent in the new piece's `inspiration` array.

Never overwrite an existing artwork to make a different one. If the user
genuinely wants to replace a piece, say what will be lost and ask first.

## Using the user's Omarchy theme

When someone asks for "my colors", "my theme", or "Omarchy colors":

1. Run `art palette` (regenerates `~/Art/lib/palette.json` and `palette.js`).
2. Uncomment the `<script src="../lib/palette.js"></script>` line in
   `index.html` — it is already there, above the p5 tag, and must load first.
3. Use the `PALETTE` global:

```js
background(PALETTE.background);
stroke(PALETTE.accent);
fill(random(PALETTE.colors));      // the theme's hues, ready to loop over
```

Keys: `background foreground accent muted highlight selection colors[] mode theme`.

The palette regenerates automatically when the user switches themes, so artwork
written this way follows the desktop.

## Attribution

When a piece is based on someone else's sketch, tutorial or technique, say so:
add the URL and the person's name to `inspiration` in `art.json`, and credit
them in the artwork's `README.md`. Learning from artists is the point; passing
their work off as new is not.

## Capturing a still

The gallery draws a placeholder from the seed when a piece has no still, so a
thumbnail is optional — but a real one is better. From inside the artwork
directory, with the canvas window focused:

```bash
mv "$(omarchy capture screenshot fullscreen save)" thumbnail.png
```

`omarchy capture screenshot fullscreen save` writes the PNG to `~/Pictures` and
prints its path. `thumbnail.png` is what the gallery looks for.

## Don't

- Edit `lib/p5.min.js`.
- Add `package.json`, a bundler, or a framework.
- Touch anything in `~/.config` or `/usr/share/omarchy`.
- Delete artwork.
- Start a second web server.
