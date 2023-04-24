---
lang: en
layout: post
title: How to migrate from Jest to node:test
---

[Jest](https://jestjs.io/) is one of the most populars testing frameworks for
Javascript and Node.js. Originally developed by Facebook, it's a one-stop-shop
with testing, assertions, code coverage... but this implies some critics, like
requiring more than 50mb of dependencies. Also, somewhat recently was shown to
[be maintained mostly by a single person](https://twitter.com/mafalda_sfu/status/1488600128680341517),
being that the reason why updates and maintenance was so much slow, so they
[decided to transfer it to OpenJS foundation](https://engineering.fb.com/2022/05/11/open-source/jest-openjs-foundation/).
Also there has been several long standing critics about not providing a pure
environment, or the fact that Jest parses the code, leading to some complexities
when needing to configure transpilation. That has lead to several people looking
for alternatives, and having now a built-in test runner in Node.js, I decided to
see myself how to migrate to it.

First of all, it's to identify the replacements for the different Jest features.
As already shown, [node:test](https://nodejs.org/api/test.html) module can the
used as the test runner and for mocking, meanwhile
[assert](https://nodejs.org/api/assert.html) module can mostly be used for
assertions. A tough topic are inline
[snapshots](https://jestjs.io/docs/snapshot-testing), since it's a feature I use
a lot. Luckily Jest snapshot engine is provided as an
[independent module](https://www.npmjs.com/package/jest-snapshot), but it don't
have documentation at all and it's very tightly coupled with Jest itself. There
are some modules that wrap it and add support for
[chai](https://www.chaijs.com/) like
[chai-jest-snapshot](https://www.npmjs.com/package/chai-jest-snapshot) and
[mocha-chai-jest-snapshot](https://www.npmjs.com/package/mocha-chai-jest-snapshot),
so it can works as a solution, but not only that would add an extra assertions
library, but also there's no support for inline snapshots, just only regular
ones. I tried to create my own wrapper without making use of any extra
dependency and adding the support for inline snapshots, but lack of
documentation makes it difficult. Maybe I'll try again in the future (anybody
interested on sponsors me? :-) ).

Having now the elements, doing the migration is surprisingly pretty straighforward:

1. Add `chai` and `chai-jest-snapshot` as dev dependencies, and remove any Jest
   related dependency and configuration.
2. Rename `__tests__` folder(s) to `test`.
3. Replace `jest` command with `node --test`.
4. Add the `node:test` functions that previously were set as globals by Jest:

   ```js
   import {
     afterEach, before, beforeEach, describe, mock, test, throws
   } from 'node:test'
   ```

5. Enable the snapshot support, and the replacement of the `expect()` function:

   ```js
   import chai, {expect} from 'chai'
   import chaiJestSnapshot from 'chai-jest-snapshot'


   chai.use(chaiJestSnapshot)

   before(function()
   {
     chaiJestSnapshot.resetSnapshotRegistry()
   })
   ```

   Since `node:test` run each test in a different process, we need to add the
   snapshot support in each test file.

6. Comment or remove calls to `expect.assertions()`, since there's no equivalent
   in `node:test`. This was possible on Jest since assertions were integrated in
   the tests runner.
7. Await the `Promise`s instead of `expect()` on them (`expect(await promise)`
   instead of `await expect(promise).resolves`).
8. Replace Jest idioms:
   - `expect(func).toThrowErrorMatchingInlineSnapshot(error)` with
     `throws(func, error)`
   - `expect(value).toBe(expected)` with `deepStrictEqual(value, expected)`
   - `expect(value).toBeInstanceOf(class)` with `ok(value instanceof class)`
   - `expect(value).toBeUndefined()` with `ifError(value)`
   - `expect(value).toMatchSnapshot()` with `expect(value).to.matchSnapshot()`

Missing points as already commented, would be the support for inline snapshots,
and maybe create a [codemods](https://github.com/skovhus/jest-codemods) to
automate the process :-)
