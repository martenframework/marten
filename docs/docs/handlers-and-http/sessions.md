---
title: Sessions
description: Learn how to use sessions to persist data between requests.
sidebar_label: Sessions
---

Sessions can be used to store small amounts of data that will be persisted between requests, on a per-visitor basis. This data is usually stored on the backend side (depending on the chosen session storage), and it is associated with a session ID that is persisted on the client through the use of a dedicated cookie.

## Configuration

In order to use sessions, you need to make sure that the [`Marten::Middleware::Session`](pathname:///api/dev/Marten/Middleware/Session.html) middleware is part of your project's middleware chain, which can be configured in the [`middleware`](../development/reference/settings.md#middleware) setting. Note that the session middleware class is automatically added to this setting when initializing new projects.

If your project does not require the use of sessions, you can simply ensure that the [`middleware`](../development/reference/settings.md#middleware) setting does not include the [`Marten::Middleware::Session`](pathname:///api/dev/Marten/Middleware/Session.html) middleware class.

How the session ID cookie is generated can also be tweaked by leveraging the following settings:

* [`sessions.cookie_domain`](../development/reference/settings.md#cookie_domain-1)
* [`sessions.cookie_http_only`](../development/reference/settings.md#cookie_http_only-1)
* [`sessions.cookie_max_age`](../development/reference/settings.md#cookie_max_age-1)
* [`sessions.cookie_name`](../development/reference/settings.md#cookie_name-1)
* [`sessions.cookie_same_site`](../development/reference/settings.md#cookie_same_site-1)
* [`sessions.cookie_secure`](../development/reference/settings.md#cookie_secure-1)

## Session stores

How session data is actually persisted can be defined by configuring the right session store backend, which can be done through the use of the [`sessions.store`](../development/reference/settings.md#store) setting.

By default, sessions are stored within a single cookie (`:cookie` session store). Cookies have a 4K size limit, which is usually sufficient in order to persist things like a user ID and flash messages. `:cookie` is the only store that is built in the Marten web framework presently.

Other session stores can be installed as separate shards. For example, the [`marten-db-session`](https://github.com/martenframework/marten-db-session) shard can be leveraged to persist session data in the database while the [`marten-redis-session`](https://github.com/martenframework/marten-redis-session) shard can be used for persisting session data using Redis.

## Using sessions

When the [`Marten::Middleware::Session`](pathname:///api/dev/Marten/Middleware/Session.html) middleware is used, each HTTP request object will have a [`#session`](pathname:///api/dev//Marten/HTTP/Request.html#session-instance-method) method returning the session store for the current request. The session store is an instance of [`Marten::HTTP::Session::Store::Base`](pathname:///api/dev/Marten/HTTP/Session/Store/Base.html) and provides a hash-like interface:

```crystal
# Persisting values:
request.session[:foo] = "bar"

# Accessing values:
request.session[:foo]
request.session[:foo]?

# Deleting values:
request.session.delete(:foo)

# Checking emptiness:
request.session.empty?
```

Both symbol and string keys can be used when trying to interact with the session store, but only **string values** can be stored.

If you are trying to access the session store from within a handler, it should be noted that you can leverage the `#session` method instead of using the request object:

```crystal
class MyHandler < Marten::Handler
  def get
    session[:foo] = "bar"
    respond "Hello World!"
  end
end
```
