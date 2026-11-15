# florilegium for ConTeXt

Procedurally grown floral page margins, as a ConTeXt module for LMTX (the `context` command
of a ConTeXt LMTX installation, or of TeX Live 2023 and later). Every page grows its own
garden in the wide margin, from Lua that writes PDF paths directly: no images, no MetaPost.
The drawing code is the same as in the LaTeX package, `florilegium.sty`, file for file; the
same seed on the same page layout gives the same garden in both.

![showcase.tex and pages 2–3 of spread.tex, built with ConTeXt](../../../../../gallery/context-preview.png)

*`showcase.tex` (spring, summer, autumn; an initial, flowers at the headings) and pages 2–3
of `spread.tex` (double-sided, the geometric theme on the last page).*

![seed 6 as flora, geometric and math](../../../../../gallery/context-themes.png)

## Install

The module is `t-florilegium.zip`, attached to every release (or built with
`make context-module`, into `build/`). It holds two folders in the layout of a TeX tree:

```
tex/context/third/florilegium/   t-florilegium.mkxl   the module
                                 t-florilegium.lua    its Lua half: the ConTeXt glue
                                 florilegium.lua      the drawing code, shared with LaTeX:
                                 florilegium-*.lua    ink, flora, grow, authored, initial,
                                                      figures, theme-geometric, theme-math
doc/context/third/florilegium/   README.md, LICENSE, examples/
```

Unzip it into a TeX tree that ConTeXt searches and refresh its file database:

```sh
# a ConTeXt LMTX installation (the standalone distribution): its tree for modules
cd /path/to/context/tex/texmf-modules && unzip /path/to/t-florilegium.zip
mtxrun --generate

# or your own tree, for TeX Live's ConTeXt as well
mkdir -p ~/texmf && cd ~/texmf && unzip /path/to/t-florilegium.zip
mtxrun --generate
```

Then `\usemodule[florilegium]` works in any document. `mtxrun --find-file t-florilegium.mkxl`
shows the copy ConTeXt will load. The module loads the Lua files from its own folder, so a
copy of the LaTeX package elsewhere in the same tree (`tex/lualatex/florilegium`) does not
interfere; a module whose files come from two releases stops with a message saying so.

Without installing, a document can name the folder: `context --path=/path/to/tex/context/third/florilegium doc.tex`.

## Usage

```tex
\usemodule[florilegium][composition=grown]

\setupflorilegium
  [composition=grown,   % authored (default) | grown
   margin=yes,          % no: no margin, only \florilegiumdraw and ornaments
   visitors=yes,        % no: no butterflies, bees, snails or birds
   sections=no,         % yes: a flower beside every \section and \subsection
   aging=no,            % yes: spring on the first page, autumn on the last
   theme=,              % geometric | math | any florilegium-theme-<name>.lua
   density=1,           % 0.05 (a single vine) .. 1
   intensity=1,         % 0.3 (faint) .. 1
   seed=]               % a fixed seed instead of the page number

\definecolor[ink][h=5B2A1F]      % the hue of the whole palette
\definecolor[accent][h=B4662F]   % the copper of the hairlines

\starttext
\florilegiuminitial[5]{E}very page grows its own garden ...
... \florilegiumbloom[lily] ...   % a flower beside this line
\florilegiumtheme{geometric}      % from this page on
\florilegiumage{0.8}              % the season of the following pages
\florilegiumornament[size=2em,ink=5B2A1F,angle=20,seed=random]{flower}
\florilegiumtextend               % the text ends here: the garden grows below it
\stoptext
```

`composition`, `margin` and `sections` are read at `\starttext`; everything else takes
effect when it is set. `\usemodule[florilegium][key=value]` takes the same keys, and
`context --florilegiumseed=7 doc.tex` fixes the seed from the command line. The garden grows
in the wider side margin, mirrored when that is the right one (double-sided documents).
Aging needs the page count of the previous run; `context` reruns by itself until it has it.

Primitives anywhere, in a picture whose coordinates are centimeters from its lower-left
corner (`x`, `y` and `rotate` are evaluated by Lua, so `x=1+0.7*(\recurselevel-1)` works
inside a `\dorecurse`), or at the current point:

