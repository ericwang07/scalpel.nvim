package.path = package.path .. ";./lua/?.lua"

local matcher = require("scalpel.matcher")
local a = require("scalpel.tests.helpers")

print("=== Matcher Tests ===")

a.assert_eq("nil candidate", matcher.score(nil, "test"), 0)
a.assert_eq("nil prediction", matcher.score("test", nil), 0)
a.assert_eq("both nil", matcher.score(nil, nil), 0)

a.assert_eq("empty candidate", matcher.score("", "test"), 0)
a.assert_eq("empty prediction", matcher.score("test", ""), 0)
a.assert_eq("both empty", matcher.score("", ""), 0)

a.assert_eq("1-char exact match", matcher.score("a", "a"), 3)
a.assert_eq("2-char exact match", matcher.score("ab", "ab"), 3)
a.assert_eq("1-char vs 2-char no match", matcher.score("a", "ab"), 0)
a.assert_eq("2-char prefix should be 0", matcher.score("abc", "ab"), 0)
a.assert_eq("2-char prediction no prefix match", matcher.score("ab", "abc"), 0)

a.assert_eq("3-char exact", matcher.score("abc", "abc"), 3)
a.assert_eq("3-char prefix match", matcher.score("abcdef", "abc"), 2)
a.assert_eq("3-char prediction prefix match", matcher.score("abc", "abcdef"), 2)
a.assert_eq("3-char suffix match", matcher.score("xyzabc", "abc"), 2)
a.assert_eq("3-char prediction suffix match", matcher.score("abc", "xyzabc"), 2)
a.assert_eq("3-char substring", matcher.score("xyzabcz", "abc"), 1)
a.assert_eq("3-char prediction substring", matcher.score("abc", "xyzabcz"), 1)

a.assert_eq("exact match basic", matcher.score("concat", "concat"), 3)
a.assert_eq("exact match case-sensitive", matcher.score("Concat", "concat"), 0)
a.assert_eq("exact match with spaces", matcher.score("hello world", "hello world"), 3)
a.assert_eq("exact match with special chars", matcher.score("foo-bar", "foo-bar"), 3)

a.assert_eq("prefix match short prediction", matcher.score("function", "func"), 2)
a.assert_eq("prefix match long candidate", matcher.score("configuration", "config"), 2)
a.assert_eq("prefix match reversed", matcher.score("abc", "abcdef"), 2)

a.assert_eq("suffix match", matcher.score("test_func", "func"), 2)
a.assert_eq("suffix match at end", matcher.score("hello_world", "world"), 2)
a.assert_eq("suffix match reversed", matcher.score("abc", "xyzabc"), 2)

a.assert_eq("substring match", matcher.score("concatenation", "cat"), 1)
a.assert_eq("substring match reversed", matcher.score("cat", "concatenation"), 1)

a.assert_eq("exact outranks prefix", matcher.score("func", "func"), 3)
a.assert_eq("prefix outranks substring", matcher.score("configuration", "conf"), 2)
a.assert_eq("suffix same priority as prefix", matcher.score("test_func", "func"), 2)

a.assert_eq("substring at start is prefix match", matcher.score("catapult", "cat"), 2)
a.assert_eq("substring at end is suffix match", matcher.score("copycat", "cat"), 2)

local long_str = string.rep("a", 200)
a.assert_eq("long string exact match", matcher.score(long_str, long_str), 3)
a.assert_eq("long string prefix match", matcher.score(long_str .. "xyz", string.rep("a", 100)), 2)

a.assert_eq("unicode exact", matcher.score("café", "café"), 3)
a.assert_eq("unicode prefix", matcher.score("café au lait", "café"), 2)
a.assert_eq("unicode no match", matcher.score("cafe", "café"), 0)

a.assert_eq("number candidate", matcher.score(123, "123"), 0)
a.assert_eq("number prediction", matcher.score("123", 123), 0)
a.assert_eq("boolean candidate", matcher.score(true, "true"), 0)
a.assert_eq("table candidate", matcher.score({}, "{}"), 0)

a.assert_eq("numeric string exact", matcher.score("123", "123"), 3)
a.assert_eq("numeric string prefix match", matcher.score("12345", "123"), 2)

a.assert_eq("leading tab string ends with prediction", matcher.score("\thello", "hello"), 2)
a.assert_eq("leading newline string ends with prediction", matcher.score("\nhello", "hello"), 2)
a.assert_eq("exact with leading tab", matcher.score("\thello", "\thello"), 3)

a.assert_eq("regex char dot suffix match", matcher.score("file.txt", "txt"), 2)
a.assert_eq("regex char star literal match", matcher.score("test*", "test"), 2)
a.assert_eq("regex char bracket substring match", matcher.score("[test]", "test"), 1)
a.assert_eq("regex char paren substring match", matcher.score("(test)", "test"), 1)

a.report("Matcher Tests")
a.exit_if_failed()
