# @mplx/xformat

[![test](https://github.com/mplx/deck-xformat/actions/workflows/test.yml/badge.svg)](https://github.com/mplx/deck-xformat/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://mplx.github.io/deck-xformat/)
[![release](https://img.shields.io/github/v/release/mplx/deck-xformat)](https://github.com/mplx/deck-xformat/releases/latest)

Text transformations in the style of `printf`'s modifiers for
[Jennifer](https://jennifer-lang.dev/) programs: case conversions (snake,
kebab, camel, pascal, constant, title, leet, ...), slicing, truncation,
trimming and folding, written as a `|`-separated spec such as
`trim|fold|case=kebab`. It composes with `io.sprintf`, which keeps its own
verbs and presentation modifiers.

**[Documentation](https://mplx.github.io/deck-xformat/)**

## Install

```sh
jvc add @mplx/xformat
```

This vendors the deck to `vendor/<scope>/xformat/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`<scope>-xformat-<version>.tar.gz`) there.

## Usage

```jennifer
import "@mplx/xformat/" as xformat;

io.printf("%s=%d\n", xformat.t("max retries", "case=constant"), 3);   # MAX_RETRIES=3
io.printf("%s\n", xformat.t("  Crème Brûlée  ", "trim|fold|case=kebab"));   # creme-brulee
```

## Requirements

Jennifer 0.26.0 or newer. No capability: pure string work.

## Development

```sh
tools/check-all.sh                   # the full gate, as CI runs it
jennifer test src/xformat_test.j      # the test overlay
tools/check-docs.sh                  # docs against the code
tools/pack.sh dist                   # build the release archive
```

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.

`tools/check-headers.sh` checks every source file's SPDX header against
`deck.toml`.