```tex
\startflorilegiumpicture[width=19cm,height=6cm,frame=yes]
  \florilegiumdraw[x=3,y=3]{flower}{1.9}
  \florilegiumdraw[x=8,y=3,rotate=-15]{leaf}{4, {lobes=4, depth=0.5}}
  \florilegiumdraw[x=13,y=3]{ghost}{"flower", {s=1.9}}
  \florilegiumlabel[x=8,y=0.5]{flower, leaf, ghost}
  \florilegiumline{15.4}{1.45}{18.6}{1.6}
\stopflorilegiumpicture
```

## Examples

`examples/` has the module's demo documents; each describes what it shows:

| file | what |
|---|---|
| `florilegium.tex`, `florilegium-grow.tex` | the authored and the grown composition, describing themselves (`text-*.tex`) |
| `showcase.tex` | initials, flowers at the headings, `\florilegiumbloom`, the seasons |
| `spread.tex` | a double-sided document; its last page switches to the geometric theme |
| `specimen.tex`, `specimen-geometric.tex` | one of every primitive, drawn with `\florilegiumdraw` |
| `ornaments.tex` | `\florilegiumornament` |
| `gallery.tex`, `animation.tex` | one page per seed or per frame (the repository's `tools/gallery.py --engine context`, `tools/animate.py --engine context`) |
| `env-florilegium.tex` | their look: the LaTeX package's page (A4, 11 pt Latin Modern, a 68 mm margin), article's headings, amsthm's blocks |

With the module installed: copy the folder somewhere and run `context florilegium-grow.tex`.

## From the LaTeX package

| LaTeX | ConTeXt |
|---|---|
| `\usepackage[grown,sections,aging]{florilegium}` | `\usemodule[florilegium][composition=grown,sections=yes,aging=yes]` |
| `nomargin`, `novisitors` | `margin=no`, `visitors=no` |
| `theme=`, `density=`, `intensity=` | the same keys |
| `\def\florilegiumseed{7}` | `seed=7`, or `context --florilegiumseed=7` |
| `\definecolor{ink}{HTML}{5B2A1F}` | `\definecolor[ink][h=5B2A1F]` |
| `twoside` + `geometry` | `\setuppagenumbering[alternative=doublesided]` + `\setuplayout[backspace=..,cutspace=..]` |
| `\florilegiumdraw{leaf}{2}` in a TikZ scope | `\florilegiumdraw[x=..,y=..,rotate=..]{leaf}{2}`, in a `\startflorilegiumpicture` or at the current point |
| aging: two `lualatex` runs | one `context` command |

`\florilegiumbloom`, `\florilegiumage`, `\florilegiumtheme`, `\florilegiuminitial`,
`\florilegiuminitialfont`, `\florilegiumtextend`, `\florilegiumframe` and
`\florilegiumornament` are the same commands.

## How it works

The garden is the page's background overlay (`\setupbackgrounds[page][background=florilegium]`;
a document that sets its own page background should list both, `background={florilegium,mine}`).
ConTeXt builds it when the page's text, header and footer are already in `\pagebox`, so
the overlay reads the layout (`\texthoffset`, `\topspace`, the header and footer areas),
walks `\pagebox` for the marks the text left (ConTeXt's `userdefined` whatsits), and calls
the shared growth code, exactly as the LaTeX shipout hook does with `\ShipoutBox`. The
drawing goes into the page as one `originliteral`; opacity and multiply go into the page
resources with `lpdf.adddocumentextgstate`. Everything on the Lua side is in
`thirddata.florilegium`. The math theme's symbols and equations are ConTeXt boxes placed
by their TikZ anchors; a tilted one is turned inside a form XObject of its own, because
rotated text in the page's own content stream made the backend lose its place for the rest
of the page. A double-sided document ends on an even page in ConTeXt; that blank page stays
blank.

## In the repository

The module's own files are in `context/`, already in this layout (`tex/…` and `doc/…`);
the drawing code stays once, in the repository's root, beside the LaTeX package, and
`tools/context-module.sh` copies it in. `make context` builds the examples against the
assembled tree (`build/context/*.pdf`), as an installed module would load them.

## License

MIT, © 2026 Kevin Raymond: `LICENSE`, and in full at the head of `t-florilegium.mkxl`.
