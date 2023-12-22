---
title: Introduction to handlers
description: Learn how to define handlers and respond to HTTP requests.
sidebar_label: Introduction
---

Handlers are classes whose responsibility is to process web requests and to return responses. They implement the necessary logic allowing to return this response, which can involve processing form data through the use of [schemas](../schemas.mdx) for example, retrieving [model records](../models-and-databases.mdx) from the database, etc. They can return responses corresponding to HTML pages, JSON objects, redirects, ...

## Writing handlers

At their core, handlers are subclasses of the [`Marten::Handler`](pathname:///api/0.2/Marten/Handlers/Base.html) class. These classes are usually defined under a `handlers` folder, at the root of a Marten project or application. Here is an example of a very simple handler:

```crystal
class SimpleHandler < Marten::Handler
  def dispatch
    respond "Hello World!"
  end
end
```

The above handler returns a `200 OK` response containing a short text, regardless of the incoming HTTP request method.

Handlers are initialized from a [`Marten::HTTP::Request`](pathname:///api/0.2/Marten/HTTP/Request.html) object and an optional set of routing parameters. Their inner logic is executed when calling the `#dispatch` method, which _must_ return a [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html) object.

When the `#dispatch` method is explicitly overridden, it is responsible for applying different logics in order to handle the various incoming HTTP request methods. For example, a handler might display an HTML page containing a form when handling a `GET` request, and it might process possible form data when handling a `POST` request:

```crystal
class FormHandler < Marten::Handler
  def dispatch
    if request.method == 'POST'
      # process form data
    else
      # return HTML page
    end
  end
end
```

It should be noted that this "dispatching" logic based on the incoming request method does not have to live inside an overridden `#dispatch` method. By default, each handler provides methods whose names match HTTP method verbs. This allows writing the logic allowing to process `GET` requests by overriding the `#get` method for example, or to process `POST` requests by overriding the `#post` method:

```crystal
class FormHandler < Marten::Handler
  def get
    # return HTML page
  end

  def post
    # process form data
  end
end
```

:::info
If a handler's logic is defined like in the above example, trying to access such handler via another HTTP verb (eg. `DELETE`) will automatically result in a "Not allowed" response (405).
:::

### The `request` and `response` objects

As mentioned previously, a handler is always initialized from an incoming HTTP request object (instance of [`Marten::HTTP::Request`](pathname:///api/0.2/Marten/HTTP/Request.html)) and is required to return an HTTP response object (instance of [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html)) as part of its `#dispatch` method.

The `request` object gives access to a set of useful information and attributes associated with the incoming request. Things like the HTTP request verb, headers, or query parameters can be accessed through this object. The most common methods that you can use are listed below:

| Method | Description |
| ----------- | ----------- |
| `#body` | Returns the raw body of the request as a string. |
| `#cookies` | Returns a hash-like object (instance of [`Marten::HTTP::Cookies`](pathname:///api/0.2/Marten/HTTP/Cookies.html)) containing the cookies associated with the request. |
| `#data` | Returns a hash-like object (instance of [`Marten::HTTP::Params::Data`](pathname:///api/0.2/Marten/HTTP/Params/Data.html)) containing the request data. |
| `#flash` | Returns a hash-like object (instance of [`Marten::HTTP::FlashStore`](pathname:///api/0.2/Marten/HTTP/FlashStore.html)) containing the flash messages available to the current request. |
| `#headers` | Returns a hash-like object (instance of [`Marten::HTTP::Headers`](pathname:///api/0.2/Marten/HTTP/Headers.html)) containing the headers embedded in the request. |
| `#host` | Returns the host associated with the considered request. |
| `#method` | Returns the considered HTTP request method (`GET`, `POST`, `PUT`, etc). |
| `#query_params` | Returns a hash-like object (instance of [`Marten::HTTP::Params::Query`](pathname:///api/0.2/Marten/HTTP/Params/Query.html)) containing the HTTP GET parameters embedded in the request. |
| `#session` | Returns a hash-like object (instance of [`Marten::HTTP::Session::Store::Base`](pathname:///api/0.2/Marten/HTTP/Session/Store/Base.html)) corresponding to the session store for the current request. |

The `response` object corresponds to the HTTP response that is returned to the client. Response objects can be created by initializing the [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html) class directly (or one of its subclasses) or by using [response helper methods](#response-helper-methods). Once initialized, these objects can be mutated to further configure what is sent back to the browser. The most common methods that you can use in this regard are listed below:

| Method | Description |
| ----------- | ----------- |
| `#content` | Returns the content of the response as a string. |
| `#content_type` | Returns the content type of the response as a string. |
| `#cookies` | Returns a hash-like object (instance of [`Marten::HTTP::Cookies`](pathname:///api/0.2/Marten/HTTP/Cookies.html)) containing the cookies that will be sent with the response. |
| `#headers` | Returns a hash-like object (instance of [`Marten::HTTP::Headers`](pathname:///api/0.2/Marten/HTTP/Headers.html)) containg the headers that will be used for the response. |
| `#status` | Returns the status of the response (eg. 200 or 404). |

### Parameters

Handlers are mapped to URLs through a [routing configuration](#mapping-handlers-to-urls). Some routes require parameters that are used by the handler to retrieve objects or perform any arbirtary logic. These parameters can be accessed by using the `#params` method, which returns a hash of all the parameters that were used to initialize the considered handler.

For example such parameters can be used to retrieve a specific model instance:

```crystal
class FormHandler < Marten::Handler
  def get
    if (record = MyModel.get(id: params["id"]))
      respond "Record found: #{record}"
    else
      respond "Record not found!", status: 404
    end
  end
end
```

### Response helper methods

Technically, it is possible to forge HTTP responses by instantiating the [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html) class directly (or one of its subclasses such as [`Marten::HTTP::Response::Found`](pathname:///api/0.2/Marten/HTTP/Response/Found.html) for example). That being said, Marten provides a set of helper methods that can be used to conveniently forge responses for various use cases:

#### `respond`

You already saw `#respond` in action in the [first example](#writing-handlers). Basically, `#respond` allows forging an HTTP response by specifying a content, a content type, and a status code:

```crystal
respond("Response content", content_type: "text/html", status: 200)
```

Unless specified, the `content_type` is set to `text/html` and the `status` is set to `200`.

#### `render`

`render` allows returning an HTTP response whose content is generated by rendering a specific [template](../templates.mdx). The template can be rendered by specifying a context hash or named tuple. For example:

```crystal
render("path/to/template.html", context: { foo: "bar" }, content_type: "text/html", status: 200)
```

Unless specified, the `content_type` is set to `text/html` and the `status` is set to `200`.

#### `redirect`

`#redirect` allows forging a redirect HTTP response. It requires a `url` and accepts an optional `permanent` argument in order to define whether a permanent redirect is returned (301 Moved Permanently) or a temporary one (302 Found):

```crystal
redirect("https://example.com", permanent: true)
```

Unless explicitly specified, `permanent` will automatically be set to `false`.

#### `#head`

`#head` allows constructing a response containing headers but without actual content. The method accepts a status code only:

```crystal
head(404)
```

#### `json`

`json` allows forging an HTTP response with the `application/json` content type. It can be used with a raw JSON string, or any serializable object:

```crystal
json({ foo: "bar" }, status: 200)
```

Unless specified, the `status` is set to `200`.

### Callbacks

Callbacks let you define logics that are triggered before or after a handler's dispatch flow. This allows you to easily intercept the incoming request and completely bypass the execution of the regular `#dispatch` method for example. Two callbacks are supported: `before_dispatch` and `after_dispatch`.

#### `before_dispatch`

`before_dispatch` callbacks are executed _before_ a request is processed as part of the handler's `#dispatch` method. For example, this capability can be leveraged to inspect the incoming request and verify that a user is logged in:

```crystal
class MyHandler < Marten::Handler
  before_dispatch :require_authenticated_user

  def get
    respond "Hello, authenticated user!"
  end

  private def require_authenticated_user
    redirect(login_url) unless user_authenticated?(request)
  end
end
```

When one of the defined `before_dispatch` callbacks returns a [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html) object, this response is always used instead of calling the handler's `#dispatch` method (the latest is thus completely bypassed).

#### `after_dispatch`

`after_dispatch` callbacks are executed _after_ a request is processed as part of the handler's `#dispatch` method. For example, such a callback can be leveraged to automatically add headers or cookies to the returned response.

```crystal
class MyHandler < Marten::Handler
  after_dispatch :add_required_header

  def get
    respond "Hello, authenticated user!"
  end

  private def add_required_header : Nil
    response!.headers["X-Foo"] = "Bar"
  end
end
```

Similarly to `#before_dispatch` callbacks, `#after_dispatch` callbacks can return a brand new [`Marten::HTTP::Response`](pathname:///api/0.2/Marten/HTTP/Response.html) object. When this is the case, this response is always used instead of the one that was returned by the handler's `#dispatch` method.

### Returning errors

It is easy to forge any error response by leveraging the `#respond` or `#head` helpers that were mentioned [previously](#response-helper-methods). Using these helpers, it is possible to forge HTTP responses that are associated with specific error status codes and specific contents. For example:

```crystal
class MyHandler < Marten::Handler
  def get
    respond "Content not found", status: 404
  end
end
```

It should be noted that Marten also support a couple of exceptions that can be raised to automatically trigger default error handlers. For example [`Marten::HTTP::Errors::NotFound`](pathname:///api/0.2/Marten/HTTP/Errors/NotFound.html) can be raised from any handler to force a 404 Not Found response to be returned. Default error handlers can be returned automatically by the framework in many situations (eg. a record is not found, or an unhandled exception is raised); you can learn more about them in [Error handlers](./error-handlers.md).

## Mapping handlers to URLs

Handlers define the logic allowing to handle incoming HTTP requests and return corresponding HTTP responses. In order to define which handler gets called for a specific URL (and what are the expected URL parameters), handlers need to be associated with a specific route. This configuration usually takes place in the `config/routes.rb` configuration file, where you can define "paths" and associate them to your handler classes:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/articles", ArticlesHandler, name: "articles"
  path "/articles/<pk:int>", ArticleDetailHandler, name: "article_detail"
end
```

Please refer to [Routing](./routing.md) for more information regarding routes configuration.

## Using cookies

Handlers are able to interact with a cookies store, that you can use to store small amounts of data on the client. This data will be persisted across requests, and will be made accessible with every incoming request.

The cookies store is an instance of [`Marten::HTTP::Cookies`](pathname:///api/0.2/Marten/HTTP/Cookies.html) and provides a hash-like interface allowing to retrieve and store data. Handlers can access it through the use of the `#cookies` method. Here is a very simple example of how to interact with cookies:

```crystal
class MyHandler < Marten::Handler
  def get
    cookies[:foo] = "bar"
    respond "Hello World!"
  end
end
```

It should be noted that the cookies store gives access to two sub stores: an encrypted one and a signed one.

`cookies.encrypted` allows defining cookies that will be signed and encrypted. Whenever a cookie is requested from this store, the raw value of the cookie will be decrypted. This is useful to create cookies whose values can't be read nor tampered by users:

```crystal
cookies.encrypted[:secret_message] = "Hello!"
```

`cookies.signed` allows defining cookies that will be signed but not encrypted. This means that whenever a cookie is requested from this store, the signed representation of the corresponding value will be verified. This is useful to create cookies that can't be tampered by users, but it should be noted that the actual data can still be read by the client.

```crystal
cookies.signed[:signed_message] = "Hello!"
```

## Using sessions

Handlers can interact with a session store, which you can use to store small amounts of data that will be persisted between requests. How much data you can persist in this store depends on the session backend being used. The default backend persists session data using an encrypted cookie. Cookies have a 4K size limit, which is usually sufficient in order to persist things like a user ID and flash messages.

The session store is an instance of [`Marten::HTTP::Session::Store::Base`](pathname:///api/0.2/Marten/HTTP/Session/Store/Base.html) and provides a hash-like interface. Handlers can access it through the use of the `#session` method. For example:

```crystal
class MyHandler < Marten::Handler
  def get
    session[:foo] = "bar"
    respond "Hello World!"
  end
end
```

Please refer to [Sessions](./sessions.md) for more information regarding configuring sessions and the available backends.

## Using the flash store

The flash store provides a way to pass basic string messages from one handler to the next one. Any string value that is set in this store will be available to the next handler processing the next request, and then it will be cleared out. Such mechanism provides a convenient way of creating one-time notification messages (such as alerts or notices).

The flash store is an instance [`Marten::HTTP::FlashStore`](pathname:///api/0.2/Marten/HTTP/FlashStore.html) and provides a hash-like interface. Handlers can access it through the use of the `#flash` method. For example:

```crystal
class MyHandler < Marten::Handler
  def post
    flash[:notice] = "Article successfully created!"
    redirect("/success")
  end
end
```

In the above example, the handler creates a flash message before returning a redirect response to another URL. It is up to the handler processing this URL to decide what to do with the flash message; this can involve rendering it as part of a base template for example.

Note that it is possible to explicitly keep the current flash messages so that they remain all accessible to the next handler processing the next request. This can be done by using the `flash.keep` method, which can take an optional argument in order to keep the message associated with a specific key only.

```crystal
flash.keep       # keeps all the flash messages for the next request
flash.keep(:foo) # keeps the message associated with the "foo" key only
```

The reverse operation is also possible: you can decide to discard all the current flash messages so that none of them will remain accessible to the next handler processing the next request. This can be done by using the `flash.discard` method, which can take an optional argument in order to discard the message associated with a specific key only.

```crystal
flash.discard       # discards all the flash messages
flash.discard(:foo) # discards the message associated with the "foo" key only
```
