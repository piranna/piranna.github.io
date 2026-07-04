---
categories:
  - AI
lang: en
layout: post
tags:
  - automation
  - chatgpt
  - coauthored-with-chatgpt
  - openai
  - productivity
  - reminders
  - tasks
  - scheduling
title: Designing “Almost-Autonomous” Reminders in ChatGPT (No Third-Party Bots)
---

How we went from a one-off ping to a nightly, varied, almost-autonomous reminder
flow **inside ChatGPT**, and the three agent patterns you can use to build it —
complete with runnable code.

<!--more-->

## TL;DR

- We explored three ways to get reminders that **feel proactive** inside
  ChatGPT:
  1. **Pre-Scheduled Simulation (In-Chat, Fixed):** prewrite times & texts
     (rotate weekly/monthly). Easiest, zero infra, no true randomness.
  2. **External Agent + OpenAI Tasks (Delegated Planning):** a tiny daily script
     asks the model for tonight’s plan (times + messages) and programs **ChatGPT
     Tasks** so the pings appear here. True nightly randomness, low infra.
  3. **In-Chat “Housekeeper” (Daily Wake-Up):** one daily Task (e.g., 23:30)
     that, when it fires, instructs ChatGPT to generate and schedule 2–3
     additional reminders between 23:30–00:30. Feels autonomous without running
     your own server.

- We finished with pattern **#3**: first visible reminder at **23:30**; I then
  schedule 2–3 more for the 23:30–00:30 window, with varied tone and “stop on
  **done**”.

## The Journey (Timeline of What We Actually Set Up)

1. **One-minute test** → “It's been a minute ⏰”.
2. **First daily reminder** → 22:30; felt early/mechanical/condescending → we
   changed tone.
3. **Window + Insistence** → 23:30, 23:45, 00:00, 00:15; varied messages, stop
   when you reply **“hecho”/“done”**.
4. **Autonomy discussion** → true in-moment randomness requires either:
   - an **external agent** that updates **ChatGPT Tasks**, or
   - a daily **in-chat wake-up** Task (the “housekeeper”) that schedules the
     rest **at runtime**.
5. **Final choice** → **Housekeeper @ 23:30** as the first visible reminder; I
   program 2–3 more random reminders until 00:30. Commands: `done`, `snooze 10`,
   `pause teeth`, `resume teeth`.

> Timezone throughout: **Europe/Madrid**. Window: **23:30–00:30**. Messages:
> 6–14 words, natural tone, ≤1 emoji, non-repetitive nightly.

## Doing It Natively in ChatGPT with Prompts

Before we explored agents or housekeepers, we discovered you can go quite far
**just with prompts and built-in Tasks inside ChatGPT**. This doesn’t require
any external script or API calls—everything lives in your conversation.

- **Step 1: Create simple one-off reminders.** Example: _“Remind me in one
  minute”_ → ChatGPT can schedule a single Task with the message **“It’s been a
  minute ⏰”**. You’ll see it pop up right here in the thread.

- **Step 2: Add a daily fixed reminder.** You can say _“Remind me every night at
  22:30 to brush my teeth”_. This works, but early on we noticed the copy felt
  too rigid—robotic or even condescending — so we experimented with tone.

- **Step 3: Build a nightly sequence (“window + insistence”).** Instead of a
  single time, you can ask: _“Remind me at 23:30, 23:45, 00:00, and 00:15 until
  I confirm”_. ChatGPT schedules those four Tasks with different messages. If
  you reply **“done”**, it cancels the rest for that night. If you say **“snooze
  10”**, it can slot in one more Task 10 minutes later. This approach gives you
  multi-step persistence entirely through prompts.

### Pros

- Zero setup: just tell ChatGPT what you want.
- Works entirely in-chat; no scripts, no external infra.
- Quick way to test tone and timing before building anything heavier.

### Cons

- All times and texts are prefixed up front; no true randomness or nightly
  variation.
- If you want different tone each day, you need to define those messages
  explicitly.
- Can get noisy if you try to manage many reminders manually.

## The Three Agent Patterns (with Code)

> **Important:** The `Tasks` API names below (`client.tasks.create/update`) are
> representative. Depending on your SDK/version, names or shapes may differ
> slightly. Treat these as **templates**.

### 1) Pre-Scheduled Simulation (In-Chat, Fixed)

**When to choose:** You want everything inside ChatGPT, zero moving parts, and
you’re OK with “pre-planned variety” (weekly/monthly rotations) rather than real
nightly randomness.

