---
title: Settings
description: Settings reference.
sidebar_label: Settings
---

This page provides a reference for all the available settings that can be used to configure Marten projects.

## Common settings

### `allowed_hosts`

Default: `[] of String`

An explicit array of allowed hosts for the application.

The application has to be explictely configured to serve a list of allowed hosts. This is to mitigate HTTP Host header attacks. The strings in this array can correspond to regular domain names or subdomains (eg. `example.com` or `www.example.com`); when this is the case the Host header of the incoming request will be checked to ensure that it exactly matches one of the configured allowed hosts.

It is also possible to match all the subdomains of a specific domain by specifying prepending a `.` at the beginning of host string. For example `.example.com` will matches `example.com`, `www.example.com`, `sub.example.com`, or any other subdomains. Finally the special `*` string can be used to match any Host value, but this wildcard value should be used with caution as you wouldn't be protected against Host header attacks.

It should be noted that this setting is automatically set to the following array when a project is running in [debug mode](#debug) (unless it is explicitly set):

```crystal
[".localhost", "127.0.0.1", "[::1]"]
```

### `debug`

Default: `false`

A boolean allowing to enable or disable debug mode.

When running in debug mode, Marten will automatically provide detailed information about raised exceptions (including tracebacks) and the incoming HTTP requests. As such this mode is mostly useful for development environments.

### `host`

Default: `"127.0.0.1"`

The host the HTTP server running the application will be listening on.

### `installed_apps`

Default: `[] of Marten::Apps::Config.class`

An array of the installed app classes. Each Marten application must define a subclass of [`Marten::Apps::Config`](pathname:///api/Marten/Apps/Config.html). When those subclasses are specified in the `installed_apps` setting, the applications' models, migrations, assets, and templates will be made available to the considered project. Please refer to [Applications](../applications) in order to learn more about applications.

### `log_backend`

Default: `Log::IOBackend.new(...)`

The log backend used by the application. Any `Log::Backend` object can be used, which can allow to easily configure how logs are formatted for example.

### `log_level`

Default: `Log::Severity::Info`

The default log level used by the application. Any severity defined in the [`Log::Severity`](https://crystal-lang.org/api/Log/Severity.html) enum can be used.

### `middleware`

Default: `[] of Marten::Middleware.class`

An array of middlewares used by the application. For example:

```crystal
config.middleware = [
  Marten::Middleware::Session,
  Marten::Middleware::I18n,
  Marten::Middleware::GZip,
]
```

Middlewares are used to "hook" into Marten's request / response lifecycle. They can be used to alter or implement logics based on incoming HTTP requests and the resulting HTTP responses. Please refer to [Middlewares](../../views-and-http/middlewares) in order to learn more about middlewares.

### `port`

Default: `8000`

The port the HTTP server running the application will be listening on.

### `port_reuse`

Default: `true`

A boolean indicating whether multiple processes can bind to the same HTTP server port.

### `request_max_parameters`

Default: `1000`

The maximum number of allowed parameters per request (such as GET or POST parameters).

A large number of parameters will require more time to process and might be the sign of a denial-of-service attack, which is why this setting can be used. This protection can also be disabled by setting `request_max_parameters` to `nil`.

### `secret_key`

Default: `""`

A secret key used for cryptographic signing for the considered Marten project.

The secret key should be set to a unique and unpredictable string value. The secret key can be used by Marten to encrypt or sign messages (eg. for cookie-based sessions), or by other authentication applications.

:::warning
The `secret_key` setting value **must** be kept secret. You should never commit this setting value to source control (instead, consider loading it from environment variables for example).
:::

### `time_zone`

Default: `Time::Location.load("UTC")`

The default time zone used by the application when it comes to store date times in the database and to display them. Any [`Time::Location`](https://crystal-lang.org/api/Time/Location.html) object can be used.

### `use_x_forwarded_host`

Default: `false`

A boolean indicating whether the `X-Forwarded-Host` header is used to look for the host. This setting can be enabled if the Marten application is served behind a proxy that sets this header.

### `use_x_forwarded_port`

Default: `false`

A boolean indicating if the `X-Forwarded-Port` header is used to determine the port of a request. This setting can be enabled if the Marten application is served behind a proxy that sets this header.

### `use_x_forwarded_proto`

Default: `false`

A boolean indicating if the `X-Forwarded-Proto header` is used to determine whether a request is secure. This setting can be enabled if the Marten application is served behind a proxy that sets this header. For example if such proxy sets this header to `https`, Marten will assume that the request is secure at the application level **only** if `use_x_forwarded_proto` is set to `true`.

### `view400`

Default: `Views::Defaults::BadRequest`

The view class that should generate responses for Bad Request responses (HTTP 400). Please refer to [Error views](../../views-and-http/error-views) in order to learn more about error views.

### `view403`

Default: `Views::Defaults::PermissionDenied`

The view class that should generate responses for Permission Denied responses (HTTP 403). Please refer to [Error views](../../views-and-http/error-views) in order to learn more about error views.

### `view404`

Default: `Views::Defaults::PageNotFound`

The view class that should generate responses for Not Found responses (HTTP 404). Please refer to [Error views](../../views-and-http/error-views) in order to learn more about error views.

### `view500`

Default: `Views::Defaults::ServerError`

The view class that should generate responses for Internal Error responses (HTTP 500). Please refer to [Error views](../../views-and-http/error-views) in order to learn more about error views.

## Assets settings

## CSRF settings

## Database settings

## I18n settings

## Media files settings

## Sessions settings

## Templates settings
