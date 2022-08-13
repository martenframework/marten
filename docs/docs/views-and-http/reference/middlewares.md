---
title: Middlewares
description: Middlewares reference
---

This page provides a reference for all the available [middlewares](../middlewares).

## Flash middleware

**Class:** [`Marten::Middleware::Flash`](pathname:///api/Marten/Middleware/Flash.html)

Enables the use of [flash messages](../introduction#using-the-flash-store).

When this middleware is used, each request will have a flash store initialized and populated from the request's session store. This flash store is a hash-like object that allows to fetch or set values that are associated with specific keys, and that will only be available to the next request (after that they are cleared out).

The flash store depends on the presence of a working session store. As such, the [Session middleware](#session-middleware) MUST be used along with this middleware. Moreover, this middleware must be placed _after_ the [`Marten::Middleware::Session`](pathname:///api/Marten/Middleware/Session.html) in the [`middleware`](../development/reference/settings#middleware) setting.

## GZip middleware

**Class:** [`Marten::Middleware::GZip`](pathname:///api/Marten/Middleware/GZip.html)

Compresses the content of the response if the browser supports GZip compression.

This middleware will compress responses that are big enough (200 bytes or more) if they don't already contain an Accept-Encoding header. It will also set the Vary header correctly by including Accept-Encoding in it so that caches take into account the fact that the content can be compressed or not.

The GZip middleware should be positioned before any other middlewares that need to interact with the response content in the [`middleware`](../development/reference/settings#middleware) setting. This is to ensure that the compression happens only when the response content is no longer accessed.

## I18n middleware

**Class:** [`Marten::Middleware::I18n`](pathname:///api/Marten/Middleware/I18n.html)

Activates the right I18n locale based on the incoming requests.

This middleware will activate the right locale based on the Accept-Language header. Only explicitly-configured locales can be activated by this middleware (that is, locales that are specified in the [`i18n.available_locales`](../../development/reference/settings#available_locales) and [`i18n.default_locale`](../../development/reference/settings#default_locale) settings). If the incoming locale can't be found in the project configuration, the default locale will be used instead.

## Session middleware

**Class:** [`Marten::Middleware::Session`](pathname:///api/Marten/Middleware/Session.html)

Enables the use of [sessions](../sessions).

When this middleware is used, each request will have a session store initialized according to the [sessions configuration](../../development/reference/settings#sessions-settings). This session store is a hash-like object that allows to fetch or set values that are associated with specific keys.

The session store is initialized from a session key that is stored as a regular cookie. If the session store ends up being empty after a request's handling, the associated cookie is deleted. Otherwise the cookie is refreshed if the session store is modified as part of the considered request. Each session cookie is set to expire according to a configured cookie max age (the default cookie max age is 2 weeks).