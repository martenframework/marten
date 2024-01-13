---
title: Middlewares
description: Learn how to leverage middlewares to alter HTTP requests and responses.
sidebar_label: Middlewares
---


Middlewares are used to "hook" into Marten's request/response lifecycle. They can be used to alter or implement logic based on incoming HTTP requests and the resulting HTTP responses. These hooks take an HTTP request as their input and they output an HTTP response; in the process, they can implement whatever logic they deem necessary to perform actions based on the incoming request and/or the associated response.

## How middlewares work

Middlewares are subclasses of the [`Marten::Middleware`](pathname:///api/0.4/Marten/Middleware.html) abstract class. They must implement a `#call` method that takes a request object (instance of [`Marten::HTTP::Request`](pathname:///api/0.4/Marten/HTTP/Request.html)) and a `get_response` proc (allowing to get the final response) as arguments, and that returns a [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) object:

```crystal
class TestMiddleware < Marten::Middleware
  def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
    # Do something with the request object.

    response = get_response.call

    # Do something with the response object.

    response
  end
end
```

The `get_response` proc will either call the next middleware in the chain of middlewares, or the handler processing the request and returning the response. Which of these is actually called is a detail that is hidden by the `get_response` proc, and this does not matter at an individual middleware level.

## Activating middlewares

In order to be used, middleware classes need to be specified in the [`middleware`](../development/reference/settings.md#middleware) setting. This setting is an array of middleware classes that defines the "chain" of middlewares that will be "hooked" into Marten's request/response lifecycle.

For example:

```crystal
config.middleware = [
  Marten::Middleware::Session,
  Marten::Middleware::I18n,
  Marten::Middleware::GZip,
]
```

It should be noted that the order of middlewares is important. For example, if one of your middleware depends on a session value, you will want to ensure that it appears _after_ the `Marten::Middleware::Session` class in the `middleware` setting.

## Available middlewares

All the available middlewares are listed in the [dedicated reference section](./reference/middlewares.md).
