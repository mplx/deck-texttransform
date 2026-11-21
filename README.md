# @mplx/texttransform

[![test](https://github.com/mplx/deck-texttransform/actions/workflows/test.yml/badge.svg)](https://github.com/mplx/deck-texttransform/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://mplx.github.io/deck-texttransform/)
[![release](https://img.shields.io/github/v/release/mplx/deck-texttransform)](https://github.com/mplx/deck-texttransform/releases/latest)

Text transformations in the style of `printf`'s modifiers for
[Jennifer](https://jennifer-lang.dev/) programs: case conversions (snake,
kebab, camel, pascal, constant, title, swap, leet, ...), slicing, truncation,
trimming and folding, written as a `|`-separated spec such as
`trim|fold|case=kebab`. It composes with `io.sprintf`, which keeps its own
verbs and presentation modifiers.

**[Documentation](https://mplx.github.io/deck-texttransform/)**

## Install

```sh
jvc add @mplx/texttransform
```

This vendors the deck to `vendor/<scope>/texttransform/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`<scope>-texttransform-<version>.tar.gz`) there.

## Usage

```jennifer
import "@mplx/texttransform/" as texttransform;

io.printf("%s=%d\n", texttransform.t("max retries", "case=constant"), 3);   # MAX_RETRIES=3
io.printf("%s\n", texttransform.t("  Crème Brûlée  ", "trim|fold|case=kebab"));   # creme-brulee
```

## Requirements

Jennifer 0.26.0 or newer. No capability: pure string work.

## Development

```sh
tools/check-all.sh                   # the full gate, as CI runs it
jennifer test src/texttransform_test.j      # the test overlay
tools/check-docs.sh                  # docs against the code
tools/pack.sh dist                   # build the release archive
```

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.

`tools/check-headers.sh` checks every source file's SPDX header against
`deck.toml`.
