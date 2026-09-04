# Vendored third-party code

Nothing here is written by Art Computer. See ../NOTICE for licenses and credits.

## p5-1.11.13/

p5.js v1.11.13 — the officially maintained `r1` (1.x) release line.
Downloaded unmodified from cdnjs:

    https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.13/p5.min.js
    sha256  e9df7d05fd7c3ff028fc09a312a43101241f23c43143b387bf89d96b2e4e0849

`install.sh` copies `p5.min.js` to `~/Art/lib/p5.min.js`, where every sketch
loads it with a relative `<script src="../lib/p5.min.js">`.

### Why 1.x and not 2.x

p5.js 2.0 removed `preload()` and made asset loading asynchronous. Nearly all
of the material Art Computer points you at — The Coding Train, the p5.js
tutorials, community sketches on OpenProcessing — is written against 1.x and
does not run as-is on 2.x. Art Computer exists to lower the barrier to
creative coding, so it ships the version the tutorials teach.

The Processing Foundation maintains 1.x under the npm `r1` dist-tag.
