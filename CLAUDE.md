# florilegium

florilegium grows a margin of plants and their visitors beside a LuaLaTeX document. All geometry is computed in Lua and written as raw PDF path operators; TeX does no arithmetic. The same Lua draws a page as SVG without TeX (`florilegium-svg.lua`, and the playground in `web/`), and the TikZ library draws the same species in pure TikZ under pdfLaTeX. `docs/how-it-works.md` explains the method, and each file's header explains the file.

## Files

| file | what |
|---|---|
| `florilegium.sty` | the TeX layer: options, commands, the shipout hook, tagging. LuaLaTeX only. |
| `florilegium.lua` | the glue: page geometry, the entry points, marks in the text, captions, initials' placement |
| `florilegium-ink.lua` | the drawing core: random numbers, noise, colors, transforms, paths, layers, output |
| `florilegium-flora.lua` | v1.3's hand-designed primitives and visitors |
| `florilegium-grow.lua` | the grown margin: regions, stems, the branch loop, seasons, animation, the motif table |
| `florilegium-authored.lua` | the authored page's hand-placed score |
| `florilegium-species.lua` | the genomes (plants, ferns, visitors, tracery, shells); writes the TikZ tables and `docs/traits.md` |
| `florilegium-native.lua` | the species' organs in Lua, step for step with the TikZ library |
| `florilegium-pgfmath.lua` | pgfmath's arithmetic and pgf's random generator, replayed exactly (LPPL) |
| `florilegium-tracery.lua`, `florilegium-shell.lua` | Gothic windows and headpieces; shells |
| `florilegium-initial.lua` | decorated initials |
| `florilegium-theme-*.lua`, `florilegium-figures.lua` | the themes (geometric, math, shells) and the math figures |
| `florilegium-svg.lua` | a page as SVG without TeX, and its command line |
| `tikzlibraryflorilegium.code.tex`, `tikzlibraryflorilegium.tables.code.tex` | the TikZ library; the tables file is generated |
| `*.tex` in the root | the demo documents, the manual (`florilegium-doc.tex`) and the body text (`text-*.tex`), which describes the method |
| `web/` | the playground, published to GitHub Pages |
| `postscript/` | v1.3's garden in PostScript, with its own README |
| `build.lua`, `testfiles/`, `config-tagging.lua`, `testfiles-tagging/` | the l3build regression tests |
| `tools/` | the checks, the Docker image, the bench, the gallery and zip scripts |
| `README.md`, `docs/` | the front page and the reference; the manual is typeset from them |
| `gallery/` | the pictures; its README says how the hand-made ones are made |
| `PROCESS.md`, `process/` | how the repository was made; historical, never updated with the code |

## Build and check

`docs/building.md` lists every target. Without a local TeX, build the image once (`docker build -t florilegium-tex tools`) and add `RUN=tools/in-docker`.

```sh
make                 # the four PDFs and the manual
make zip             # build/florilegium.zip, for CTAN and the release
make preview         # gallery/*.png
make luacheck        # every Lua file
make check           # the l3build regression tests (~15 s)
make check-tagging   # the tagged-PDF test, in CI's newer TeX Live image
```

Look at the output before calling a change good: `pdftoppm -png -r 100 file.pdf page`, and `-r 300` with `-x -y -W -H` for detail. `scratch/` is git-ignored, for test documents.

| after changing | run |
|---|---|
| anything | `make luacheck`, `make check` |
| something that should draw nothing new | `tools/ident.lua` before and after, then `diff -r`; `make check` passes without saving a log |
| the drawing, on purpose | `l3build save <test>`, look at the pages, and say so in the PR |
| `florilegium-grow.lua` or a theme | `tools/animcheck.lua 1 2 3` |
| what the page path reads from TeX | `tools/svgcheck.sh lua5.3 lua5.4` |
| a trait, a plan or a sampler | `texlua tools/tikztables.lua`, `tools/speciescheck.lua`, `tools/tikzcheck.lua 1 1000` |
| the TikZ library or `florilegium-native.lua` | `tools/tikzcheck.lua draw quick` |
| `florilegium-pgfmath.lua` | `tools/pgfmathcheck.lua 30000` |
| `web/` | `tools/playcheck` |
| one of v1.3's primitives, or v1.3's path in `florilegium-grow.lua` | the same change in `postscript/florilegium.ps`, then `make pscheck` |
| tagging in the `.sty` | `make check-tagging` |
| `docs/` | build the manual and look |
| `.github/` | `uvx --from actionlint-py actionlint`, `uvx zizmor --offline .github/` |

