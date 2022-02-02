---
lang: en
layout: post
title: How to do proper exceptions handling
twitter: '1488788775526453253'
---

An exception happens when something we expected that should happen, didn't. We
can log them, but printing logs everywhere add a lot of noise, so it's better to
throw errors and handle them in upper levels. Also, a thrown error is easy to
check and test, but a log message is not, so they are better for unit testing.

After throwing it, the caller function (and the one that expected it to work)
can process it and decide if it's something that can be ignored (a warning) or
not, but the actual function that had the error should **not** decide itself if
it's a warning or not. It's a principle of responsabilities ownership.

Also, throwing multiple errors is fine if the function needs to check multiple
things. This doesn't means it can thrown the same error, but instead they should
be different ones, to make them easier to identify what went wrong. Maybe a
different type, but a different code or at least error message should be enough.

Regarding exceptions handling, as a rule of thumb I follow Python philosofy:

- `try-catch` blocks should be as small as possible, and ideally down to a
  single statement or function call. There can be multiple ones if all of them
  can throw exceptions, but if any operation doesn't (and usually access to
  objects fields don't do it), then it must be moved out of the `try-catch`
  block. This can apply to `async-await` functions too.

- Don't do nested `try-catch` blocks, that's a symptom of wrong responsibilities
  ownership, or exceptions over-handling. Move the block to another function
  (leading us to the first point about handling of single statement or function
  call), or better throw it and handle it in the external `try-catch` block.

- And finally and most importantly, if it's not something we care about, we
  throw it up in the calls stack to be processed from somebody else. And if it
  ends up in the main function without nobody else processing it before, then
  now yes, log it and show it to the user.
