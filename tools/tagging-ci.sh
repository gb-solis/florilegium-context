#!/bin/sh
# CI's tagging job: the tagged-PDF test (config-tagging.lua) in latex-action's TeX Live, which
# runs this file as its "compiler". On a failure it prints what differs from the saved log.
# latex-action's Alpine image has busybox's diff, which makes no context diffs (l3build's
# default is diff -c)
export diffexe="diff -u"
l3build check -c config-tagging && exit 0
cat build/l3build/test-config-tagging/*.diff
exit 1
