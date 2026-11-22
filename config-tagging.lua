-- config-tagging.lua -- l3build's settings for the tagged-PDF test (testfiles-tagging/):
-- the structure a tagged document gets from the package, as show-pdf-tags reads it from the
-- PDF (\SHOWPDFTAGS). It needs a newer LaTeX than TeX Live 2023's, so it is a config of its
-- own and runs in CI's tagging job (latex-action's TeX Live), not with `l3build check`:
--   l3build check -c config-tagging
--   l3build save -c config-tagging tagging     after an intended change
-- Locally, in the image CI uses: make check-tagging
-- Copyright (c) 2026 Kevin Raymond. MIT License: see LICENSE or florilegium.sty.

testfiledir = "./testfiles-tagging"
