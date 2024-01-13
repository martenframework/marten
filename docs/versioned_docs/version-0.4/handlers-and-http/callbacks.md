---
title: Handler callbacks
description: Learn how to define handler callbacks.
sidebar_label: Callbacks
---

Callbacks enable you to define logic that is triggered at different stages of a handler's lifecycle. This feature allows you to intercept incoming requests and potentially bypass the standard `#dispatch` method. This document covers the available callbacks and introduces you to the associated API, which you can use to define hooks in your handlers.

## Overview

As stated above, callbacks are methods that will be called when specific events occur for a specific handler instance. They need to be registered explicitly in your handler classes. There are many types of of callbacks: some are [shared between all types of handlers](#shared-handler-callbacks) while some others are specific to some kinds of generic handlers. For most types of callbacks, it is generally possible to register "before" or "after" callbacks.

Registering a callback is as simple as calling the right callback macro (eg. `#before_dispatch`) with a symbol of the name of the method to call when the callback is executed. 

For example, the following handler leverages the [`#before_dispatch`](#before_dispatch) callback in order to redirect the user to a login page if they are not already authenticated:

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

## Shared handler callbacks

The following callbacks are shared between all types of handlers.

### `before_dispatch`

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

When one of the defined `before_dispatch` callbacks returns a [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) object (like this is the case in the above example), this response is always used instead of calling the handler's `#dispatch` method (the latest is thus completely bypassed).

### `after_dispatch`

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

Similarly to `#before_dispatch` callbacks, `#after_dispatch` callbacks can return a brand new [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) object. When this is the case, this response is always used instead of the one that was returned by the handler's `#dispatch` method.

### `before_render`

`before_render` callbacks are invoked prior to rendering a template when generating a response that incorporates its content. This means that these callbacks are executed as part of the [`#render`](./introduction.md#render) helper method and when rendering templates as part of subclasses of the [`Marten::Handlers::Template`](./generic-handlers.md#rendering-a-template) generic handler.

Typically, these callbacks are used to add new variables to the [global template context](./introduction.md#global-template-context), in order to make them accessible to the template runtime. For example:

```crystal
class MyHandler < Marten::Handlers::Template
  template_name "app/my_template.html"
  before_render :add_variable_to_context

  private def add_variable_to_context : Nil
    context["foo"] = "bar"
  end
end
```

Note that `before_render` callbacks can technically be used to return a [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) object. When this situation arises, this response always takes precedence over the one that would've been returned following the rendering of the template.

## Schema handler callbacks

The following callbacks are only available for handlers that inherit from the [schema handler](./reference/generic-handlers.md#processing-a-schema). That is, handlers that inherit from [`Marten::Handlers::Schema`](pathname:///api/0.4/Marten/Handlers/Schema.html), but also handlers that inherit from [`Marten::Handlers::RecordCreate`](pathname:///api/0.4/Marten/Handlers/RecordCreate.html) and [`Marten::Handlers::RecordUpdate`](pathname:///api/0.4/Marten/Handlers/RecordUpdate.html).

These callbacks let you define logics that are triggered before or after the validation of the schema. This allows you to easily intercept validation and handle the response independently of the schema validity. All these callbacks can optionally return a [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) object. When an HTTP response is returned,
all following callbacks are skipped and the obtained response is returned directly, thus bypassing responses that might have been returned after by the handler.

### `before_schema_validation`

`before_schema_validation` callbacks are executed _before_ a schema is checked for validity. For example, this capability can be leveraged to set an attribute on the schema object before the schema validity is checked:

```crystal
class ArticleCreateHandler < Marten::Handlers::Schema
  success_url "https://example.com/articles/list"
  template_name "articles/create.html"
  schema ArticleSchema

  before_schema_validation :prepare_schema

  private def prepare_schema
    schema.user = request.user
  end
end
```

### `after_schema_validation`

`after_schema_validation` callbacks are executed right _after_ a schema is checked for validity. For example, this capability can be leveraged to call a custom method on the schema instance:

```crystal
class ArticleCreateHandler < Marten::Handlers::Schema
  success_url "https://example.com/articles/list"
  template_name "articles/create.html"
  schema ArticleSchema

  after_schema_validation :run_schema_post_validation

  private def run_schema_post_validation : Nil
    schema.trigger_post_something
  end
end
```

### `after_successful_schema_validation`

`after_successful_schema_validation` callbacks are executed right _after_ a schema is checked for validity (and after possible [`after_schema_validation`](#after_schema_validation) callbacks), and only if the schema validation was successful.
For example, this capability can be leveraged to create a flash message:

```crystal
class ArticleCreateHandler < Marten::Handlers::Schema
  success_url "https://example.com/articles/list"
  template_name "articles/create.html"
  schema ArticleSchema

  after_successful_schema_validation :generate_success_flash_message

  private def generate_success_flash_message : Nil
    flash[:notice] = "Article successfully created!"
  end
end
```

### `after_failed_schema_validation`

`after_failed_schema_validation` callbacks are executed right _after_ a schema is checked for validity (and after possible
[`after_schema_validation`](#after_schema_validation) callbacks), but only if the schema validation failed. For example, this capability can be leveraged to create a flash message:

```crystal
class ArticleCreateHandler < Marten::Handlers::Schema
  success_url "https://example.com/articles/list"
  template_name "articles/create.html"
  schema ArticleSchema

  after_failed_schema_validation :generate_failure_flash_message

  private def generate_failure_flash_message : Nil
    flash[:notice] = "Article creation failed!"
  end
end
```