**How it works:** Run once to pre-create a week’s worth of reminders (e.g.,
4/night × 7 nights). Rotate texts by day/slot. You can re-run weekly to refresh
the next cycle.

#### Python 3.13 — Weekly Pre-Planner (fixed times & rotating messages)

```python
# preplan_week.py
# pip install openai python-dateutil
import os, json
from datetime import datetime, timedelta, time
from dateutil.tz import gettz
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
TZ = "Europe/Madrid"

# 4 fixed slots per night, 00:00 and 00:15 are next day:
SLOTS = [time(23,30), time(23,45), time(0,0), time(0,15)]

# A 7x4 rotation table (examples — edit freely)
ROTATION = [
  [
    "Teeth time—two minutes, done. 🪥", "Bed’s boarding soon; brush now. ✈️",
    "Short brush, long smile. ✨", "One minute now beats regret."
  ],
  [
    "Clock says brush; future you agrees.", "Let’s make morning breath proud.",
    "Tiny habit, big payoff.", "Brush now, dream better."
  ],
  [
    "Do it now so sleep wins.", "Gentle nudge: toothbrush time.",
    "Last call before midnight. 😏", "Brush → peace → pillow."
  ],
  [
    "Your pillow called: ‘brush first.’", "Don’t outrun hygiene tonight.",
    "Two minutes, zero drama.", "Brush and close the day."
  ],
  [
    "Netflix can wait; teeth can’t.", "Midnight’s close—make it fresh.",
    "A small ritual, big signal.", "One brush to rule sleep."
  ],
  [
    "Pro tip: future breath says thanks.", "Bed queue open—brush to enter.",
    "Two minutes, lights out. 🌙", "Keep it simple: brush now."
  ],
  [
    "Almost there—teeth, then peace.", "Tiny win before sleep.",
    "Short swipe, sweet dreams.", "Last nudge: toothbrush up."
  ]
]

def next_seven_days(start_date):
  for i in range(7):
    yield start_date + timedelta(days=i)

def to_dt_eu(date_obj, t: time):
  # 23:30 stays same day; 00:00/00:15 roll to next
  dt = datetime.combine(date_obj, t)
  if t.hour < 12 and t.hour < 1:  # midnight slots flagged if needed
    # If time is 00:00 or 00:15, ensure it's next calendar day
    if t.hour == 0:
      dt = dt + timedelta(days=1)
  return dt.replace(tzinfo=gettz(TZ))

def to_vevent(dt_eu):
  dt_utc = dt_eu.astimezone(gettz("UTC"))
  return (
    f"BEGIN:VEVENT\nDTSTART:{dt_utc.strftime('%Y%m%dT%H%M%SZ')}\nEND:VEVENT"
  )

def create_task(title, prompt, vevent):
  return client.tasks.create(title=title, prompt=prompt, schedule=vevent)

def main():
  today = datetime.now(gettz(TZ)).date()
  for day_index, day in enumerate(next_seven_days(today)):
    messages = ROTATION[day_index % len(ROTATION)]
    for slot_index, slot in enumerate(SLOTS):
      dt_eu = to_dt_eu(day, slot)
      vevent = to_vevent(dt_eu)
      prompt = messages[slot_index % len(messages)]
      title = f"Teeth (weekly preplan) {day.isoformat()} #{slot_index+1}"
      task = create_task(title, prompt, vevent)
      print(
        "Scheduled:", title, "→", dt_eu.isoformat(),
        "::", prompt,
        ":: TaskID", getattr(task,"id",None)
      )

if __name__ == "__main__":
  main()
```

#### Pros

- Dead simple. Everything lands in ChatGPT automatically.
- No daily compute required.

#### Cons

- Variety is “pre-baked.” To change tone or timing nightly, you must re-plan.

### 2) External Agent + OpenAI Tasks (Delegated Planning)

**When to choose:** You want **true nightly randomness** (fresh times + fresh
copy), but still want the reminder to **appear in ChatGPT**. You can run a
lightweight script once per day (GitHub Actions, cron, Cloudflare Workers
calling a tiny endpoint, etc.).

**How it works:** Each day your script “wakes up”, asks the model for tonight’s
plan (JSON: 1–4 reminders with local datetimes + messages), converts to iCal
`DTSTART` in UTC, and creates/updates **Tasks** so the pings show up here.

