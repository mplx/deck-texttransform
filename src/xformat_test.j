# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * White-box tests for the entry module: jennifer test src/xformat_test.j
 */
use io;
use testing;

/** Fail a test whose call should have thrown. */
func missed() {
    throw Error{kind: "test", message: "the call did not fail"};
}

/**
 * The message of the error a spec throws, or "" when it does not throw.
 *
 * @param text {string} the text
 * @param spec {string} the spec
 * @return {string} the message
 */
func errorOf(text as string, spec as string) {
    try {
        t($text, $spec);
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        return $e.message;
    }
    return "";
}

func testWords() {
    testing.assertEqual(words("HTTPServer2Go-fast"), ["HTTP", "Server2", "Go", "fast"]);
    testing.assertEqual(words("helloWorld"), ["hello", "World"]);
    testing.assertEqual(words("XMLHttpRequest"), ["XML", "Http", "Request"]);
    testing.assertEqual(
        words("snake_case and kebab-case"),
        ["snake", "case", "and", "kebab", "case"]);
    testing.assertEqual(words("v2Go v10"), ["v2", "Go", "v10"]);
    testing.assertEqual(words("ABC"), ["ABC"]);
    testing.assertEqual(words("Größe änderNÄCHSTE"), ["Größe", "änder", "NÄCHSTE"]);
    testing.assertEqual(words("漢字 kanji"), ["漢字", "kanji"]);
    testing.assertEqual(words(" -- "), []);
    testing.assertEqual(words(""), []);
}

func testCases() {
    def text as string init "jenniferDecks parseJSONFiles v2Fast";
    testing.assertEqual(t($text, "case=upper"), "JENNIFERDECKS PARSEJSONFILES V2FAST");
    testing.assertEqual(t($text, "case=lower"), "jenniferdecks parsejsonfiles v2fast");
    testing.assertEqual(t($text, "case=title"), "Jenniferdecks Parsejsonfiles V2fast");
    testing.assertEqual(t("the QUICK-brown fox", "case=title"), "The Quick-Brown Fox");
    testing.assertEqual(t("  the QUICK brown fox.", "case=sentence"), "  The quick brown fox.");
    testing.assertEqual(t($text, "case=sentence"), "Jenniferdecks parsejsonfiles v2fast");
    testing.assertEqual(t($text, "case=snake"), "jennifer_decks_parse_json_files_v2_fast");
    testing.assertEqual(t($text, "case=kebab"), "jennifer-decks-parse-json-files-v2-fast");
    testing.assertEqual(t($text, "case=camel"), "jenniferDecksParseJsonFilesV2Fast");
    testing.assertEqual(t($text, "case=pascal"), "JenniferDecksParseJsonFilesV2Fast");
    testing.assertEqual(t($text, "case=constant"), "JENNIFER_DECKS_PARSE_JSON_FILES_V2_FAST");
    testing.assertEqual(t($text, "case=dot"), "jennifer.decks.parse.json.files.v2.fast");
    testing.assertEqual(t($text, "case=path"), "jennifer/decks/parse/json/files/v2/fast");
    testing.assertEqual(t($text, "case=leet"), "j3nn1f3rD3ck5 p4r53J50NF1l35 v2F457");
    testing.assertEqual(t("Bestest Gizmo", "case=leet"), "8357357 612m0");
    testing.assertEqual(t("user ID", "case=camel"), "userId");
    testing.assertEqual(t("-- --", "case=snake"), "");
    testing.assertEqual(toCase("Größe ändern", "snake"), "größe_ändern");
    testing.assertEqual(len(CASES), 12);
    for (def c in CASES) {
        testing.assertEqual(toCase("abc", $c) != "", true);
    }
    testing.assertContains(errorOf("x", "case=shout"), "a case is one of upper, lower");
}

