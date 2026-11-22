# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Text transformations in the style of `printf`'s modifiers: a `|`-separated
 * list such as `case=pascal|truncate=20`, applied left to right to a string.
 *
 * `printf`'s modifiers shape how a value is printed and never change it;
 * transformations that do (`case=upper`, `slice=0:5`) were left out of the
 * format language on purpose. This deck brings them back as a function that
 * composes with the real `io.sprintf`, so every verb and presentation
 * modifier keeps working on its typed argument:
 *
 *   io.printf("%s: %s\n", texttransform.t($key, "case=constant"), texttransform.t($title, "truncate=30"));
 *
 * A character is what a reader sees as one: a letter with the combining
 * marks that follow it (`e` + U+0301 is one `é`), so slicing, truncating and
 * reversing never strip an accent from its letter.
 *
 * A spec is strict: an unknown modifier, a missing or malformed value, or a
 * slice outside the text throws `Error{kind: "texttransform"}`.
 *
 * @module texttransform
 * @example
 *   texttransform.t("HTTPServer2Go", "case=snake");   # "http_server2_go"
 *   texttransform.t("hello world", "case=pascal");    # "HelloWorld"
 */
use convert;
use lists;
use maps;
use regex;
use strings;

/** The `kind` of every error the deck throws. */
export def const ERROR_KIND as string init "texttransform";

/** The modifiers a spec may use. */
export def const MODIFIERS as list of string init [
    "case",
    "slice",
    "truncate",
    "trim",
    "squash",
    "fold",
    "reverse"
];

/** The values `case=` takes. */
export def const CASES as list of string init [
    "upper",
    "lower",
    "title",
    "sentence",
    "snake",
    "kebab",
    "camel",
    "pascal",
    "constant",
    "dot",
    "path",
    "swap",
    "leet"
];

/** What `truncate=N` puts at the end of a cut text, counted in N. */
export def const ELLIPSIS as string init "...";

/** The letters `case=leet` replaces, either case, and their digits. */
def const LEET as map of string to string init {
    "a": "4",
    "b": "8",
    "e": "3",
    "g": "6",
    "i": "1",
    "o": "0",
    "s": "5",
    "t": "7",
    "z": "2"
};

/**
 * Throw an texttransform error.
 *
 * @param message {string} what is wrong, without the prefix
 */
func fail(message as string) {
    throw Error{kind: ERROR_KIND, message: "texttransform: " + $message};
}

/**
 * A text's characters: each code point that is not a combining mark, with
 * the marks that follow it. Marks at the very start, with no character
 * before them, form a character of their own. Not full Unicode grapheme
 * clusters: emoji sequences and flags are still several characters.
 *
 * @param text {string} the text
 * @return {list of string} the characters, in order
 */
func chars(text as string) {
    def out as list of string init [];
    for (def m in regex.findAll('\P{M}\p{M}*|\p{M}+', $text)) {
        $out[] = $m.text;
    }
    return $out;
}

/**
 * Whether a character is a letter (any script), with any marks on it.
 *
 * @param c {string} one character
 * @return {bool} true for a letter
 */
func isLetter(c as string) {
    return regex.matches('^\p{L}\p{M}*$', $c);
}

/**
 * Whether a character is a decimal digit (any script), with any marks on it.
 *
 * @param c {string} one character
 * @return {bool} true for a digit
 */
func isDigit(c as string) {
    return regex.matches('^\p{Nd}\p{M}*$', $c);
}

/**
 * Whether a character is an upper-case letter.
 *
 * @param c {string} one character
 * @return {bool} true when it has a lower case different from itself
 */
func isUpper(c as string) {
    return strings.lower($c) != $c and strings.upper($c) == $c;
}

/**
 * Whether a character is a lower-case letter.
 *
 * @param c {string} one character
 * @return {bool} true when it has an upper case different from itself
 */
func isLower(c as string) {
    return strings.upper($c) != $c and strings.lower($c) == $c;
}

