---
title: Middlewares
description: Middlewares reference
---

This page provides a reference for all the available [middlewares](../middlewares.md).

## Flash middleware

**Class:** [`Marten::Middleware::Flash`](pathname:///api/0.2/Marten/Middleware/Flash.html)

Enables the use of [flash messages](../introduction.md#using-the-flash-store).

When this middleware is used, each request will have a flash store initialized and populated from the request's session store. This flash store is a hash-like object that allows to fetch or set values that are associated with specific keys, and that will only be available to the next request (after that they are cleared out).

The flash store depends on the presence of a working session store. As such, the [Session middleware](#session-middleware) MUST be used along with this middleware. Moreover, this middleware must be placed _after_ the [`Marten::Middleware::Session`](pathname:///api/0.2/Marten/Middleware/Session.html) in the [`middleware`](../../development/reference/settings.md#middleware) setting.

## GZip middleware

**Class:** [`Marten::Middleware::GZip`](pathname:///api/0.2/Marten/Middleware/GZip.html)

Compresses the content of the response if the browser supports GZip compression.

This middleware will compress responses that are big enough (200 bytes or more) if they don't already contain an Accept-Encoding header. It will also set the Vary header correctly by including Accept-Encoding in it so that caches take into account the fact that the content can be compressed or not.

The GZip middleware should be positioned before any other middleware that needs to interact with the response content in the [`middleware`](../../development/reference/settings.md#middleware) setting. This is to ensure that the compression happens only when the response content is no longer accessed.

## I18n middleware

**Class:** [`Marten::Middleware::I18n`](pathname:///api/0.2/Marten/Middleware/I18n.html)

Activates the right I18n locale based on incoming requests.

This middleware will activate the right locale based on the Accept-Language header. Only explicitly-configured locales can be activated by this middleware (that is, locales that are specified in the [`i18n.available_locales`](../../development/reference/settings.md#available_locales) and [`i18n.default_locale`](../../development/reference/settings.md#default_locale) settings). If the incoming locale can't be found in the project configuration, the default locale will be used instead.

## Session middleware

**Class:** [`Marten::Middleware::Session`](pathname:///api/0.2/Marten/Middleware/Session.html)

Enables the use of [sessions](../sessions.md).

When this middleware is used, each request will have a session store initialized according to the [sessions configuration](../../development/reference/settings.md#sessions-settings). This session store is a hash-like object that allows to fetch or set values that are associated with specific keys.

The session store is initialized from a session key that is stored as a regular cookie. If the session store ends up being empty after a request's handling, the associated cookie is deleted. Otherwise, the cookie is refreshed if the session store is modified as part of the considered request. Each session cookie is set to expire according to a configured cookie max age (the default cookie max age is 2 weeks).

## Strict-Transport-Security middleware

**Class:** [`Marten::Middleware::StrictTransportSecurity`](pathname:///api/0.2/Marten/Middleware/StrictTransportSecurity.html)

Sets the Strict-Transport-Security header in the response if it wasn't already set.

This middleware automatically sets the HTTP Strict-Transport-Security (HSTS) response header for all responses unless it was already specified in the response headers. This allows to let browsers know that the considered website should only be accessed using HTTPS, which results in future HTTP requests being automatically converted to HTTPS (up until the configured strict transport policy max age is reached).

Browsers ensure that this policy is applied for a specific duration because a `max-age` directive is embedded into the header value. This max age duration is expressed in seconds and can be configured using the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting.

:::caution
When enabling this middleware, you should probably start with small values for the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting (for example `3600` - one hour). Indeed, when browsers are aware of the Strict-Transport-Security header they will refuse to connect to your website using HTTP until the expiry time corresponding to the configured max age is reached.

This is why the value of the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting is `nil` by default: this prevents the middleware from inserting the Strict-Transport-Security response header until you actually specify a max age.
:::

## X-Frame-Options middleware

**Class:** [`Marten::Middleware::XFrameOptions`](pathname:///api/0.2/Marten/Middleware/XFrameOptions.html)

Sets the X-Frame-Options header in the response if it wasn't already set.

When this middleware is used, a X-Frame-Options header will be inserted into the HTTP response. The default value for this header (which is configurable via the [`x_frame_options`](../../development/reference/settings.md#x_frame_options) setting) is "DENY", which means that the response cannot be displayed in a frame. This allows preventing click-jacking attacks, by ensuring that the web app cannot be embedded into other sites.

On the other hand, if the `x_frame_options` is set to "SAMEORIGIN", the page can be displayed in a frame if the including site is the same as the one serving the page.
