---
title: Error handlers
description: Learn about the built-in error handlers and how to configure them.
sidebar_label: Error handlers
---

Marten provides default error handlers that you can leverage to show specific error conditions to your users: when a page is not found, when an operation is forbidden, in case of a server error, etc.

## The default error handlers

Marten provides default error handlers for the following situations:

* when **a record or a route is not found**, it will return a default Page Not Found (404) response
* when **an unexpected error occurs**, it will return a default Internal Server Error (500) response
* when **a suspicious operation is detected**, it will return a default Bad Request (400) response
* when **an action is forbidden**, it will return a default Forbidden (403) response

Note that you don't need to manually interact with these default error handlers: they are automatically used by the Marten server when the above error conditions are met.

### Page Not Found (404)

A Page Not Found (404) response is automatically returned by the [`Marten::Handlers::Defaults::PageNotFound`](pathname:///api/dev/Marten/Handlers/Defaults/PageNotFound.html) handler when:

* a route cannot be found for an incoming request
* the [`Marten::HTTP::Errors::NotFound`](pathname:///api/dev/Marten/HTTP/Errors/NotFound.html) exception is raised

:::info
If your project is running in debug mode, Marten will automatically show a different page containing specific information about the original request instead of using the default Page Not Found handler.
:::

### Internal Server Error (500)

An Internal Server Error (500) response is automatically returned by the [`Marten::Handlers::Defaults::ServerError`](pathname:///api/dev/Marten/Handlers/Defaults/ServerError.html) handler when an unhandled exception is intercepted by the Marten server.

:::info
If your project is running in debug mode, Marten will automatically show a different page containing specific information about the error that occurred (traceback, request details, etc) instead of using the default Internal Server Error handler.
:::

### Bad Request (400)

A Bad Request (400) response is automatically returned by the [`Marten::Handlers::Defaults::BadRequest`](pathname:///api/dev/Marten/Handlers/Defaults/BadRequest.html) handler when the [`Marten::HTTP::Errors::SuspiciousOperation`](pathname:///api/dev/Marten/HTTP/Errors/SuspiciousOperation.html) exception is raised.

### Forbidden (403)

A Forbidden (403) response is automatically returned by the [`Marten::Handlers::Defaults::PermissionDenied`](pathname:///api/dev/Marten/Handlers/Defaults/PermissionDenied.html) handler when the [`Marten::HTTP::Errors::PermissionDenied`](pathname:///api/dev/Marten/HTTP/Errors/PermissionDenied.html) exception is raised.

## Customizing error handlers

Each of the error handlers mentioned above can be easily customized: by default they provide a "raw" server response with a standard message, and it might make sense on a project basis to customize how they show up to your users. As such, each handler is associated with a dedicated template name that will be rendered if your project defines it. Each of these handlers can also be replaced by a custom one by using the appropriate settings.

These customization options are listed below:

| Error | Template name | Handler setting | 
| ----- | ------------- | ------------ |
| Page Not Found (404) | `404.html` | [`handler404`](../development/reference/settings.md#handler404) |
| Internal Server Error (500) | `500.html` | [`handler500`](../development/reference/settings.md#handler500) |
| Bad Request (400) | `400.html` | [`handler400`](../development/reference/settings.md#handler400) |
| Forbidden (403) | `403.html` | [`handler403`](../development/reference/settings.md#handler403) |

For example, you could define a default "Page Not Found" template by defining a `404.html` HTML template file in your project's `templates` folder.
