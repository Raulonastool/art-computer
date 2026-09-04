# {{TITLE}}

{{PROMPT_BLOCK}}
## Run it

```bash
art run {{SLUG}}
```

## Files

- `sketch.js` — the artwork. This is the part worth reading.
- `index.html` — loads p5.js and `sketch.js`. That's all it does.
- `art.json` — metadata: title, seed, the prompt that started it, inspiration.

## Change it

Talk to your agent from inside this directory:

```bash
art open {{SLUG}}
```

Or just edit `sketch.js` — the canvas reloads by itself while `art serve` is running.

## Seed

`SEED` at the top of `sketch.js` makes the randomness repeatable. Same seed,
same artwork. Change it for a new variation of the same idea.

---

Made with [Art Computer](https://github.com/Raulonastool/art-computer) · Drawn with [p5.js](https://p5js.org)
