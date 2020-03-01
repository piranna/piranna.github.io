---
layout: post
title: Confirm deletion in RESTful APIs
---

When designing web services, it's normal to include an option to delete an
user's account. Since this is an important action (the user and its data will
dissapear from the platform), usually this is done by asking him to confirm the
operation, with several endpoints one for each operation step. Navigating
between different pages is *so* 2010-style, and there's no direct mapping at
this point between REST APIs and CRUD operations, that I've been thinking in a
REST compatible alternative: use a token.

The idea is, when you want to remove an user or resource, call to the
corresponding endpoint (ideally the resource path using the `DELETE` method),
but instead of doing inmediatly the removal operation, return an unique token
that needs to send back again to the same endpoint to confirm the operation.
The behaviour is similar to how HTTP authorization works, where a
`401 Unauthorized` error code should be returned with a challenge, so you
authenticate yourself and try the request again. I think JSON Web Tokens can be
a good fit for this, since they are signed and server can check it's issued by
itself and there's no need to store it anywhere, and also can store a timeout to
make them shortlived (since it's an user interacted operation, 5 minutes would
be more than enought). Also there's no problem by sending the token twice to the
server because it's a deletion operation, so the second time it would be already
deleted... that was exactly what we were asking for :-) To increase security,
the token should host the user (or better, the session) and resource IDs, and
the operation itself in case this mechanism is used for other operations in the
future.

Returned HTTP status codes could be a bit tricky, since the token is introducing
some kind of state. For the first request it should return `401 Unauthorized` with the deletion token (so clients must diferenciate between this operation and
a global unauthorized error), or `404 Not Found` if the resource doesn't exists.
And what should be returned in the second request? On success, according to
[RFC 7231](https://tools.ietf.org/html/rfc7231#section-4.3.5), if deletion
returns some status data it should return `200 OK` for inmediate deletions or
`202 Accepted` for queued ones, or `204 No Content` if returning nothing (my
prefered one), but on failure the token statefulness introduce the need of
several ones, like `408 Request Timeout` if the token had expired,
`409 Conflict` if server detect that the resource was modified (so a timestamp
would be needed to be included in the token itself), or `410 Gone` if resource
was already deleted in the time between the two requests by another token.
Alternatively this could be prevented by locking the resource on the first
request call, in that case the server would need to check this and return an
`423 Locked` to other requests to delete it.

By default, due to the usage of an expiration, request would be canceled
automatically if they are not send, but servers would use that expiration to add
support for explicit cancelation: the token can be send with an extra parameter
to notify the server that the operation gets canceled, and the server would use
the expiration date to response other requests with the same token with a
`401 Unauthorized` error, since the token is now invalid because it has been
already been used, providing them with a new deletion token.

Now, the drawbacks. Requests using `DELETE` method can have a body payload, but
[servers would ignore it](https://tools.ietf.org/html/rfc7231#section-4.3.5), so
better send the token using other mechanisms like query params or headers
(probably the most canonical option). Also, this has the already shown problem
of adding some state to the RESTful API, but being this state stored by the
client (servers can have some state structures for the expirations, but that's
just only as an optional optimization), this mostly doesn't affect the stateless
behaviour of RESTful APIs.

Finally, as a side note: **don't delete the actual data**. Remind the rule-0 of
databases design: deleted data is lost data. It's ok to allow users to delete
their data, but instead design and implement your system to add a new entry
instead of modify your currently stored data, or make use of a flag to indicate
that it has been removed. Your *you* of the future will thanks both us of having
done it :-) This could have some conflicts with GDPR since it would mostly be
seen as a *disable account* more like an actual user deletion, but this problem
can be fixed up to some extend by having isolated databases for your user
accounts and credentials and their actual profiles in your application. Because
you have already designed your database that way... haven't you, eh?
**Haven't you?**
