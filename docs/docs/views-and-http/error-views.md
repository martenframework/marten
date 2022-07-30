---
title: Error views
description: Learn about the built-in error views and how to configure them.
sidebar_label: Error views
---

Marten provides default error views that you can leverage to show specific error conditions to your users: when a page is not found, when an operation is forbidden, in case of a server error, etc.

## The default error views

Marten provides default error views for the following situations:

* when **a record or a route is not found**, it will return a default Page Not Found (404) response
* when **an unexpected error occurs**, it will return a default Internal Server Error (500) response
* when **a suspicious operation is detected**, it will return a default Bad Request (400) response
* when **an action is forbidden**, it will return a default Forbidden (403) response

Note that you don't need to manually deal or interact with these default error views: they are automatically used by the Marten server when the above error conditions are met.

### Page Not Found (404)

A Page Not Found (404) response is automatically returned by the [`Marten::Views::Defaults::PageNotFound`](pathname:///api/Marten/Views/Defaults/PageNotFound.html) view when:

* a route cannot be found for an incoming request
* the [`Marten::HTTP::Errors::NotFound`](pathname:///api/Marten/Http/Errors/NotFound.html) exception is raised

:::info
If your project is running in debug mode, Marten will automatically show a different page containing specific information about the original request instead of using the default Page Not Found view.
:::

### Internal Server Error (500)

An Internal Server Error (500) response is automatically returned by the [`Marten::Views::Defaults::ServerError`](pathname:///api/Marten/Views/Defaults/ServerError.html) view when an unhandled exception is intercepted by the Marten server.

:::info
If your project is running in debug mode, Marten will automatically show a different page containing specific information about the error that occurred (traceback, request details, etc) instead of using the default Internal Server Error view.
:::

### Bad Request (400)

A Bad Request (400) response is automatically returned by the [`Marten::Views::Defaults::BadRequest`](pathname:///api/Marten/Views/Defaults/BadRequest.html) view when the [`Marten::HTTP::Errors::SuspiciousOperation`](pathname:///api/Marten/Http/Errors/SuspiciousOperation.html) exception is raised.

### Forbidden (403)

A Forbidden (403) response is automatically returned by the [`Marten::Views::Defaults::PermissionDenied`](pathname:///api/Marten/Views/Defaults/PermissionDenied.html) view when the [`Marten::HTTP::Errors::PermissionDenied`](pathname:///api/Marten/Http/Errors/PermissionDenied.html) exception is raised.

## Customizing error views

Each of the error views mentioned above can be easily customized: by default they provide a "raw" server response with a standard message, and it might make sense on a project-basis to customize how they show up to your users. As such, each view is associated with a dedicated template name that will be rendered if your project defines it. Each of these views can also be replaced by a custom one by using the appropriate settings.

These customization options are listed below:

| Error | Template name | View setting | 
| ----- | ------------- | ------------ |
| Page Not Found (404) | `404.html` | [`view404`](../development/reference/settings#view404) |
| Internal Server Error (500) | `500.html` | [`view500`](../development/reference/settings#view500) |
| Bad Request (400) | `400.html` | [`view400`](../development/reference/settings#view400) |
| Forbidden (403) | `403.html` | [`view403`](../development/reference/settings#view403) |

For example, you could define a default "Page Not Found" template by defining a `404.html` HTML template file in your project's `templates` folder.
