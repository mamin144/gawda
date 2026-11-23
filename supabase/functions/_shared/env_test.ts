import { assertEquals } from "@std/assert";
import { parseDefaultKey } from "./env.ts";

Deno.test("parseDefaultKey: returns the 'default' entry", () => {
  assertEquals(parseDefaultKey('{"default":"k1","other":"k2"}'), "k1");
});

Deno.test("parseDefaultKey: missing, empty or malformed input is null", () => {
  assertEquals(parseDefaultKey(undefined), null);
  assertEquals(parseDefaultKey(""), null);
  assertEquals(parseDefaultKey("not json"), null);
  assertEquals(parseDefaultKey("null"), null);
  assertEquals(parseDefaultKey('"default"'), null);
  assertEquals(parseDefaultKey("[]"), null);
  assertEquals(parseDefaultKey('{"other":"k2"}'), null);
  assertEquals(parseDefaultKey('{"default":""}'), null);
  assertEquals(parseDefaultKey('{"default":42}'), null);
});
