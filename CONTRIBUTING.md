# Contributing

Thanks for looking. This is a small project with a narrow purpose, so the most
useful thing you can do before writing code is read
[docs/DESIGN.md](docs/DESIGN.md) — most of what a newcomer would reasonably
propose has a deliberate reason for being the way it is, and the trade-offs are
written down.

## What is most wanted

The [What's next](README.md#whats-next) list in the README, in roughly that
order. Beyond it:

- **Reports from other machines.** This has been tested on exactly one setup
  (Omarchy, Hyprland, Arch, single monitor). If `install.sh` does something
  wrong on yours, that is a genuinely valuable issue.
- **Trust pre-approval for an agent you actually use.** `trust_dir` in `bin/art`
  has a `case` waiting for more branches. Only add one if you have verified how
  that agent records trust — a guess is worse than the no-op it replaces.
- **Sketches.** If the house style in `share/AGENTS.md` produces bad art for a
  kind of prompt, that is a bug in the instructions.

## Ground rules

**No build step.** No `package.json`, no bundler, no framework, no dependency
that needs installing. `bin/art` is bash with `jq`; `lib/art-serve.mjs` is plain
Node with no imports outside the standard library. This is a constraint, not an
oversight — see the design doc.

**Never touch the user's artwork.** Not the install script, not the uninstall
script, not the CLI. `~/Art/<piece>/` belongs to the person who made it. The
same goes for anything under `/usr/share/omarchy`.

**Anything written outside the repo gets documented.** The "What it touches"
table in the README is a promise. If your change writes a new file, adds a
config entry, or leaves something behind after uninstall, that table changes in
the same commit.

**Match the surrounding comments.** The code explains *why* rather than *what*,
in full sentences. A comment that restates the line below it is noise; one that
records the reason a choice was made is the point.

## Working on it

```bash
git clone https://github.com/Raulonastool/art-computer.git
cd art-computer
./install.sh                      # ~/.local/bin/art symlinks to your checkout
```

The install symlinks rather than copies, so edits to `bin/art` are live
immediately — no reinstall between changes.

```bash
bash -n bin/art                   # syntax check
ART_HOME=/tmp/art-test art list   # run against a scratch sketchbook
art serve --log                   # what the server is doing
```

`ART_HOME` redirects everything — CLI, server, install — at a throwaway
directory, which is the safe way to test anything destructive.

There is no test suite yet. If you add one, that is a contribution in itself.

## Licensing

MIT. By contributing you agree your work ships under it. p5.js is vendored
unmodified under LGPL-2.1 and is not ours to relicense — see [NOTICE](NOTICE).