## Public surfaces

Other people's code builds on these. Renaming or changing one is a breaking change, noted in the release.

- `florilegium-svg.lua`'s command line, and `M.page`'s options and returns (ports to the web and to Typst).
- `ink.backend` (`extgstate`, `literal`), `florilegium.sync_transform`, `florilegium.page_marks` and `florilegium.captions` (a ConTeXt module).
- The `.sty`'s options, commands and keys, and the TikZ library's pics and keys, as `docs/usage.md` and `docs/tikz.md` describe them.

## Rules

### Names, versions and licenses

- US spelling everywhere: code, comments, docs, file names.
- Every Lua module but `florilegium.lua` is `florilegium-<part>.lua`, themes too, flat in the root. TeX finds a file by its bare name, the document's folder first, so a generic name loses to a user's own file. LuaTeX looks for `.lua` in `LUAINPUTS`, so a subfolder would need it set wherever LuaLaTeX runs.
- Each module carries `M.version`, and `florilegium.lua` checks at load that every part in `PARTS` and the `.sty` agree, since an old copy in `~/texmf` can meet a newer one. A new module goes into `PARTS` and the preload, `MODULES` in `web/worker.js`, and `FILES` in `tools/zip.py`.
- Every file a user copies carries the copyright line; the `.sty` and the `.ps` carry the full MIT text. `florilegium-pgfmath.lua` is LPPL 1.3c, with clause 6's notices, and anything else that reimplements pgf goes in it. `LICENSE` stays plain MIT text so GitHub recognizes it.
- A borrowed algorithm or published constant gets a credit where it's used and a line under the README's Credits, checked at its source. Trademarks stay out of user-facing names, and data with a license of its own stays out of the package.
- The package's TeX names (`\flo@orn@...`, `\flo@colm`) and the TikZ library's (`\flo@o@...`) must never overlap, since a document can load both.

### Determinism

- Every primitive takes an rng. Layout code draws from `layout` and hands primitives `rng.fork()`, so a change inside a primitive doesn't move the layout. Never iterate a string-keyed table with `pairs()` where the order feeds an rng.
- A new feature draws from a stream of its own (`ink.rng(seed * 7919 + N)`), so pages without it stay byte-identical. Taken: 13, 17, 41, 43, 101, 103, 211, 307, 401, 503, 601, 701, and `docseed * 104729 +` 307, 401, 701.
- The animation replays each `place()` closure several times and restores `rng` and `layout` between. A closure draws only from those two, forking inside itself; otherwise the last frame stops matching the page.
- `density` and `intensity` reduce to the old arithmetic at 1: only multiply or divide by `D`, never add draws on the `D = 1` path.
- A theme's page runs v1.3's code (the `else` of every `if comm` in `florilegium-grow.lua`), and `M.theme(nil)` stays the old path. A theme with `page(g, grow)` follows the animation contract and returns `{ rec, total }`; text in its captions reads left to right on a mirrored page too, and needs no package the user may not load.
- On a mirrored page only `ink.page_transform` reflects. A position handed back in page coordinates (`ink.to_page`) is already reflected and must be mapped back before it's drawn in layout coordinates.

### Parity between TikZ and Lua

- Both engines draw from pgf's generator, which `ink.pgfrng` replays exactly. Every choice is an integer draw, and real traits are pgfmath's own numbers; never key a `BY` on an `R` trait. A new trait or plan goes into `florilegium-species.lua` only, in `TRAITS`' order, and then the tables are written again.
- A change to the library's drawing is made in `florilegium-native.lua` too, step for step and draw for draw, and `tikzcheck.lua draw quick` stays green. Lua parses no pgfmath expression; a number that sits on a threshold comes from `florilegium-pgfmath.lua`.

### PDF and TeX