#### Python 3.13 — Delegated Plan (model generates times + messages)

```python
# agent_delegate.py
# pip install openai python-dateutil
import os, json
from datetime import datetime
from dateutil import tz
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
TZ = "Europe/Madrid"
TITLE_PREFIX = "Teeth (delegated) "

def ask_model_for_today_plan():
  today = datetime.now(tz.gettz(TZ)).date().isoformat()
  resp = client.responses.create(
    model="gpt-5-think",
    temperature=0.9,
    max_output_tokens=300,
    input=[
      {
        "role":"system",
        "content":(
          "Generate tonight’s brushing reminders (1–4 entries) as pure JSON:\n"
          "{ \"day\":\"YYYY-MM-DD\", \"tz\":\"Europe/Madrid\", "
          "\"reminders\":[{\"dt_local\":\"YYYY-MM-DDTHH:MM:SS\","
          "\"message\":\"...\"}, ...] }\n"
          "Rules:\n"
          "• Window: 23:30–24:00 today and 00:00–00:30 tomorrow "
          "(Europe/Madrid).\n"
          "• ≥10 min between reminders; no duplicate minutes.\n"
          "• message: 6–14 words, natural tone, ≤1 emoji, no quotes."
        )
      },
      {"role":"user","content": f"Plan for {today} please."}
    ]
  )
  return json.loads(resp.output_text.strip())

def to_vevent(dt_local_iso):
  local = datetime.fromisoformat(dt_local_iso).replace(tzinfo=tz.gettz(TZ))
  utc = local.astimezone(tz.gettz("UTC"))
  return f"BEGIN:VEVENT\nDTSTART:{utc.strftime('%Y%m%dT%H%M%SZ')}\nEND:VEVENT"

def upsert_task(title, prompt, vevent, task_id=None):
  if task_id:
    try:
      return client.tasks.update(
        task_id=task_id, title=title, prompt=prompt, schedule=vevent,
        is_enabled=True
      )
    except Exception:
      pass
  return client.tasks.create(title=title, prompt=prompt, schedule=vevent)

def main():
  state_file = ".tasks_ids.json"
  try:
    state = json.loads(open(state_file).read())
  except Exception:
    state = {}

  plan = ask_model_for_today_plan()
  day = plan["day"]

  for idx, r in enumerate(plan["reminders"], start=1):
    title = f"{TITLE_PREFIX}{day} #{idx}"
    prompt = r["message"]
    vevent = to_vevent(r["dt_local"])
    key = f"{day}#{idx}"
    task_id = state.get(key)
    task = upsert_task(title, prompt, vevent, task_id=task_id)
    state[key] = getattr(task, "id", task_id)
    print(f"[OK] {title} → {r['dt_local']} :: {prompt}")

  with open(state_file, "w") as f:
    json.dump(state, f)

if __name__ == "__main__":
  main()
```

#### Pros

- Real nightly randomness (times and copy).
- Still lands inside ChatGPT as native reminders.
- Very small daily runtime (once/day).

#### Cons

- Requires a daily trigger (Actions/cron/Worker).

> _Note:_ You can expand messages by day-of-week, user mood, recent behavior
> (“if missed yesterday, nudge earlier”), etc.—the model can synthesize those
> rules into the JSON plan.

### 3) In-Chat “Housekeeper” (Daily Wake-Up) — **Our Final Choice**

**When to choose:** You want the **least infrastructure** while still getting
nightly variety that’s decided **right before** your window. Everything happens
in ChatGPT.

**How it works:**

- You create **one recurring Task** at **23:30**. That message is your **first
  visible reminder**.
- Its prompt instructs ChatGPT to **immediately schedule 2–3 more** reminders at
  randomized minutes between **23:30–00:30**, ensure ≥10-minute spacing, and
  stop if you reply **done**.
- Optional commands in chat: `done` (stop remaining tonight), `snooze 10` (add
  one +10), `pause teeth` / `resume teeth` (disable/enable routine).

#### Python 3.13 — Create/Update the Daily Housekeeper (RRULE)