/**
 * Split a text into words, as the case conversions see them: any character
 * that is neither a letter nor a digit separates words, and a word also ends
 * where a lower-case letter or a digit is followed by an upper-case one
 * (`fooBar`, `v2Go`) and where an upper-case run meets a capitalised word
 * (`HTTPServer` is `HTTP` and `Server`). Digits stay with the word they
 * follow.
 *
 * @param text {string} the text
 * @return {list of string} the words, in order; empty for a text with none
 * @example
 *   texttransform.words("HTTPServer2Go-fast");   # ["HTTP", "Server2", "Go", "fast"]
 */
export func words(text as string) {
    def cs as list of string init chars($text);
    def out as list of string init [];
    def cur as list of string init [];
    def n as int init len($cs);
    for (def i in 0..$n) {
        def c as string init $cs[$i];
        if (not isLetter($c) and not isDigit($c)) {
            if (len($cur) > 0) {
                $out[] = strings.join($cur, "");
                $cur = [];
            }
            continue;
        }
        if (len($cur) > 0) {
            def p as string init $cur[len($cur) - 1];
            def nextLower as bool init $i + 1 < $n and isLower($cs[$i + 1]);
            if (isUpper($c) and
                (isLower($p) or isDigit($p) or (isUpper($p) and $nextLower))) {
                $out[] = strings.join($cur, "");
                $cur = [];
            }
        }
        $cur[] = $c;
    }
    if (len($cur) > 0) {
        $out[] = strings.join($cur, "");
    }
    return $out;
}

/**
 * A word with its first character upper case and the rest lower case.
 *
 * @param w {string} the word
 * @return {string} the word, capitalised
 */
func capital(w as string) {
    if ($w == "") {
        return "";
    }
    def cs as list of string init chars($w);
    return strings.upper($cs[0]) + strings.lower(strings.join($cs[1..], ""));
}

/**
 * Words joined with a separator, each lower or upper case.
 *
 * @param text {string} the text
 * @param sep {string} the separator
 * @param upper {bool} upper case instead of lower
 * @return {string} the joined words
 */
func joined(text as string, sep as string, upper as bool) {
    def out as list of string init [];
    for (def w in words($text)) {
        if ($upper) {
            $out[] = strings.upper($w);
        } else {
            $out[] = strings.lower($w);
        }
    }
    return strings.join($out, $sep);
}

/**
 * Words capitalised and joined without a separator; the first one lower case
 * for camel case.
 *
 * @param text {string} the text
 * @param camel {bool} the first word lower case
 * @return {string} the joined words
 */
func capitalised(text as string, camel as bool) {
    def out as list of string init [];
    for (def w in words($text)) {
        if ($camel and len($out) == 0) {
            $out[] = strings.lower($w);
        } else {
            $out[] = capital($w);
        }
    }
    return strings.join($out, "");
}

/**
 * Title case: every word's first letter upper case, the rest lower case;
 * the characters between words are kept.
 *
 * @param text {string} the text
 * @return {string} the text in title case
 */
func titled(text as string) {
    def out as list of string init [];
    def start as bool init true;
    for (def c in chars($text)) {
        if (isLetter($c) or isDigit($c)) {
            if ($start) {
                $out[] = strings.upper($c);
            } else {
                $out[] = strings.lower($c);
            }
            $start = false;
        } else {
            $out[] = $c;
            $start = true;
        }
    }
    return strings.join($out, "");
}

/**
 * Sentence case: the first letter upper case, everything else lower case.
 *
 * @param text {string} the text
 * @return {string} the text in sentence case
 */
func sentence(text as string) {
    def out as list of string init [];
    def done as bool init false;
    for (def c in chars(strings.lower($text))) {
        if (not $done and isLetter($c)) {
            $out[] = strings.upper($c);
            $done = true;
        } else {
            $out[] = $c;
        }
    }
    return strings.join($out, "");
}

/**
 * Swap case: upper-case letters lower case and lower-case ones upper case;
 * everything else, a letter without case included, kept.
 *
 * @param text {string} the text
 * @return {string} the text with its case swapped
 */
