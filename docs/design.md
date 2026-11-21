<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Design

## Scope

The deck transforms text by a spec written in the style of `printf`'s
modifiers: `t(text, spec)` applies a `|`-separated list of modifiers
(`case=`, `slice=`, `truncate=`, `trim`, `squash`, `fold`, `reverse`) left to
right. `toCase` converts to one of the `CASES`, and `words` shows how the
case conversions split a text.

It deliberately leaves out the rest of the original "super-sprintf" idea:

- **Markdown modifiers** (`md=bold`, `md=link(...)`, tables): building
  markdown is a markdown library's job.
- **Serialisation modifiers** (`json=`, `xml=`, `yaml=`): the libraries
  exist and do it properly.
- **Domain spellings** such as `null=sql`: they leak one domain's
  conventions into a general tool.
- **An `xprintf` of its own**: see Decisions.

## Decisions

- **A deck, not a core feature.** `printf`'s modifiers shape how a value is
  printed (`%d|base=2` writes 5 as `101`) and never change the value.
  Transformations that do (`case=upper`, `slice=0:5`) were proposed for the
  format language and rejected for the core as mission creep: once one
  transform is in, every string operation becomes a candidate modifier and
  the format spec grows a parallel API to the libraries (`jennifer`'s
  technical notes, "printf data-transformation modifiers"). A deck is opt-in,
  so it can bring back the `case=` and `slice=` parts without that cost.
- **The name says transformation.** `printf` presents, this deck transforms;
  a name with "format" in it blurred that line. "text-transform" is the CSS
  property for the same job (`uppercase`, `capitalize`), so the name reads
  without explanation.
- **A function that composes with `io.sprintf`.** A user function cannot
  take a variable number of arguments of mixed types (no variadics, no
  `any`, homogeneous lists), so the deck cannot offer its own
  `printf`. `t` transforms one value into a plain string, and the real
  `io.sprintf` keeps every verb and presentation modifier on its typed
  arguments. Variadic user functions are an open idea in `jennifer`'s
  horizon (DRAFT#32); this deck is cited there as the case that needs them.
- **The modifier syntax of `printf`.** `name` or `name=value`, joined by
  `|`, so a spec reads like a format modifier list. Names are case
  sensitive.
- **Strict specs.** An empty spec, an empty or unknown modifier, a value on a
  modifier that takes none or none on `case`, `slice` or `truncate`, a
  malformed number, and a slice bound outside the text all throw. Nothing
  is guessed. `trim`'s value is the one optional value: bare trims both
  sides, `trim=left` / `trim=right` one side, anything else is an error.
- **Word splitting for the joined cases.** Any character that is neither a
  letter (`\p{L}`) nor a decimal digit (`\p{Nd}`) separates words; a word also
  ends where a lower-case letter or a digit meets an upper-case one
  (`fooBar`, `v2Go`) and where an upper-case run meets a capitalised word
  (`HTTPServer` is `HTTP` and `Server`). Digits stay with the word before
  them. Case is what `strings.upper` / `strings.lower` change, so letters of
  any script count, and a script without case is one word per run.
- **Two families of case styles.** `upper`, `lower`, `title`, `sentence`,
  `swap` and `leet` keep the text's characters and spacing. `snake`, `kebab`,
  `constant`, `dot`, `path`, `camel` and `pascal` rebuild the text from its
  words, so an acronym becomes `Http` in camel and pascal case.
- **Characters, not bytes or code points.** A character is a code point
  that is not a combining mark plus the marks after it (`\P{M}\p{M}*`), so
  a decomposed `é` is one character everywhere: in `words`, the case
  styles, `slice`, `truncate` and `reverse`. Full UAX #29 grapheme clusters
  (emoji sequences, flags) need tables the core does not have yet (M30.19
  in the interpreter's roadmap). `slice` and `truncate` count characters.
  `slice` is half-open with either side optional and negative bounds from
  the end. `truncate=N` counts `ELLIPSIS`
  (`...`) in N, so N must be more than 3.
- **Exported vocabularies.** `MODIFIERS`, `CASES`, `ELLIPSIS` and
  `ERROR_KIND` are constants, so a program can validate or list choices
  without copying them.

## Errors

Every error is a plain `Error` of kind `"texttransform"` (`ERROR_KIND`) with a
message starting `texttransform: ` that names the offending part. The deck
reports only problems with the caller's spec, so there are no fields to
carry and no struct.

## Security and limits

The deck is pure text processing: no capability, no I/O. Input is the
caller's own. There are no size caps; the cost is linear in the text's
length, with a regular-expression test per character in `words` and the
case checks. Slice bounds are limited to nine digits.

## Testing and validation

`src/texttransform_test.j` covers `words` (acronyms, digits, separators,
non-Latin scripts), every case style, slices (negative and empty bounds, out
of range), truncation, the other modifiers, chains, every strict-spec error,
and composition with `io.sprintf`. `examples/cases.j` prints every case style
for a sample text and runs in CI.

## Known limitations and open questions

- Casing is `strings.upper` / `strings.lower`, with no locale-specific
  rules.
- `leet` maps a fixed set of nine letters.
- If variadic user functions land, an `xprintf` could take the spec inline;
  until then `t` with `io.sprintf` is the form.

## Dependencies on the interpreter

- The floor is `>=0.26.0`, the floor of every new deck.
- `strings.fold` (for `fold`), `strings.chars`, and `\p{L}` / `\p{Nd}` in
  `regex`. The deck needs no capability.