```python
# housekeeper_setup.py
# pip install openai
import os
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

TITLE = "Teeth (housekeeper)"
# This prompt becomes the FIRST visible reminder at 23:30,
# and also instructs ChatGPT what to do right after firing.
PROMPT = (
  "First, show a friendly one-line brushing reminder (6–14 words, ≤1 emoji). "
  "Then, immediately schedule 2–3 additional reminders tonight between "
  "23:30–00:30 (Europe/Madrid) at randomized minutes, with ≥10 minutes "
  "spacing. Vary the wording so the messages don't repeat tonight. "
  "If the user replies 'done', cancel remaining tonight. "
  "If the user says 'snooze X', schedule one extra reminder X minutes later. "
  "Keep the tone natural, not condescending."
)

# Daily at 23:30 Europe/Madrid
RRULE_VEVENT = """BEGIN:VEVENT
RRULE:FREQ=DAILY;BYHOUR=23;BYMINUTE=30;BYSECOND=0
END:VEVENT"""

def create_or_update_housekeeper(task_id=None):
  if task_id:
    try:
      return client.tasks.update(
        task_id=task_id,
        title=TITLE,
        prompt=PROMPT,
        schedule=RRULE_VEVENT,
        is_enabled=True,
      )
    except Exception:
      pass
  return client.tasks.create(
    title=TITLE,
    prompt=PROMPT,
    schedule=RRULE_VEVENT,
  )

if __name__ == "__main__":
  # If you store the returned task.id, you can update it later instead of
  # creating a new one.
  task = create_or_update_housekeeper(task_id=None)
  print("Housekeeper Task:", getattr(task, "id", None))
```

#### Pros

- No external compute; feels “autonomous” nightly.
- True per-night variation since scheduling of the 2–3 follow-ups happens right
  after 23:30.
- All interaction remains in ChatGPT.

#### Cons

- Needs that single daily wake-up at 23:30 (by design).
- If you **must** hide the wake-up, make it the **first visible reminder** (as
  we did). A truly silent internal wake-up isn’t supported as a user-invisible
  message.

## Choosing the Right Pattern

- **I want the simplest thing now** → **#1 Pre-Scheduled Simulation**. Rotations
  keep it fresh enough for many people. Zero infra.

- **I want genuine nightly randomness** and don’t mind a tiny daily job → **#2
  External Agent + Tasks**. Use GitHub Actions (daily), a cron on a VPS/NAS, or
  a Worker hitting a small endpoint.

- **I want it all in ChatGPT** with minimal setup and a strong sense of autonomy
  → **#3 Housekeeper** (our pick). One recurring Task at 23:30; it schedules the
  additional reminders on the fly.

> You can also combine them: use **#3** as the baseline and fall back to **#1**
> (weekly rotation) if anything fails.

## Operational Notes & Best Practices

- **Timezone:** Always compute and store in **Europe/Madrid**, then convert to
  UTC for `DTSTART`.
- **Spacing:** Keep ≥10 minutes between reminders to avoid spammy bursts.
- **Copy style:** 6–14 words, natural, sometimes lightly humorous, max one
  emoji.
- **Stopping logic:** Reply **done** to cancel the rest of the night; **snooze
  X** to add one late reminder.
- **Idempotency:** Save `task_id` so you can **update** instead of creating
  duplicates.
- **Pause/Resume:** Add simple commands (`pause teeth`, `resume teeth`) to
  toggle the routine.

## What We Actually Ended Up With

- Pattern **#3 Housekeeper** at **23:30** (first visible reminder).
- I generate and schedule **2–3 more** randomized pings between **23:30–00:30**.
- Messages vary nightly; stop on **done**, ad-hoc **snooze** supported.
- If you ever want **full nightly randomness plus cross-day memory** (e.g.,
  adapt if you missed yesterday), switch to **#2** so your script can keep
  longer-term state and feed it back into the plan.

_Note on alternatives:_ If you ever decide to move reminders off ChatGPT, you
can replace Tasks with notifications in other channels (e.g.,
Telegram/Matrix/email) via an external agent. In this article we stayed strictly
with **ChatGPT/OpenAI** delivery.

> **Note**
>
> This post was developed collaboratively between me and
> [ChatGPT](https://chatgpt.com/), an AI language model by
> [OpenAI](https://openai.com/). The ideas, discussion, and final decisions were
> shaped through a process of interactive brainstorming and refinement. After
> that, final formatting and edition was done by hand. You can
> [download]({{ site.baseurl }}/chatgpt-conversations/2025-09-14-Designing-“Almost-Autonomous”-Reminders-in-ChatGPT-(No-Third-Party-Bots).html)
> a detailed discussion of the process, or get access to the
> [original conversation](https://chatgpt.com/share/68c69668-f2a4-8000-a257-09714a45660e).
>
> `#human-ai-collaboration`
