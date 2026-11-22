# Gallery

The pictures in the README and `docs/`. Most are made by `make preview`, `make gallery` and `make animation` (seed 6). The rest are made by hand, as below. Redo the comparisons after a change to the drawing.

- `species-strips.png`, `species-forms.png`, `species-visitors.png`: crops of `specimen-tikz.pdf` pages 1, 3 and 8 at 120 dpi, then `magick -colors 256`.
- `compare-pages.png` and `compare-600dpi.png`: page 2 of `florilegium-grow.tex` built with v1.3 (from `build/bench/v1.3`, which `make bench` unpacks) and with this tree. The first is the margin column at 100 dpi. The second is 827 px squares at 600 dpi of the top flower and the middle of the column, on (235,235,240) with 8 px gaps.
- `detail.png` and `detail-visitors.png`: 300 dpi, 740x600, the margin only, from pages 2 and 1.
- `tracery.png`: `showcase.pdf` page 2 at 100 dpi, `-x 190 -y 90 -W 700 -H 330` (the headpiece, its vine and the heading), then `magick -colors 256`.
- `tracery-windows.png`: `specimen-tikz.pdf` page 9 at 120 dpi, `-x 55 -y 215 -W 880 -H 760` (the two rows of windows), then `magick -colors 256`.
- `shells-ground.png`: page 2 of `testfiles/shells.lvt` built as a plain document, at 150 dpi, `-x 0 -y 1290 -W 705 -H 465`, then `magick -colors 256`.
- `shells-specimens.png`: `specimen-tikz.pdf` page 10 at 120 dpi, crop `900x912+45+205`, then `magick -colors 256`.
- `preview-grown-lastpage.png`: the last page at 60 dpi.
- `playground.png`: `tools/playcheck/shot.mjs`, then `optipng -o2`.
- `social.png`: `make social`, then uploaded by hand under the repository's Settings, Social preview.
- `initials.png`, `preview-postscript.png` and `printed.jpg` show v1.3's hand, which 2.0 keeps there.