func swapped(text as string) {
    def out as list of string init [];
    for (def c in chars($text)) {
        if (isUpper($c)) {
            $out[] = strings.lower($c);
        } elseif (isLower($c)) {
            $out[] = strings.upper($c);
        } else {
            $out[] = $c;
        }
    }
    return strings.join($out, "");
}

/**
 * Leet: the letters of `LEET` replaced by their digits, any case.
 *
 * @param text {string} the text
 * @return {string} the text in leet
 */
func leet(text as string) {
    def out as list of string init [];
    for (def c in chars($text)) {
        def k as string init strings.lower($c);
        if (maps.has(LEET, $k)) {
            $out[] = LEET[$k];
        } else {
            $out[] = $c;
        }
    }
    return strings.join($out, "");
}

/**
 * Convert a text to one of the `CASES`.
 *
 * @param text {string} the text
 * @param style {string} one of `CASES`
 * @return {string} the converted text
 * @throws {Error} kind `"texttransform"` for an unknown style
 * @example
 *   texttransform.toCase("user ID", "camel");   # "userId"
 */
export func toCase(text as string, style as string) {
    if ($style == "upper") {
        return strings.upper($text);
    }
    if ($style == "lower") {
        return strings.lower($text);
    }
    if ($style == "title") {
        return titled($text);
    }
    if ($style == "sentence") {
        return sentence($text);
    }
    if ($style == "snake") {
        return joined($text, "_", false);
    }
    if ($style == "kebab") {
        return joined($text, "-", false);
    }
    if ($style == "constant") {
        return joined($text, "_", true);
    }
    if ($style == "dot") {
        return joined($text, ".", false);
    }
    if ($style == "path") {
        return joined($text, "/", false);
    }
    if ($style == "camel") {
        return capitalised($text, true);
    }
    if ($style == "pascal") {
        return capitalised($text, false);
    }
    if ($style == "swap") {
        return swapped($text);
    }
    if ($style == "leet") {
        return leet($text);
    }
    fail("a case is one of " + strings.join(CASES, ", ") + ", got \"" + $style + "\"");
    return "";
}

/**
 * A slice bound: an integer, negative from the end, or empty for the
 * default.
 *
 * @param text {string} the bound as written
 * @param n {int} the text's length in characters
 * @param missing {int} the default
 * @return {int} the position, 0 to n
 */
func bound(text as string, n as int, missing as int) {
    if ($text == "") {
        return $missing;
    }
    if (not regex.matches('^-?[0-9]{1,9}$', $text)) {
        fail("a slice bound is an integer, got \"" + $text + "\"");
    }
    def at as int init convert.toInt($text);
    if ($at < 0) {
        $at = $n + $at;
    }
    if ($at < 0 or $at > $n) {
        fail("the slice bound " + $text + " is outside a text of " + convert.toString($n) +
            " characters");
    }
    return $at;
}

/**
 * `slice=START:END` on characters: half-open, either side empty for the
 * start or end, negative from the end.
 *
 * @param text {string} the text
 * @param spec {string} `START:END`
 * @return {string} the slice
 */
func sliced(text as string, spec as string) {
    def parts as list of string init strings.split($spec, ":");
    if (len($parts) != 2) {
        fail("slice is START:END, got \"" + $spec + "\"");
    }
    def cs as list of string init chars($text);
    def n as int init len($cs);
    def from as int init bound($parts[0], $n, 0);
    def upto as int init bound($parts[1], $n, $n);
    if ($from > $upto) {
        fail("slice " + $spec + " starts after it ends");
    }
    return strings.join($cs[$from..$upto], "");
}

/**
 * `truncate=N`: a text longer than N characters cut so that it, with
 * `ELLIPSIS`, is N long.
 *
 * @param text {string} the text
 * @param spec {string} N, at least the ellipsis' length plus one
 * @return {string} the text, at most N characters
 */