func testSlice() {
    testing.assertEqual(t("abcdefgh", "slice=2:5"), "cde");
    testing.assertEqual(t("abcdefgh", "slice=:3"), "abc");
    testing.assertEqual(t("abcdefgh", "slice=5:"), "fgh");
    testing.assertEqual(t("abcdefgh", "slice=-3:"), "fgh");
    testing.assertEqual(t("abcdefgh", "slice=1:-1"), "bcdefg");
    testing.assertEqual(t("abcdefgh", "slice=:"), "abcdefgh");
    testing.assertEqual(t("abcdefgh", "slice=3:3"), "");
    testing.assertEqual(t("Grüße", "slice=2:4"), "üß");
    testing.assertContains(errorOf("abc", "slice=1"), "slice is START:END");
    testing.assertContains(errorOf("abc", "slice=1:2:3"), "slice is START:END");
    testing.assertContains(errorOf("abc", "slice=a:2"), "a slice bound is an integer");
    testing.assertContains(errorOf("abc", "slice=0:4"), "outside a text of 3 characters");
    testing.assertContains(errorOf("abc", "slice=-4:"), "outside a text of 3 characters");
    testing.assertContains(errorOf("abc", "slice=2:1"), "starts after it ends");
}

func testTruncate() {
    testing.assertEqual(t("The quick brown fox", "truncate=10"), "The qui...");
    testing.assertEqual(t("short", "truncate=10"), "short");
    testing.assertEqual(t("exactly10!", "truncate=10"), "exactly10!");
    testing.assertEqual(t("Grüße aus Graz", "truncate=8"), "Grüße...");
    testing.assertContains(errorOf("abc", "truncate=3"), "truncate is more than 3 characters");
    testing.assertContains(errorOf("abc", "truncate=x"), "truncate is a number of characters");
    testing.assertContains(errorOf("abc", "truncate=-5"), "truncate is a number of characters");
}

func testOtherModifiers() {
    testing.assertEqual(t("  a  b \t c  ", "trim"), "a  b \t c");
    testing.assertEqual(t(" \t a b  \n", "trim=left"), "a b  \n");
    testing.assertEqual(t(" \t a b  \n", "trim=right"), " \t a b");
    testing.assertEqual(t("  x  ", "trim=left|trim=right"), "x");
    testing.assertContains(errorOf("x", "trim=both"), "trim is trim, trim=left or trim=right");
    testing.assertContains(errorOf("x", "trim="), "trim is trim, trim=left or trim=right");
    testing.assertContains(errorOf("x", "trim=Left"), "trim is trim, trim=left or trim=right");
    testing.assertEqual(t("  a  b \t\n c  ", "squash"), "a b c");
    testing.assertEqual(t("Crème Brûlée", "fold"), "Creme Brulee");
    testing.assertEqual(t("Grüße", "reverse"), "eßürG");
    testing.assertEqual(len(MODIFIERS), 7);
}

func testChains() {
    testing.assertEqual(t("  Crème Brûlée  ", "trim|fold|case=kebab"), "creme-brulee");
    testing.assertEqual(t("Some Very Long Title Here", "case=snake|truncate=12"), "some_very...");
    # left to right: slicing first, then the case
    testing.assertEqual(t("hello world", "slice=0:5|case=upper"), "HELLO");
    testing.assertEqual(t("hello world", "case=upper|slice=6:"), "WORLD");
}

func testStrictSpecs() {
    testing.assertContains(errorOf("x", ""), "a spec names at least one modifier");
    testing.assertContains(errorOf("x", "  "), "a spec names at least one modifier");
    testing.assertContains(errorOf("x", "shout"), "unknown modifier \"shout\"");
    testing.assertContains(errorOf("x", "trim||fold"), "an empty modifier");
    testing.assertContains(errorOf("x", "=upper"), "an empty modifier");
    testing.assertContains(errorOf("x", "case"), "case needs a value");
    testing.assertContains(errorOf("x", "fold=yes"), "fold takes no value");
    testing.assertContains(errorOf("x", "reverse=1"), "reverse takes no value");
    testing.assertContains(errorOf("x", "Case=upper"), "unknown modifier \"Case\"");
    testing.assertEqual(errorOf("x", "trim"), "");
}

func testComposesWithSprintf() {
    testing.assertEqual(io.sprintf("%s=%d", t("max retries", "case=constant"), 3), "MAX_RETRIES=3");
    testing.assertEqual(t(io.sprintf("%d", 255), "reverse"), "552");
}
