---
lang: en
layout: post
tags: coauthored-with-chatgpt, fastify, typescript, nodejs, django, webdev, programming, cbv, class-based-views, architecture, design-patterns, api, http, web-frameworks
title: Bringing Class-Based Views to Fastify (Inspired by Django)
---

> *Why doesn’t Node.js have something like Django’s Class-Based Views (CBVs)?*

I love Django key features like its **class-based views** or ORM, and I usually
miss them when working with Node.js. So yesterday night, in the middle of my
usual insomnia, I wondered if anyone had already built something like that for
Node.js.

I did a quick search, and what I found were just a few experiments from ~8–9
years ago. Nothing robust, modern, or maintained.

Django Class-Based Views (CBVs) provide a **clear structure**, lots of
**built-in functionality**, and still enough flexibility to adapt them to
different use cases. So I decided to sketch out a design for
[Fastify](https://fastify.dev/) (and [Node.js](https://nodejs.org/) in general)
that feels natural to use, contract-first, and TypeScript-friendly. This post is
a walk-through of that exploration during the rest of the Sunday.

## Why Class-Based Views?

In Django, in addition to writing separate functions for each route, you can
define a **class** with methods like `get()`, `post()`, `delete()`. Django
automatically registers those with the correct HTTP verbs and routes.

The benefits are clear:

* **Organization:** keep related logic together.
* **Inheritance & Mixins:** factor out reusable behavior.
* **Consistency:** no need to wire up handlers manually.

## The Challenges in Node.js

* Most Node frameworks ([Express](https://expressjs.com/),
  [Fastify](https://fastify.dev/), [Koa](https://koajs.com/)) assume
  **functions** as handlers (at least it feels natural to use closures to
  provide some structure, in contrast to most Python frameworks).
* For that reason, there’s little to no **out-of-the-box CBV support**.
* TypeScript typing gets tricky: how do we connect the schemas (runtime) to have
  strict request/response types (compile-time)?
* HTTP has subtle rules to respect (e.g. `HEAD` vs `GET`, `204 No Content` never
  having a body).

## Building Blocks

Although this project was initially conceived for the Class Based Views pattern,
other topics surfaced along the way to make projects using it production-ready
and pleasant to use with Fastify and TypeScript, like TypeScript Strictness.
Here are the main building blocks:

1. **BaseView**: a class that defines an `as_plugin()` static method, similar to
   Django's `View.as_view()`, returning a Fastify plugin with routes registered
   automatically for any methods you implement (`get`, `post`, `delete`, etc.).
2. **`replyWith()` helper**: to handle *shortcuts* (errors, 404s, 204s) in a
   type-safe way, cutting the control flow.
3. **Error handling**: done globally via `fastify.setErrorHandler()`, not inside
   the view itself.
4. **Contract-first schemas**: using `fastify-type-provider-json-schema-to-ts`
   (JSTT) and `json-schema-to-ts`, the JSON Schema is the source of truth, and
   TypeScript types are derived from it.
5. **Mixins via class factories**: because TypeScript doesn’t have multiple
   inheritance, we can use class expressions to compose behavior.

## The Final `BaseView` Implementation

```ts
// cbv.mts
import { METHODS } from 'node:http';

import type {
  FastifyInstance, FastifyReply, FastifyRequest, RouteShorthandOptions
} from 'fastify';
import fastifyAllow from 'fastify-allow';
import fp from 'fastify-plugin';


export class HTTPError extends Error {
  constructor(statusCode: number, message?: string, payload?: unknown) {
    super(message);

    this.statusCode = statusCode;
    this.message = message ?? (
      statusCode === 500 ? 'Internal Server Error' : 'Error'
    );
    this.payload = payload;
  }
}

/** Return HTTP methods in lowercase, but put HEAD before GET.
 *  Why? Because Fastify will auto-generate HEAD routes for GET if none exist.
 *  If you *do* define your own head(), we need to register it first.
 */
function orderedNodeMethods(): string[] {
  const all = Array.from(new Set(METHODS.map(m => m.toLowerCase())));
  const i = all.indexOf('head');
  if (i > -1) { all.splice(i, 1); all.unshift('head'); }
  return all;
}

export class BaseView<D extends object = Record<string, unknown>> {
  constructor(
    ctx: {
      req: FastifyRequest; reply: FastifyReply; fastify: FastifyInstance
    } & D
  ) {
    this.ctx = ctx;
  }

  static as_plugin<TDeps extends object = Record<string, unknown>>(opts?: {
    deps?: TDeps;
    common?: RouteShorthandOptions;
  }) {
    const ViewClass = (
      this as unknown as new (ctx: any) => BaseView<TDeps> & Record<string, any>
    );
    const deps   = opts?.deps   ?? ({} as TDeps);
    const common = opts?.common ?? {};

    return fp(async function viewPlugin(fastify) {
      // Derive allowed methods from what we actually register in this scope.
      await fastify.register(fastifyAllow);

      const staticSchemas: Record<string, any> =
        (
          (ViewClass as any).schemas &&
          typeof (ViewClass as any).schemas === 'object'
        )
          ? (ViewClass as any).schemas
          : {};

      for (const m of orderedNodeMethods()) {
        if (typeof (ViewClass as any).prototype[m] !== 'function') continue;

        fastify.route({
          method: m.toUpperCase(),
          url: '/',                 // combined with prefix at register time
          ...common,
          schema: staticSchemas[m] ?? common.schema,

          // minimal handler: return the method result; Fastify sends or
          // forwards errors
          handler: (req, reply) => {
            const view = new ViewClass(
              { req, reply, fastify: req.server, ...deps }
            );
            return (view as any)[m](req, reply);
          }
        });
      }
    });
  }
}
```

## Shortcuts with `replyWith()`

The happy path is simple: return your value, and Fastify will send it. But for
shortcuts (errors, 404, 204), we use `replyWith()` to ensure type safety.

```ts
// reply-with.mts
import type { FastifyReply } from 'fastify';
import type { FromSchema } from 'json-schema-to-ts';

export type ResponseMap = Record<number, unknown>;
export type StatusOf<R extends ResponseMap> = keyof R & number;

type BodyArg<R extends ResponseMap, S extends StatusOf<R>> =
  S extends 204 ? [] : [body: FromSchema<R[S]>];

/**
 * Sends a response with code+body, and marks this branch as terminal (`never`).
 * Trick: after reply.send(), we return `undefined as never`.
 * This way TypeScript enforces that every code path either returns a value
 * (happy path) or uses replyWith() (shortcut).
 */
export function replyWith<R extends ResponseMap, S extends StatusOf<R>>(
  reply: FastifyReply,
  status: S,
  ...args: BodyArg<R, S>
): never {
  // @ts-expect-error: generics enforce type correctness
  reply.code(status).send(args[0]);
  return undefined as never;
}
```

### Why `never`?

Because it cuts the control flow in TypeScript. If you forget to `return`
something in a method, the compiler will complain. This ensures exhaustiveness.

## Contract-First Schemas

We define schemas as the **single source of truth**, then derive TypeScript
types using `json-schema-to-ts`.

```ts
// users-schemas.mts
import type { FromSchema } from 'json-schema-to-ts';

const User = {
  type: 'object',
  properties: { id: { type: 'number' }, name: { type: 'string' } },
  required: ['id','name'],
  additionalProperties: false
} as const;

const ErrorPayload = {
  type: 'object',
  properties: { error: { type: 'string' } },
  required: ['error'],
  additionalProperties: false
} as const;

export const UsersSchemas = {
  get: {
    params: {
      type: 'object',
      properties: { id: { type: 'integer', minimum: 1 } },
      required: ['id'],
      additionalProperties: false
    },
    response: {
      200: User,
      404: ErrorPayload
    }
  } as const,
  post: {
    body: {
      type: 'object',
      properties: { name: { type: 'string', minLength: 1 } },
      required: ['name'],
      additionalProperties: false
    },
    response: {
      201: User,
      400: ErrorPayload
    }
  } as const,
  del: {
    // According to the HTTP spec, 204 No Content must *never* have a body.
    response: { 204: { type: 'null' } }
  } as const
} as const;

// Derived types
export type GetParams     = FromSchema<typeof UsersSchemas.get.params>;
export type Get200        = FromSchema<typeof UsersSchemas.get.response[200]>;
export type GetResponses  = typeof UsersSchemas.get.response;
export type PostBody      = FromSchema<typeof UsersSchemas.post.body>;
export type Post201       = FromSchema<typeof UsersSchemas.post.response[201]>;
export type PostResponses = typeof UsersSchemas.post.response;
export type DelResponses  = typeof UsersSchemas.del.response;
```

## The `UsersView`

As an example, here’s a simple `UsersView` with `get()`, `post()`, and
`delete()`, using the schemas and `replyWith()` for shortcuts.

```ts
// users-view.mts
import type { FastifyRequest, FastifyReply } from 'fastify';
import { BaseView } from './cbv.mjs';
import { replyWith } from './reply-with.mjs';
import {
  UsersSchemas,
  type GetParams, type Get200, type GetResponses,
  type PostBody,  type Post201, type PostResponses,
  type DelResponses
} from './users-schemas.mjs';

export class UsersView extends BaseView<{
  usersRepo: {
    get(id: number): Promise<Get200 | null>;
    create(d: { name: string }): Promise<Post201>;
    del(id: number): Promise<void>;
  }
}> {
  static schemas = UsersSchemas;

  // GET /users/:id
  async get(
    req: FastifyRequest<{ Params: GetParams }>, reply: FastifyReply
  ): Promise<Get200> {
    const user = await this.ctx.usersRepo.get(req.params.id);
    if (!user) {
      return replyWith<GetResponses>(reply, 404, { error: 'User not found' });
    }
    return user; // happy path
  }

  // POST /users
  async post(
    req: FastifyRequest<{ Body: PostBody }>, reply: FastifyReply
  ): Promise<Post201> {
    const name = req.body.name?.trim();
    if (!name) {
      return replyWith<PostResponses>(
        reply, 400, { error: 'name is required' }
      );
    }
    const created = await this.ctx.usersRepo.create({ name });
    reply.code(201);
    return created;
  }

  // DELETE /users/:id
  async delete(
    req: FastifyRequest<{ Params: GetParams }>, reply: FastifyReply
  ): Promise<never> {
    await this.ctx.usersRepo.del(req.params.id);
    return replyWith<DelResponses>(reply, 204);
  }
}
```

## Global Error Handler

Continuing with the example code, error handling is done once, at the Fastify
server level:

```ts
// server.mts
import Fastify from 'fastify';
import {
  JSONSchemaToTSProvider
} from 'fastify-type-provider-json-schema-to-ts';
import { UsersView } from './users-view.mjs';

const app = Fastify(
  { logger: true }
).withTypeProvider<JSONSchemaToTSProvider>();

const defaultErrorHandler = app.errorHandler;

app.setErrorHandler((err, req, reply) => {
  try { defaultErrorHandler(err, req, reply); } catch { /* noop */ }
  if (reply.sent) return;

  const status = (
    typeof (err as any)?.statusCode === 'number' ? (err as any).statusCode : 500
  );
  const payload = (err as any)?.payload
    ?? {
      error: (err as any)?.message ?? (
        status === 500 ? 'Internal Server Error' : 'Error'
      )
    };

  reply.code(status).send(payload);
});

// Example repo with fixtures
const usersRepo = {
  async get(id: number) {
    const all = [
      { id: 1, name: 'Ada'   },
      { id: 2, name: 'Grace' },
      { id: 3, name: 'Hedy'  },
      { id: 4, name: 'Radia' }
    ];
    return all.find(u => u.id === id) ?? null;
  },
  async create({ name }: { name: string }) {
    return { id: Date.now(), name };
  },
  async del(_id: number) { /* ... */ }
};

await app.register(
  UsersView.as_plugin({ deps: { usersRepo } }), { prefix: '/users' }
);
await app.listen({ port: 3000 });
```

## About Mixins

One of the nice parts of Django CBVs is inheritance and mixins. Javascript (and
by extension TypeScript) doesn’t allow multiple inheritance, but you can achieve
similar results on ES6 classes with **class factories**:

```ts
type Constructor<T = {}> = new (...args: any[]) => T;

function LoggingMixin<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    log(message: string) {
      console.log(`[${this.constructor.name}] ${message}`);
    }
  };
}

class MyView extends LoggingMixin(BaseView) {
  async get() {
    this.log('Handling GET');
    return { ok: true };
  }
}
```

This pattern lets you **compose behavior** flexibly, and types carry through
correctly.

## TypeScript Strictness

This whole design leans heavily on **contract-first schemas**:

* **Source of truth**: JSON Schema.
* **Compile-time types**: derived via `json-schema-to-ts`.
* **Runtime validation/serialization**: Fastify + AJV.
* **Type-provider (JSTT)**: glues the schemas into `req.query`, `req.body`, and
  `reply.send()` signatures.

That means if you update the schema, TypeScript will
**force you to update your code**, or it won’t compile.

## Conclusion

Starting from a bout of insomnia, I ended up building a Django-like CBV system
for Fastify, with a few additional goodies to make it production-ready and
TypeScript-friendly:

* **Automatic method routing** with `as_plugin()`.
* **HEAD registered before GET** to align with Fastify’s behavior.
* **405 Method Not Allowed** handled by `fastify-405`.
* **`replyWith()`** helper for type-safe shortcuts (404, 400, 204).
* **204 No Content** strictly without body, enforced by types.
* **Global error handler** consistent with Fastify’s default.
* **Contract-first schemas** with strict TypeScript typing.
* **Mixins via class factories** for flexible composition.

It’s not a full-blown library (yet), but it shows how powerful the combination
of **Fastify**, **TypeScript**, and a few design patterns can be. If you miss
Django’s CBVs in Node.js, this approach might scratch that itch. By the moment,
the initial code is available at <https://github.com/piranna/fastify-cbv>.

And hey, at least my insomnia was good for something.

> **Note**
>
> This post was developed collaboratively between me and
> [ChatGPT GPT-5](https://chatgpt.com/), an AI language model by
> [OpenAI](https://openai.com/). The ideas, discussion, and final decisions were
> shaped through a process of interactive brainstorming and refinement. After
> that, final formatting and edition was done by hand. You can
> [download]({{ site.baseurl }}/chatgpt-conversations/2025-09-29-Bringing-Class-Based-Views-to-Fastify-(Inspired-by-Django).html)
> a detailed discussion of the process, or get access to the
> [original conversation](https://chatgpt.com/share/68da112e-568c-8000-b319-18dfb15053ca).
>
> `#human-ai-collaboration`