func truncated(text as string, spec as string) {
    if (not regex.matches('^[0-9]{1,9}$', $spec)) {
        fail("truncate is a number of characters, got \"" + $spec + "\"");
    }
    def most as int init convert.toInt($spec);
    def e as int init len(chars(ELLIPSIS));
    if ($most <= $e) {
        fail("truncate is more than " + convert.toString($e) + " characters, got " + $spec);
    }
    def cs as list of string init chars($text);
    if (len($cs) <= $most) {
        return $text;
    }
    return strings.join($cs[0..$most - $e], "") + ELLIPSIS;
}

/**
 * Apply one modifier.
 *
 * @param text {string} the text
 * @param name {string} the modifier
 * @param value {string} its value, `""` for none
 * @param has {bool} whether `=value` was written
 * @return {string} the transformed text
 */
func modify(text as string, name as string, value as string, has as bool) {
    if (not lists.contains(MODIFIERS, $name)) {
        fail("unknown modifier \"" + $name + "\"; known: " + strings.join(MODIFIERS, ", "));
    }
    def takesValue as bool init $name == "case" or $name == "slice" or $name == "truncate";
    if ($takesValue and not $has) {
        fail($name + " needs a value: " + $name + "=...");
    }
    # trim's value is optional: both sides without one
    if (not $takesValue and $has and $name != "trim") {
        fail($name + " takes no value");
    }
    if ($name == "case") {
        return toCase($text, $value);
    }
    if ($name == "slice") {
        return sliced($text, $value);
    }
    if ($name == "truncate") {
        return truncated($text, $value);
    }
    if ($name == "trim") {
        if (not $has) {
            return strings.trim($text);
        }
        if ($value == "left") {
            return strings.trimLeft($text);
        }
        if ($value == "right") {
            return strings.trimRight($text);
        }
        fail("trim is trim, trim=left or trim=right, got trim=\"" + $value + "\"");
    }
    if ($name == "squash") {
        return strings.trim(regex.replace('\s+', $text, " "));
    }
    if ($name == "fold") {
        return strings.fold($text);
    }
    if ($name == "reverse") {
        return strings.join(lists.reverse(chars($text)), "");
    }
    return $text;
}

/**
 * Transform a text by a spec: `|`-separated modifiers, applied left to
 * right, in `printf`'s modifier style.
 *
 * | Modifier | Does |
 * | --- | --- |
 * | `case=STYLE` | one of `CASES` (see `toCase`) |
 * | `slice=START:END` | characters START to END, half-open; either side may be empty, negative counts from the end |
 * | `truncate=N` | at most N characters, ending in `ELLIPSIS` when cut |
 * | `trim` | leading and trailing whitespace removed; `trim=left` only leading, `trim=right` only trailing |
 * | `squash` | every whitespace run one space, trimmed |
 * | `fold` | Latin diacritics and ligatures folded (`strings.fold`) |
 * | `reverse` | the characters in reverse order |
 *
 * @param text {string} the text
 * @param spec {string} the modifiers, such as `case=kebab|truncate=20`
 * @return {string} the transformed text
 * @throws {Error} kind `"texttransform"` for an empty spec, an unknown modifier, a
 *   missing or malformed value, or a slice outside the text
 * @example
 *   texttransform.t("  Crème Brûlée  ", "trim|fold|case=kebab");   # "creme-brulee"
 */
export func t(text as string, spec as string) {
    if (strings.trim($spec) == "") {
        fail("a spec names at least one modifier");
    }
    def out as string init $text;
    for (def part in strings.split($spec, "|")) {
        def name as string init $part;
        def value as string init "";
        def has as bool init false;
        def eq as int init strings.indexOf($part, "=");
        if ($eq >= 0) {
            $name = $part[..$eq];
            $value = $part[$eq + 1..];
            $has = true;
        }
        if ($name == "") {
            fail("an empty modifier in \"" + $spec + "\"");
        }
        $out = modify($out, $name, $value, $has);
    }
    return $out;
}
