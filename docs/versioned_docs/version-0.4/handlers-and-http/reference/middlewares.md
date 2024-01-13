---
title: Middlewares
description: Middlewares reference
---

This page provides a reference for all the available [middlewares](../middlewares.md).

## Asset serving middleware

**Class:** [`Marten::Middleware::AssetServing`](pathname:///api/0.4/Marten/Middleware/AssetServing.html)

The purpose of this middleware is to handle the distribution of collected assets, which are stored under the configured assets root ([`assets.root`](../../development/reference/settings.md#root) setting). The assumption is that these assets have been "collected" using the [`collectassets`](../../development/reference/management-commands.md#collectassets) management command and that the file system storage ([`Marten::Core::Storage::FileSystem`](pathname:///api/0.4/Marten/Core/Storage/FileSystem.html)) is being used.

Additionally, the [`assets.url`](../../development/reference/settings.md#url) setting must either align with the domain of your Marten application or correspond to a relative URL path, such as `/assets/`. This ensures proper mapping and accessibility of the assets within your application (so that they can be served by this middleware).

It is important to mention that this middleware automatically applies compression to the served assets, utilizing GZip or deflate based on the Accept-Encoding header of the incoming request. Additionally, the middleware sets the Cache-Control header and defines a max-age of 3600 seconds, ensuring efficient caching of the assets.

:::info
This middleware should be placed at the first position in the [`middleware`](../../development/reference/settings.md#middleware) setting (ie. before all other configured middlewares).
:::

:::tip
This middleware is provided to make it easy to serve assets in situations where you can't easily configure a web server such as [Nginx](https://nginx.org) or a third-party service (like Amazon's S3 or GCS) to serve your assets directly.
:::

## Content-Security-Policy middleware

**Class:** [`Marten::Middleware::ContentSecurityPolicy`](pathname:///api/0.4/Marten/Middleware/ContentSecurityPolicy.html)

This middleware guarantees the presence of the Content-Security-Policy header in the response's headers. This header provides clients with the ability to limit the allowed sources of different types of content.

By default, the middleware will include a Content-Security-Policy header that corresponds to the policy defined in the [`content_security_policy`](../../development/reference/settings.md#content-security-policy-settings) settings. However, if a [`Marten::HTTP::ContentSecurityPolicy`](pathname:///api/0.4/Marten/HTTP/ContentSecurityPolicy.html) object is explicitly assigned to the request object, it will take precedence over the default policy and be used instead.

Please refer to [Content Security Policy](../../security/content-security-policy.md) to learn more about the Content-Security-Policy header and how to configure it.

## Flash middleware

**Class:** [`Marten::Middleware::Flash`](pathname:///api/0.4/Marten/Middleware/Flash.html)

Enables the use of [flash messages](../introduction.md#using-the-flash-store).

When this middleware is used, each request will have a flash store initialized and populated from the request's session store. This flash store is a hash-like object that allows to fetch or set values that are associated with specific keys, and that will only be available to the next request (after that they are cleared out).

The flash store depends on the presence of a working session store. As such, the [Session middleware](#session-middleware) MUST be used along with this middleware. Moreover, this middleware must be placed _after_ the [`Marten::Middleware::Session`](pathname:///api/0.4/Marten/Middleware/Session.html) in the [`middleware`](../../development/reference/settings.md#middleware) setting.

## GZip middleware

**Class:** [`Marten::Middleware::GZip`](pathname:///api/0.4/Marten/Middleware/GZip.html)

Compresses the content of the response if the browser supports GZip compression.

This middleware will compress responses that are big enough (200 bytes or more) if they don't already contain an Accept-Encoding header. It will also set the Vary header correctly by including Accept-Encoding in it so that caches take into account the fact that the content can be compressed or not.

The GZip middleware should be positioned before any other middleware that needs to interact with the response content in the [`middleware`](../../development/reference/settings.md#middleware) setting. This is to ensure that the compression happens only when the response content is no longer accessed.

:::note
The GZip middleware incorporates a mitigation strategy against the [BREACH attack](https://www.breachattack.com/). This strategy (described in the [Heal The Breach paper](https://ieeexplore.ieee.org/document/9754554)) involves introducing up to 100 random bytes into GZip responses to enhance the security against such attacks.
:::

## I18n middleware

**Class:** [`Marten::Middleware::I18n`](pathname:///api/0.4/Marten/Middleware/I18n.html)

Activates the right I18n locale based on incoming requests.

This middleware will activate the right locale based on the Accept-Language header or the value provided by the [locale cookie](../../development/reference/settings.md#locale_cookie_name). Only explicitly-configured locales can be activated by this middleware (that is, locales that are specified in the [`i18n.available_locales`](../../development/reference/settings.md#available_locales) and [`i18n.default_locale`](../../development/reference/settings.md#default_locale) settings). If the incoming locale can't be found in the project configuration, the default locale will be used instead.

## Session middleware

**Class:** [`Marten::Middleware::Session`](pathname:///api/0.4/Marten/Middleware/Session.html)

Enables the use of [sessions](../sessions.md).

When this middleware is used, each request will have a session store initialized according to the [sessions configuration](../../development/reference/settings.md#sessions-settings). This session store is a hash-like object that allows to fetch or set values that are associated with specific keys.

The session store is initialized from a session key that is stored as a regular cookie. If the session store ends up being empty after a request's handling, the associated cookie is deleted. Otherwise, the cookie is refreshed if the session store is modified as part of the considered request. Each session cookie is set to expire according to a configured cookie max age (the default cookie max age is 2 weeks).

## SSL redirect middleware

**Class:** [`Marten::Middleware::SSLRedirect`](pathname:///api/0.4/Marten/Middleware/SSLRedirect.html)

Redirects all non-HTTPS requests to HTTPS.

This middleware will permanently redirect all non-HTTP requests to HTTPS. By default the middleware will redirect to the incoming request's host, but a different host to redirect to can be configured with the [`ssl_redirect.host`](../../development/reference/settings.md#host-2) setting. Additionally, specific request paths can also be exempted from this SSL redirect if the corresponding strings or regexes are specified in the [`ssl_redirect.exempted_paths`](../../development/reference/settings.md#exempted_paths) setting.

## Strict-Transport-Security middleware

**Class:** [`Marten::Middleware::StrictTransportSecurity`](pathname:///api/0.4/Marten/Middleware/StrictTransportSecurity.html)

Sets the Strict-Transport-Security header in the response if it wasn't already set.

This middleware automatically sets the HTTP Strict-Transport-Security (HSTS) response header for all responses unless it was already specified in the response headers. This allows to let browsers know that the considered website should only be accessed using HTTPS, which results in future HTTP requests being automatically converted to HTTPS (up until the configured strict transport policy max age is reached).

Browsers ensure that this policy is applied for a specific duration because a `max-age` directive is embedded into the header value. This max age duration is expressed in seconds and can be configured using the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting.

:::caution
When enabling this middleware, you should probably start with small values for the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting (for example `3600` - one hour). Indeed, when browsers are aware of the Strict-Transport-Security header they will refuse to connect to your website using HTTP until the expiry time corresponding to the configured max age is reached.

This is why the value of the [`strict_security_policy.max_age`](../../development/reference/settings.md#max_age) setting is `nil` by default: this prevents the middleware from inserting the Strict-Transport-Security response header until you actually specify a max age.
:::

## X-Frame-Options middleware

**Class:** [`Marten::Middleware::XFrameOptions`](pathname:///api/0.4/Marten/Middleware/XFrameOptions.html)

Sets the X-Frame-Options header in the response if it wasn't already set.

When this middleware is used, a X-Frame-Options header will be inserted into the HTTP response. The default value for this header (which is configurable via the [`x_frame_options`](../../development/reference/settings.md#x_frame_options) setting) is "DENY", which means that the response cannot be displayed in a frame. This allows preventing click-jacking attacks, by ensuring that the web app cannot be embedded into other sites.

On the other hand, if the `x_frame_options` is set to "SAMEORIGIN", the page can be displayed in a frame if the including site is the same as the one serving the page.