- Raw literals bypass TikZ's transforms. A primitive inside a TikZ scope reads pgf's matrix itself (`sync_transform`).
- Line widths are absolute bp. Anything that should scale with a motif is a filled shape (`taper`, `ribbon`).
- Never wrap typeset text in `q`...`Q` page literals: `Q` drops the font LuaTeX set inside and the rest of the page's text disappears.
- Output size is the constraint, not time. Measure before adding per-petal detail, and keep level of detail by size on the page.
- Lua keeps only the first value of a call in the middle of a table constructor; assign to locals first.
- Lua inside `\directlua` in the `.sty` has no `%`, `#` or `~`, and a line ending in `\fi` swallows its newline, so end the statement before it with `;`. A `\flo@` name printed from Lua uses the at-letter catcode table.
- `florilegium-svg.lua` translates only the operators ink writes and errors on anything else, so a new operator in ink needs a case there. Anything new the page path reads from TeX needs a stub in `M.page`.

### The TikZ library

- The tables file is generated by `texlua tools/tikztables.lua`. Never edit it.
- `\flo@i \flo@j \flo@n \flo@m \flo@p` are count registers: never `\flo@calc`, `\def` or `\edef` into them. A count register and a macro never share a name.
- Pass sizes to organ macros in a macro they don't use (`\flo@oarg`), never `\flo@t`, which they redraw first.
- A macro name can't end in a digit. `\edef` and `\relax` inside a `\flo@calc` expression break pgfmath, and pgfmath overflows past 16384, so write `*(i/n)`, not `*i/n`.
- `\pgfscope` empties the current path. Build a path inside the scope that fills it.
- The library patches one line of pgf's number parser (`\flo@pgfpatch`) and matches it in TeX Live 2023's and 2026's pgf. Before a release, run the `tikz` checks in `ghcr.io/xu-cheng/texlive-alpine:latest` (`sh tools/tikzcheck-ci.sh`).

### Tests and CI

- The regression tests' logs were recorded with TeX Live 2023 (the Docker image, CI's `l3build` job). Another TeX Live may set the text differently, so record them there. The tagged-PDF test needs TeX Live 2026, and `make check-tagging` runs it in CI's image.
- Every action is pinned to a full commit SHA with its version in a comment. Workflows default to `contents: read`, and checkouts use `persist-credentials: false`.
- latex-action passes no environment variable into its container. Set one in `pre_compile`, or run a script as the compiler (`compiler: sh`).
- Dependabot opens alerts and one grouped version-update PR a month, never one PR per dependency.

### Docs

- The README is the front page: one picture and a few sentences per feature, each linking to its page in `docs/`. Reference material goes in `docs/`, never back into the README. Keep its compelling examples when trimming it.
- Numbers come from `make bench` or are measured and dated. "Procedural" is claimed only for what the code decides. The pure-TikZ claim keeps its caveats: the margin's layout is Lua only, and pure TikZ is slow and needs `extra_mem_top`.
- A change to what grows or how it's drawn updates `docs/species.md` or `docs/how-it-works.md`, and `text-*.tex`.
- The manual is typeset from `docs/*.md` by `docs/manual.lua`, which reads only the constructs its header lists. A new doc goes into `M.CHAPTERS`, a new file a user needs into `tools/zip.py`'s `FILES`.

### The playground

- The browser runs Lua 5.4 and LuaTeX 5.3, so the Lua keeps to both. `worker.js` calls `lua.global.setTop(0)` after each page, or memory runs out after about 35 pages.
- It's a printer's proof and its colophon, not a sidebar of sliders. Cobalt is what is printed, copper what can be taken hold of, and a choice is never told by color alone. The colophon is generated from the state and offers only what the style uses.
- Third-party scripts load only as the bytes pinned beside their URLs (`tools/sri.sh` checks them), and `index.html`'s Content-Security-Policy names them.

### Releases

- Releases are immutable once published, and `v*` tags can't be moved or deleted. Main takes changes through a PR with `lua` and `pdfs` green.
- Set the new version in one commit (the `.sty`'s `\ProvidesPackage` and every `M.version`), run `tools/versioncheck.sh v<version>`, then push an annotated tag. CI builds, attests and attaches the PDFs, the manual, `florilegium.zip` and `florilegium-pdfs.sigstore.json` to a draft release. Never publish the draft before they are all attached; edit it with `gh release edit <tag>`.
- CTAN gets the zip `make zip` builds from the tagged commit. CTAN's `pkgcheck -d florilegium/` on the unpacked zip must report nothing but I0002.
