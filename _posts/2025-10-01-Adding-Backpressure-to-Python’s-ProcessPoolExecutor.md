---
lang: en
layout: post
tags: coauthored-with-chatgpt, python, concurrency, programming, backpressure, processpoolexecutor, threading
title: Adding Backpressure to Python’s ProcessPoolExecutor
---

Recently I've hit a practical limitation with Python’s `ProcessPoolExecutor`:
when feeding it tens of thousands of tasks from hundreds of producer threads,
the executor happily accepted them all. The result? Memory usage ballooned,
latency increased, and eventually the whole system became unstable.

The root issue: by default, `ProcessPoolExecutor` accepts
**an unbounded number of submissions**. The internal queue of work IDs grows
without limit, and since every `submit()` creates a `Future`, you can easily
flood memory if your producers are much faster than the pool can drain tasks.

I needed **backpressure**: a way to make `submit()` block when the executor is
saturated, so producers naturally pause until capacity frees up.

## Options Considered

Several strategies came up during exploration:

1. **Monkey-patching internals**
   Replace the executor’s private `_work_ids` queue with a bounded one.
   Technically possible (the last field initialized in the constructor), but
   fragile across Python versions.

2. **External semaphore**
   Wrap the executor in a class that holds a `Semaphore`. Each `submit()`
   acquires a slot; each task completion releases it. This approach is stable
   and easy to customize.

3. **Bounded queue feeder**
   Insert a `Queue(maxsize=N)` between producers and a dedicated feeder thread
   that calls `submit()`. Producers block on `put()` when the queue is full.

4. **Batching**
   Increase the task granularity (using `chunksize` in `map()` or by grouping
   tasks manually). This reduces overhead but doesn’t directly solve the memory
   growth problem.

Ultimately, I wanted something **drop-in compatible** with the existing executor
API. That meant subclassing with a simple extension.

## Choosing Defaults

The key design choice is how large the backlog of pending tasks should be before
producers block. The number should be proportional to the number of workers:

* **2 × workers**: a balanced default for CPU-bound tasks of ~1s duration.
* **3 × workers**: useful when task durations vary a lot.
* **4 × workers**: a practical upper bound; beyond that, memory and latency
  increase without improving throughput.

Example: with 8 CPU workers and tasks taking around one second,
`max_submit_backlog=16` keeps memory stable and ensures low latency. If variance
is high, bump it to 24. Rarely is more than 32 necessary, only if task durations
are extremely low (e.g., less than 100 milliseconds), but in that cases,
overhead from inter-process communication dominates anyway, so it's better to
use batching or a different concurrency model.

## The Implementation

Here is the final class I ended up using. It subclasses `ProcessPoolExecutor`
and adds a bounded queue via a semaphore:

```python
from concurrent.futures import ProcessPoolExecutor, Future
from threading import Semaphore
from typing import Literal, Optional, cast, Callable, Any


class BoundedProcessPoolExecutor(ProcessPoolExecutor):
    """
    A ProcessPoolExecutor with a bounded submission queue.

    Unlike the standard implementation, `submit()` will block once the
    number of pending tasks reaches `max_submit_backlog`. This provides
    natural backpressure to producers and prevents unbounded memory
    growth.
    """

    def __init__(
        self,
        max_submit_backlog: Optional[int | Literal[True]] = None,
        *args: Any,
        **kwargs: Any,
    ) -> None:
        """
        :param max_submit_backlog:
            - None (default): unlimited (same as ProcessPoolExecutor).
            - int > 0: maximum number of tasks allowed to be pending.
                       `submit()` blocks if this limit is reached.
            - True: automatic mode, sets the queue size to 2 ×
                    max_workers.
        """
        super().__init__(*args, **kwargs)

        if max_submit_backlog is None:
            self._semaphore: Semaphore | None = None
        else:
            if max_submit_backlog is True:
                max_submit_backlog = cast(int, self._max_workers) * 2
            elif not (
                isinstance(max_submit_backlog, int) and
                0 < max_submit_backlog
            ):
                raise ValueError(
                    "max_submit_backlog must be None, True, or a positive int"
                )

            self._semaphore = Semaphore(max_submit_backlog)

    def submit(
        self, fn: Callable[..., Any], /, *args: Any, **kwargs: Any
    ) -> Future:
        semaphore = self._semaphore
        if semaphore:
            semaphore.acquire()

        future = super().submit(fn, *args, **kwargs)

        if semaphore:
            future.add_done_callback(lambda f: semaphore.release())

        return future
```

## Results

With this subclass in place:

* **Producers pause** automatically when the pool is full, instead of flooding
  memory.
* **Memory stays flat**, no runaway growth from thousands of pending `Future`
  objects.
* **Latency stabilizes**, since tasks no longer wait behind massive queues.
* **Throughput remains consistent**, limited only by the number of workers.

There are visible pauses in producer threads and even some “gaps” in disk
activity, but that’s expected: it’s the backpressure mechanism working as
intended.

## Takeaways

This isn’t a perfect candidate for inclusion in the Python standard library as I
initially intended, that would require deeper refactoring to improve current
implementation (e.g., eliminating `_queue_count` and insert `_WorkItem`s
[directly into the queue](https://github.com/python/cpython/blob/f48128b6b3722ee2b2cef026e9679e37bd5b2517/Lib/concurrent/futures/process.py#L801-L803C18)).
But as an **ad-hoc solution or external utility**, it works extremely well and
is simple to reason about.

If you’re pushing `ProcessPoolExecutor` with tens of thousands of tasks, this
bounded version is a safe and effective drop-in replacement that keeps your
memory in check and your system responsive.

> **Note**
>
> This post was developed collaboratively between me and
> [ChatGPT GPT-5](https://chatgpt.com/), an AI language model by
> [OpenAI](https://openai.com/). The ideas, discussion, and final decisions were
> shaped through a process of interactive brainstorming and refinement. After
> that, final formatting and edition was done by hand. You can
> [download]({{ site.baseurl }}/chatgpt-conversations/2025-10-01-Adding-Backpressure-to-Python’s-ProcessPoolExecutor.md)
> a detailed discussion of the process, or get access to the
> [original conversation](https://chatgpt.com/share/68dcb335-0eac-8000-8341-3566bb6fc676).
>
> `#human-ai-collaboration`
