#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Show every case style for a text: jennifer run examples/cases.j "user ID 2go"
 *
 * Without an argument it uses a sample with a camel-case word, an acronym and a
 * digit.
 */
use io;
use os;

import "../src/xformat.j" as xformat;

def text as string init "jenniferDecks parseJSONFiles v2Fast";
if (len(os.ARGS) > 1) {
    $text = os.ARGS[1];
}
io.printf("words: %v\n", xformat.words($text));
for (def style in xformat.CASES) {
    io.printf("%s: %s\n", $style, xformat.toCase($text, $style));
}
io.printf("slug: %s\n", xformat.t($text, "fold|case=kebab|truncate=24"));
