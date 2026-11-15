# florilegium for ConTeXt

Procedurally grown floral page margins, as a ConTeXt module for LMTX. Every page grows its
own garden in the wide margin, from Lua that writes PDF paths directly: no images, no
MetaPost. The drawing code is that of the LaTeX package, `florilegium.sty`; the module
replaces only the part that talks to TeX.

This is a fork of [florilegium](https://github.com/kevinraymond/florilegium), on its
release 2.0.1. The branch `context` adds the module in this folder and a few lines in three
of the drawing files (`florilegium.lua`, `florilegium-ink.lua`, `florilegium-initial.lua`)
that let them run without LaTeX.

## Credits

- **florilegium**, all of its drawing code and the LaTeX package: Kevin Raymond,
  <https://github.com/kevinraymond/florilegium>.
- **The ConTeXt port**: `t-florilegium.mkxl`, `t-florilegium.lua`, the examples and the first
  version of this README come from the port of florilegium 1.3 that Luis Montgomery published
  at <https://github.com/montylucho/florilegium>.
- **This fork**: Gabriel Solis moved the port to florilegium 2.0.1 and maintains it. The
  branch's history lists every change since the port.

## Install

The module is every `florilegium*.lua` from the repository's root together with the two
files `context/t-florilegium.mkxl` and `context/t-florilegium.lua`, all in one folder of a
TeX tree that ConTeXt searches:

```sh
# a ConTeXt LMTX installation (the standalone distribution): its tree for modules
dest=/path/to/context/tex/texmf-modules/tex/context/third/florilegium
mkdir -p "$dest"
cp florilegium*.lua context/t-florilegium.mkxl context/t-florilegium.lua "$dest"/
mtxrun --generate
```

Then `\usemodule[florilegium]` works in any document, and `mtxrun --find-file
t-florilegium.mkxl` shows the copy ConTeXt will load. A module whose files come from two
releases stops with a message saying so.

Without installing, a document can name the two folders of a checkout:
`context --path=/path/to/florilegium-context,/path/to/florilegium-context/context doc.tex`.

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
   seed=,               % a fixed seed instead of the page number
   inkcolor=,           % a color's name: the hue of the whole palette
   accentcolor=]        % a color's name: the copper of the hairlines

\definecolor[sepia][h=5B2A1F]
\setupflorilegium[inkcolor=sepia]

\starttext
\florilegiuminitial[5]{E}very page grows its own garden ...
... \florilegiumbloom[lily] ...   % a flower beside this line
\florilegiumtheme{geometric}      % from this page on
\florilegiumage{0.8}              % the season of the following pages
\florilegiumornament[size=2em,ink=5B2A1F,angle=20,seed=random]{flower}
\florilegiumtextend               % the text ends here: the garden grows below it
\stoptext
```

`margin` and `sections` are read at `\starttext`; everything else takes effect when it is
set. `\usemodule[florilegium][key=value]` takes the same keys, and
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
| `gallery.tex`, `animation.tex` | one page per seed (`context --florilegiumseed=7 gallery.tex`) or per frame of a garden's growth |
| `env-florilegium.tex` | their look: the LaTeX package's page (A4, 11 pt Latin Modern, a 68 mm margin), article's headings, amsthm's blocks |

With the module installed: copy the folder somewhere and run `context florilegium-grow.tex`.
The examples were written for florilegium 1.3; they build with 2.0.1, but their text does not
describe what 2.0 added (the species of the grown margin).

## From the LaTeX package

| LaTeX | ConTeXt |
|---|---|
| `\usepackage[grown,sections,aging]{florilegium}` | `\usemodule[florilegium][composition=grown,sections=yes,aging=yes]` |
| `nomargin`, `novisitors` | `margin=no`, `visitors=no` |
| `theme=`, `density=`, `intensity=` | the same keys |
| `\def\florilegiumseed{7}` | `seed=7`, or `context --florilegiumseed=7` |
| `\definecolor{ink}{HTML}{5B2A1F}` | `\definecolor[sepia][h=5B2A1F]` + `inkcolor=sepia` (and `accentcolor=` for `accent`) |
| `twoside` + `geometry` | `\setuppagenumbering[alternative=doublesided]` + `\setuplayout[backspace=..,cutspace=..]` |
| `\florilegiumdraw{leaf}{2}` in a TikZ scope | `\florilegiumdraw[x=..,y=..,rotate=..]{leaf}{2}`, in a `\startflorilegiumpicture` or at the current point |
| aging: two `lualatex` runs | one `context` command |

`\florilegiumbloom`, `\florilegiumage`, `\florilegiumtheme`, `\florilegiuminitial`,
`\florilegiuminitialfont`, `\florilegiumtextend`, `\florilegiumframe` and
`\florilegiumornament` are the same commands.

## How it works

The garden is an overlay among the page's backgrounds. At `\starttext` the module adds it
after the ones the document has set, so it is drawn on top of them; a document that sets the
page's background after `\starttext` should list it too, `background={mine,florilegium}`.
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

## What is missing

- The TikZ library of florilegium 2.0 (`\usetikzlibrary{florilegium}`) has no counterpart here.
- The numbers given to `\florilegiumage`, `density`, `intensity`, `seed` and an ornament's
  `angle` are not checked as the LaTeX package checks them, and the drawing code's warnings
  (a `\florilegiumbloom` that names no motif, for one) do not reach the log.
- `sections=yes` sets the `deeptextcommand` of `section` and `subsection`, in place of one
  the document may have set.
- A page without a single glyph on it (a full-page figure and no header or page number) is
  taken for the blank page that ends a double-sided document, and gets no garden.
- The math theme sets each of its symbols in a body font of its own size, and ConTeXt logs a
  notice for every new size.

## License

MIT, © 2026 Kevin Raymond: `LICENSE` in the repository's root, and in full at the head of
`t-florilegium.mkxl`.
