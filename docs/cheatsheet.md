<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# xformat cheatsheet

Every export of `@mplx/xformat`. Guides are listed in
[the introduction](index.md).

```jennifer
import "@mplx/xformat/" as xformat;
```

A bad spec or style throws `Error{kind: "xformat"}`.

## Constants

| Constant | Value | Meaning |
|---|---|---|
| `ERROR_KIND` | `"xformat"` | the kind of every error |
| `ELLIPSIS` | `"..."` | what `truncate=` puts at the end of a cut text |
| `MODIFIERS` | `["case", "slice", "truncate", "trim", "squash", "fold", "reverse"]` | the modifiers a spec may use |
| `CASES` | `["upper", "lower", "title", "sentence", "snake", "kebab", "camel", "pascal", "constant", "dot", "path", "leet"]` | the values `case=` takes |

## Functions

| Function | Returns | Does |
|---|---|---|
| `xformat.t(text as string, spec as string)` | `string` | apply a `\|`-separated spec, left to right |
| `xformat.toCase(text as string, style as string)` | `string` | one case conversion |
| `xformat.words(text as string)` | `list of string` | the words the case conversions see |
