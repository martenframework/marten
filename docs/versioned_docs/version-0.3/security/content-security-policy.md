---
title: Content Security Policy
description: Learn how to configure the Content-Security-Policy (CSP) header.
---

Marten offers a convenient mechanism to define the Content-Security-Policy header, which serves as a safeguard against vulnerabilities such as cross-site scripting (XSS) and injection attacks. This mechanism enables the specification of a trusted resource allowlist, enhancing security measures.

## Overview

The [Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) (CSP) header is a collection of guidelines that the browser follows to allow specific sources for scripts, styles, embedded content, and more. It ensures that only these approved sources are allowed while blocking all other sources.

Utilizing the Content-Security-Policy header in a web application is a great way to mitigate or eliminate cross-site scripting (XSS) vulnerabilities. By implementing an effective Content-Security-Policy, the inclusion of inline scripts is prevented, and only scripts from trusted sources in separate files are allowed.

## Basic usage

Marten's Content-Security-Policy mechanism involves using a dedicated middleware: the [Content-Security-Policy middleware](../handlers-and-http/reference/middlewares.md#content-security-policy-middleware). To ensure that your project is using this middleware, you can add the [`Marten::Middleware::ContentSecurityPolicy`](pathname:///api/0.3/Marten/Middleware/ContentSecurityPolicy.html) class to the [`middleware`](../development/reference/settings.md#middleware) setting as follows:

```crystal title="config/settings/base.cr"
Marten.configure do |config|
  config.middleware = [
    // highlight-next-line
    Marten::Middleware::ContentSecurityPolicy,
    # Other middlewares...
    Marten::Middleware::Session,
    Marten::Middleware::Flash,
    Marten::Middleware::I18n,
  ]
end
```

The [Content-Security-Policy middleware](../handlers-and-http/reference/middlewares.md#content-security-policy-middleware) guarantees the presence of the Content-Security-Policy header in the response's headers. By default, the middleware will include a Content-Security-Policy header that corresponds to the policy defined in the [`content_security_policy`](../development/reference/settings.md#content-security-policy-settings) settings. However, if a [`Marten::HTTP::ContentSecurityPolicy`](pathname:///api/0.3/Marten/HTTP/ContentSecurityPolicy.html) object is explicitly assigned to the request object, it will take precedence over the default policy and be used instead.

When enabling the [Content-Security-Policy middleware](../handlers-and-http/reference/middlewares.md#content-security-policy-middleware), it is recommended to define a default Content-Security-Policy by leveraging the [`content_security_policy`](../development/reference/settings.md#content-security-policy-settings) settings. For example:

```crystal title="config/settings/base.cr"
Marten.configure do |config|
  config.content_security_policy.default_policy.default_src = [:self, "example.com"]
  config.content_security_policy.default_policy.script_src = [:self, :https]
end
```

## Disabling the CSP header in specific handlers

You can decide to disable or enable the use of the Content-Security-Policy header on a per-[handler](../handlers-and-http.mdx) basis. To do so, you can simply make use of the [`#exempt_from_content_security_policy`](pathname:///api/0.3/Marten/Handlers/ContentSecurityPolicy/ClassMethods.html#exempt_from_content_security_policy(exempt:Bool):Nil-instance-method) class method, which takes a single boolean as argument:

```crystal
class ProtectedHandler < Marten::Handler
  exempt_from_content_security_policy false

  # [...]
end

class UnprotectedHandler < Marten::Handler
  exempt_from_content_security_policy true

  # [...]
end
```

## Overriding the CSP header in specific handlers

Sometimes you may also need to override the content of the Content-Security-Policy header on a per-[handler](../handlers-and-http.mdx) basis. To do so, you can make use of the [`#content_security_policy`](pathname:///api/0.3/Marten/Handlers/ContentSecurityPolicy/ClassMethods.html#content_security_policy(%26content_security_policy_block%3AHTTP%3A%3AContentSecurityPolicy->)-instance-method) class method, which yields a [`Marten::HTTP::ContentSecurityPolicy`](pathname:///api/0.3/Marten/HTTP/ContentSecurityPolicy.html) object that you can configure (by adding/modifying/removing CSP directives) for the handler at hand. For example:

```crystal
class ProtectedHandler < Marten::Handler
  content_security_policy do |csp|
    csp.default_src = {:self, "example.com"}
  end

  # [...]
end
```

## Using a CSP nonce

CSP nonces serve as a valuable tool to enable the execution or rendering of specific elements, such as inline script or style tags, by the browser. When a tag contains the correct nonce value in a `nonce` attribute, the browser grants permission for its execution or rendering, while blocking others that lack the expected nonce value.

You can configure Marten so that it automatically adds a nonce to an explicit set of Content-Security-Policy directives. This can be achieved by specifying the list of intended CSP directives in the [`content_security_policy.nonce_directives`](../development/reference/settings.md#nonce_directives) setting. For example:

```crystal title="config/settings/base.cr"
Marten.configure do |config|
  config.content_security_policy.nonce_directives = ["script-src", "style-src"]
end
```

For example, if this setting is set to `["script-src", "style-src"]`, a `nonce-<b64-value>` value will be added to the `script-src` and `style-src` directives in the Content-Security-Policy header value. The nonce is a randomly generated Base64 value (generated through the use of [`Random::Secure#urlsafe_base64`](https://crystal-lang.org/api/Random.html#urlsafe_base64(n:Int=16,padding=false):String-instance-method)).

To make the browser do anything with the nonce value, you will need to include it in the attributes of the tags that you wish to mark as safe. In this light, you can use the [`Marten::HTTP::Request#content_security_policy_nonce`](pathname:///api/0.3/Marten/HTTP/Request.html#content_security_policy_nonce-instance-method) method, which returns the CSP nonce value for the current request. This method can also be called from within [templates](../templates.mdx), making it easy to generate `script` or `style` tags containing the right `nonce` attribute:

```html
<script nonce="{{ request.content_security_policy_nonce }}">
  var hello = "world";
</script>
```
