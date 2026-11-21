# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * White-box tests for the entry module: jennifer test src/texttransform_test.j
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
    testing.assertEqual(t("alphaBETA", "case=swap"), "ALPHAbeta");
    testing.assertEqual(t($text, "case=swap"), "JENNIFERdECKS PARSEjsonfILES V2fAST");
    testing.assertEqual(t("Straße 12, ÄRGER", "case=swap"), "sTRAßE 12, ärger");
    testing.assertEqual(t("漢字 Kanji", "case=swap"), "漢字 kANJI");
    testing.assertEqual(len(CASES), 13);
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

# Combining marks stay with their letter: "e" + U+0301 is one character.
func testCombiningMarks() {
    def s as string init "cafe\u0301 tre\u0300s";
    testing.assertEqual(words($s), ["cafe\u0301", "tre\u0300s"]);
    testing.assertEqual(t($s, "case=snake"), "cafe\u0301_tre\u0300s");
    testing.assertEqual(t($s, "case=title"), "Cafe\u0301 Tre\u0300s");
    testing.assertEqual(t($s, "case=swap"), "CAFE\u0301 TRE\u0300S");
    testing.assertEqual(t($s, "reverse"), "se\u0300rt e\u0301fac");
    testing.assertEqual(t($s, "slice=0:4"), "cafe\u0301");
    testing.assertEqual(t($s, "slice=-2:"), "e\u0300s");
    testing.assertEqual(t($s, "truncate=7"), "cafe\u0301...");
    testing.assertContains(errorOf($s, "slice=0:10"), "outside a text of 9 characters");
    # a mark with no letter before it is a character of its own
    testing.assertEqual(t("\u0301ab", "reverse"), "ba\u0301");
    testing.assertEqual(t("\u0301ab", "slice=0:1"), "\u0301");
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
