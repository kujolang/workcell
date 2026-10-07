import assert from 'node:assert/strict';
import { test } from 'node:test';
import { quote, parse } from 'shell-quote';

test('bundled shell quoting rejects line termination after a comment token', () => {
  // GHSA-pqg4-j6r4-53mv: never execute the generated string in this regression.
  for (const terminator of ['\n', '\r', '\u2028', '\u2029']) {
    assert.throws(() => quote([{ comment: 'observed' }, `${terminator}echo injected`]), TypeError);
  }
});

test('bundled shell quoting preserves ordinary literal command arguments', () => {
  const args = ['printf', '%s', 'a b', "single'quote", '$literal', ';literal'];
  assert.deepEqual(parse(quote(args)), args);
});
