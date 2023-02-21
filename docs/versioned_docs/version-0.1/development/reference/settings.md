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

The application has to be explicitly configured to serve a list of allowed hosts. This is to mitigate HTTP Host header attacks. The strings in this array can correspond to regular domain names or subdomains (eg. `example.com` or `www.example.com`); when this is the case the Host header of the incoming request will be checked to ensure that it exactly matches one of the configured allowed hosts.

It is also possible to match all the subdomains of a specific domain by prepending a `.` at the beginning of the host string. For example `.example.com` will matches `example.com`, `www.example.com`, `sub.example.com`, or any other subdomains. Finally, the special `*` string can be used to match any Host value, but this wildcard value should be used with caution as you wouldn't be protected against Host header attacks.

It should be noted that this setting is automatically set to the following array when a project is running in [debug mode](#debug) (unless it is explicitly set):

```crystal
[".localhost", "127.0.0.1", "[::1]"]
```

### `debug`

Default: `false`

A boolean allowing to enable or disable debug mode.

When running in debug mode, Marten will automatically provide detailed information about raised exceptions (including tracebacks) and incoming HTTP requests. As such this mode is mostly useful for development environments.

### `host`

Default: `"127.0.0.1"`

The host the HTTP server running the application will be listening on.

### `installed_apps`

Default: `[] of Marten::Apps::Config.class`

An array of the installed app classes. Each Marten application must define a subclass of [`Marten::Apps::Config`](pathname:///api/0.1/Marten/Apps/Config.html). When those subclasses are specified in the `installed_apps` setting, the applications' models, migrations, assets, and templates will be made available to the considered project. Please refer to [Applications](../applications) to learn more about applications.

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

Middlewares are used to "hook" into Marten's request / response lifecycle. They can be used to alter or implement logics based on incoming HTTP requests and the resulting HTTP responses. Please refer to [Middlewares](../../handlers-and-http/middlewares) to learn more about middlewares.

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

The default time zone used by the application when it comes to storing date times in the database and displaying them. Any [`Time::Location`](https://crystal-lang.org/api/Time/Location.html) object can be used.

### `use_x_forwarded_host`

Default: `false`

A boolean indicating whether the `X-Forwarded-Host` header is used to look for the host. This setting can be enabled if the Marten application is served behind a proxy that sets this header.

### `use_x_forwarded_port`

Default: `false`

A boolean indicating if the `X-Forwarded-Port` header is used to determine the port of a request. This setting can be enabled if the Marten application is served behind a proxy that sets this header.

### `use_x_forwarded_proto`

Default: `false`

A boolean indicating if the `X-Forwarded-Proto` header is used to determine whether a request is secure. This setting can be enabled if the Marten application is served behind a proxy that sets this header. For example, if such proxy sets this header to `https`, Marten will assume that the request is secure at the application level **only** if `use_x_forwarded_proto` is set to `true`.

### `handler400`

Default: `Marten::Handlers::Defaults::BadRequest`

The handler class that should generate responses for Bad Request responses (HTTP 400). Please refer to [Error handlers](../../handlers-and-http/error-handlers) to learn more about error handlers.

### `handler403`

Default: `Marten::Handlers::Defaults::PermissionDenied`

The handler class that should generate responses for Permission Denied responses (HTTP 403). Please refer to [Error handlers](../../handlers-and-http/error-handlers) to learn more about error handlers.

### `handler404`

Default: `Marten::Handlers::Defaults::PageNotFound`

The handler class that should generate responses for Not Found responses (HTTP 404). Please refer to [Error handlers](../../handlers-and-http/error-handlers) to learn more about error handlers.

### `handler500`

Default: `Marten::Handlers::Defaults::ServerError`

The handler class that should generate responses for Internal Error responses (HTTP 500). Please refer to [Error handlers](../../handlers-and-http/error-handlers) to learn more about error handlers.

### `x_frame_options`

Default: `"DENY"`

The value to use for the X-Frame-Options header when the associated middleware is used. The value of this setting will be used by the [`Marten::Middleware::XFrameOptions`](../../handlers-and-http/reference/middlewares#x-frame-options-middleware) middleware when inserting the X-Frame-Options header in HTTP responses.

## Assets settings

Assets settings allow configuring how Marten should interact with [assets](../../files/asset-handling). These settings are all available under the `assets` namespace:

```crystal
config.assets.root = "assets"
config.assets.url = "/assets/"
```

### `app_dirs`

Default: `true`

A boolean indicating whether assets should be looked for inside installed application folders. When this setting is set to `true`, this means that assets provided by installed applications will be collected by the `collectassets` command (please refer to [Asset handling](../../files/asset-handling) for more details regarding how to manage assets in your project).

### `dirs`

Default: `[] of String`

An array of directories where assets should be looked for. The order of these directories is important as it defines the order in which assets are searched for.

It should be noted that path objects or symbols can also be used to configure this setting:

```crystal
config.assets.dirs = [
  Path["src/path1/assets"],
  :"src/path2/assets",
]
```

### `manifests`

Default: `[] of String`

An array of paths to manifest JSON files to use to resolve assets URLs. Manifest files will be used to return the right fingerprinted asset path for a generic path, which can be useful if your asset bundling strategy support this.

### `root`

Default: `"assets"`

A string containing the absolute path where collected assets will be persisted (when running the `collectassets` command). By default, assets will be persisted in a folder that is relative to the Marten project's directory. Obviously, this folder should be empty before running the `collectassets` command in order to not overwrite existing files: assets should be defined as part of your applications' `assets` folders instead.

:::info
This setting is only used if `assets.storage` is `nil`.
:::

### `storage`

Default: `nil`

An optional storage object, which must be an instance of a subclass of [`Marten::Core::Store::Base`](pathname:///api/0.1/Marten/Core/Storage/Base.html). This storage object will be used when collecting asset files to persist them in a given location.

By default this setting value is set to `nil`, which means that a [`Marten::Core::Store::FileSystem`](pathname:///api/0.1/Marten/Core/Storage/FileSystem.html) storage is automatically constructed by using the `assets.root` and `assets.url` setting values: in this situation, asset files are collected and persisted in a local directory, and it is expected that they will be served from this directory by the web server running the application.

A specific storage can be set instead to ensure that collected assets are persisted somewhere else in the cloud and served from there (for example in an Amazon's S3 bucket). When this is the case, the `assets.root` and `assets.url` setting values are basically ignored and are overridden by the use of the specified storage.

### `url`

Default: `"/assets/"`

The base URL to use when exposing asset URLs. This base URL will be used by the default [`Marten::Core::Store::FileSystem`](pathname:///api/0.1/Marten/Core/Storage/FileSystem.html) storage to construct asset URLs. For example, requesting a `css/App.css` asset might generate a `/assets/css/App.css` URL by default.

:::info
This setting is only used if `assets.storage` is `nil`.
:::

## CSRF settings

CSRF settings allow configuring how Cross-Site Request Forgeries (CSRF) attack protection measures are implemented within the considered Marten project. Please refer to [Cross-Site Request Forgery protection](../../security/csrf) for more details about this topic.

The following settings are all available under the `csrf` namespace:

```crystal
config.csrf.protection_enabled = true
config.csrf.cookie_name = "csrf-token"
```

### `cookie_domain`

Default: `nil`

An optional domain to use when setting the CSRF cookie. This can be used to share the CSRF cookie across multiple subdomains for example. For example, setting this option to `.example.com` will make it possible to send a POST request from a form on one subdomain (eg. `foo.example.com`) to another subdomain (eg. `bar.example.com `).

### `cookie_http_only`

Default: `false`

A boolean indicating whether client-side scripts should be prevented from accessing the CSRF token cookie. If this option is set to `true`, Javascript scripts won't be able to access the CSRF cookie.

### `cookie_max_age`

Default: `31_556_952` (approximately one year)

The max age (in seconds) of the CSRF cookie.

### `cookie_name`

Default: `"csrftoken"`

The name of the cookie to use for the CSRF token. This cookie name should be different than any other cookies created by your application.

### `cookie_same_site`

Default: `"Lax"`

The value of the [SameSite flag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite) to use for the CSRF cookie. Accepted values are `"Lax"`, `"Strict"`, or `"None"`.

### `cookie_secure`

Default: `false`

A boolean indicating whether to use a secure cookie for the CSRF cookie. Setting this to `true` will force browsers to send the cookie with an encrypted request over the HTTPS protocol only.

### `protection_enabled`

Default: `true`

A boolean indicating if the CSRF protection is enabled globally. When set to `true`, handlers will automatically perform a CSRF check to protect unsafe requests (ie. requests whose methods are not `GET`, `HEAD`, `OPTIONS`, or `TRACE`). Regardless of the value of this setting, it is always possible to explicitly enable or disable CSRF protection on a per-handler basis. See [Cross-Site Request Forgery protection](../../security/csrf) for more details.

### `trusted_origins`

Default: `[] of String`

An array of trusted origins.

These origins will be trusted for CSRF-protected requests (such as POST requests) and they will be used to check either the `Origin` or the `Referer` header depending on the request scheme. This is done to ensure that a specific subdomain such as `sub1.example.com` cannot issue a POST request to `sub2.example.com`. To enable CSRF-protected requests over different origins, it's possible to add trusted origins to this array. For example `https://sub1.example.com` can be configured as a trusted domain that way, but it's possible to allow CSRF-protected requests for all the subdomains of a specific domain by using `https://*.example.com`.

For example:

```crystal
config.csrf.trusted_origins = [
  "https://*.example.com",
  "https://other.example.org",
]
```

## Database settings

These settings allow configuring the databases used by the considered Marten project. At least one default database must be configured if your project makes use of [models](../../models-and-databases/introduction), and additional databases can optionally be configured as well.

```crystal
# Default database
config.database do |db|
  db.backend = :sqlite
  db.name = "default_db.db"
end

# Additional database
config.database :other do |db|
  db.backend = :sqlite
  db.name = "other_db.db"
db
```

Configuring other database backends such as MySQL or PostgreSQL usually involves specifying more connection parameters (eg. user, password, etc). For example:

```crystal
config.database do |db|
  db.backend = :postgresql
  db.host = "localhost"
  db.name = "my_db"
  db.user = "my_user"
  db.password = "my_passport"
end
```

The following options are all available when configuring a database configuration object, which is available by opening a block with the `#database` method (like in the above examples).

### `backend`

Default: `nil`

The database backend to use for connecting to the considered database. Marten supports three backends presently:

* `:mysql`
* `:postgresql`
* `:sqlite`

### `host`

Default: `nil`

A string containing the host used to connect to the database. No value means that the host will be localhost.

### `name`

Default: `nil`

The name of the database to connect to. If you use the `sqlite` backend, this can be a string or a `Path` object containing the path (absolute or relative) to the considered database path.

### `password`

Default: `nil`

A string containing the password to use to connect to the configured database.

### `port`

Default: `nil`

The port to use to connect to the configured database. No value means that the default port will be used.

### `user`

Default: `nil`

A string containing the name of the user that should be used to connect to the configured database.

## I18n settings

I18n settings allow configuring internationalization-related settings. Please refer to [Internationalization](../../i18n) for more details about how to leverage translations and localized content in your projects.

:::info
Marten makes use of [crystal-i18n](https://crystal-i18n.github.io/) to handle translations and locales. Further [configuration options](https://crystal-i18n.github.io/configuration.html) are also provided by this shard and can be leveraged by any Marten projects if necessary.
:::

The following settings are all available under the `i18n` namespace:

```crystal
config.i18n.default_locale = :fr
```

### `available_locales`

Default: `nil`

Allows defining the locales that can be activated to perform translation lookups and localizations. For example:

```crystal
config.i18n.available_locales = [:en, :fr]
```

### `default_locale`

Default: `"en"`

The default locale used by the Marten project.

## Media files settings

Media files settings allow configuring how Marten should interact with [media files](../../files/managing-files). These settings are all available under the `media_files` namespace:

```crystal
config.media_files.root = "files"
config.media_files.url = "/files/"
```

### `root`

Default: `"media"`

A string containing the absolute path where uploaded files will be persisted. By default uploaded files will be persisted in a folder that is relative to the Marten project's directory.

:::info
This setting is only used if `media_files.storage` is `nil`.
:::

### `storage`

Default: `nil`

An optional storage object, which must be an instance of a subclass of [`Marten::Core::Store::Base`](pathname:///api/0.1/Marten/Core/Storage/Base.html). This storage object will be used when uploading files to persist them in a given location.

By default, this setting value is set to `nil`, which means that a [`Marten::Core::Store::FileSystem`](pathname:///api/0.1/Marten/Core/Storage/FileSystem.html) storage is automatically constructed by using the `media_files.root` and `media_files.url` setting values: in this situation, media files are persisted in a local directory, and it is expected that they will be served from this directory by the web server running the application.

A specific storage can be set instead to ensure that uploaded files are persisted somewhere else in the cloud and served from there (for example in an Amazon's S3 bucket). When this is the case, the `media_files.root` and `media_files.url` setting values are basically ignored and are overridden by the use of the specified storage.

### `url`

Default: `"/media/"`

The base URL to use when exposing media files URLs. This base URL will be used by the default [`Marten::Core::Store::FileSystem`](pathname:///api/0.1/Marten/Core/Storage/FileSystem.html) storage to construct media files URLs. For example, requesting a `foo/bar.txt` file might generate a `/media/foo/bar.txt` URL by default.

:::info
This setting is only used if `media_files.storage` is `nil`.
:::

## Sessions settings

Sessions settings allow configuring how Marten should handle [sessions](../../handlers-and-http/introduction#using-sessions). These settings are all available under the `sessions` namespace:

```crystal
config.sessions.cookie_name = "_sessions"
config.sessions.store = :cookie
```

### `cookie_domain`

Default: `nil`

An optional domain to use when setting the session cookie. This can be used to share the session cookie across multiple subdomains.

### `cookie_http_only`

Default: `false`

A boolean indicating whether client-side scripts should be prevented from accessing the session cookie. If this option is set to `true`, Javascript scripts won't be able to access the session cookie.

### `cookie_max_age`

Default: `1_209_600` (two weeks)

The max age (in seconds) of the session cookie.


### `cookie_name`

Default: `"sessionid"`

The name of the cookie to use for the session token. This cookie name should be different than any other cookies created by your application.

### `cookie_same_site`

Default: `"Lax"`

The value of the [SameSite flag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite) to use for the session cookie. Accepted values are `"Lax"`, `"Strict"`, or `"None"`.

### `cookie_secure`

Default: `false`

A boolean indicating whether to use a secure cookie for the session cookie. Setting this to `true` will force browsers to send the cookie with an encrypted request over the HTTPS protocol only.

### `store`

Default: `"cookie"`

A string containing the identifier of the store used to handle sessions.

By default, sessions are stored within a single cookie. Cookies have a 4K size limit, which is usually sufficient to persist things like a user ID and flash messages. Other stores can be implemented and leveraged to store sessions data; see [Sessions](../../handlers-and-http/sessions) for more details about this capability.

## Strict transport security policy settings

Strict transport security policy settings allow to configure how Marten should set the HTTP Strict-Transport-Security response header when the [`Marten::Middleware::StrictTransportSecurity`](../../handlers-and-http/reference/middlewares#strict-transport-security-middleware) middleware is used:

```crystal
config.strict_transport_security.max_age = 3_600
config.strict_transport_security.include_sub_domains = true
```

### `include_sub_domains`

Default: `false`

Defines whether the `includeSubDomains` directive should be inserted into the HTTP Strict-Transport-Security response header. When this directive is set, this means that the policy will also apply to all the site's subdomains.

:::caution
You should be careful when enabling this option as this will prevent browsers from connecting to your site's subdomains using HTTP for the duration defined by the [`max_age`](#max_age) setting.
:::

### `max_age`

Default: `nil`

Defines the duration in seconds that browsers should remember that the web app must be accessed using HTTPS only. A `nil` value means that the HTTP Strict-Transport-Security response header is not inserted in responses (which is equivalent to not using the [`Marten::Middleware::StrictTransportSecurity`](../../handlers-and-http/reference/middlewares#strict-transport-security-middleware) middleware).

:::caution
You should be careful when defining a value for this setting because this will prevent browsers from connecting to your site using HTTP for the duration you specified.
:::

### `preload`

Default: `false`

Defines whether the `preload` directive should be inserted into the HTTP Strict-Transport-Security response header. Setting this to `true` means that you allow your site to be submitted to the [HSTS browser preload list](https://hstspreload.org/) by browsers.

## Templates settings

Templates settings allow configuring how Marten discovers and renders [templates](../../templates). These settings are all available under the `templates` namespace:

```crystal
config.templates.app_dirs = false
config.templates.cached = false
```

### `app_dirs`

Default: `true`

A boolean indicating whether templates should be looked for inside installed application folders (local `templates` directories). When this setting is set to `true`, this means that templates provided by installed applications can be loaded and rendered by the templates engine. Otherwise, it would not be possible to load and render these application templates.

### `cached`

Default: `false`

A boolean indicating whether templates should be kept in a memory cache upon being loaded and parsed. This setting should likely be set to `false` in development environments (where changes to templates are frequent) and set to `true` in production environments (to avoid loading and parsing the same templates multiple times).

### `context_producers`

Default: `[] of Marten::Template::ContextProducer.class`

An array of context producer classes. Context producers are helpers that ensure that common variables are automatically inserted in the template context whenever a template is rendered. See [Using context producers](../../templates/introduction#using-context-producers) to learn more about this capability.

### `dirs`

Default: `[] of String`

An array of directories where templates should be looked for. The order of these directories is important as it defines the order in which templates are searched for when requesting a template for a given path (eg. `foo/bar/template.html`).

It should be noted that path objects or symbols can also be used to configure this setting:

```crystal
config.templates.dirs = [
  Path["src/path1/templates"],
  :"src/path2/templates",
]
```
