---
title: Assets handling
description: Learn how to handle assets.
sidebar_label: Introduction
---

Web applications generally need to serve "static files" or "assets": static images, Javascript files, CSS files, etc. Marten provides a set of helpers in order to help you manage assets, refer to them, and upload them to specific storages.

## Idea and scope

Asset files can be defined in two places:

* they can be provided by [apps](../development/applications.md): for example, some apps need to rely on specific assets to provide full-featured UIs
* they can be defined in [specifically configured folders](../development/reference/settings.md#dirs) in projects

This allows applications to be relatively independent and to rely on their own assets if they need to, while also allowing projects to define assets as part of their structure.

When a project is deployed, it is expected that all these asset files will be "collected" to be placed to the final destination from which they will be served: this operation is made available through the use of the [`collectassets`](../development/reference/management-commands.md#collectassets) management command. This "destination" depends on your deployment strategy: it can be as simple as moving all these assets to a dedicated folder in your server (so that they can be served by your web server), or it can involve uploading these assets to an S3 or GCS bucket for example.

:::info
The assets flow provided by Marten is **intentionally simple**. Indeed, Marten being a backend-oriented framework, can't account for all the ways assets can be packaged and/or bundled together. Some projects might require a webpack strategy to bundle assets, some might require a fingerprinting step on top of that, and others might need something entirely different. How these toolchains are configured or set up is left to the discretion of web application developers; it is just expected that these operations will be applied _before_ the [`collectassets`](../development/reference/management-commands.md#collectassets) management command is executed.
:::

Once assets have been "collected", it is possible to generate their URLs through the use of dedicated helpers:

* by using the [assets engine](pathname:///api/0.2/Marten/Asset/Engine.html#url(filepath%3AString)%3AString-instance-method) in Crystal
* by using the [`asset`](../templates/reference/tags.md#asset) tag in templates

The way these asset URLs are generated depends on the configured [asset storage](../development/reference/settings.md#storage).

## Configuring assets

Assets can be configured through the use of the [assets settings](../development/reference/settings.md#assets-settings), which are available under the `assets` namespace.

An example assets configuration might look like this:

```crystal
config.assets.root = "assets"
config.assets.url = "/assets/"
```

### Assets storage

One of the most important asset settings is the [`storage`](../development/reference/settings.md#storage) one. Indeed, Marten uses a file storage mechanism to perform file operations related to assets (like uploading files, generating URLs, etc) by leveraging a standardized API. By default, assets use the [`Marten::Core::Store::FileSystem`](pathname:///api/0.2/Marten/Core/Storage/FileSystem.html) storage backend, which ensures that assets files are collected and placed to a specific folder in the local file system: this allows these files to then be served by a web server such as Nginx for example.

### Assets root directory

This directory - which can be configured through the use of the [`root`](../development/reference/settings.md#root) setting - corresponds to the absolute path where collected assets will be persisted (when running the [`collectassets`](../development/reference/management-commands.md#collectassets) command). By default, assets will be persisted in a folder that is relative to the Marten project's directory. Obviously, this folder should be empty before running the `collectassets` command in order to not overwrite existing files. The default value is `assets`.

### Assets URL

The asset URL is used when generating URLs for assets. This base URL will be used by the default [`Marten::Core::Store::FileSystem`](pathname:///api/0.2/Marten/Core/Storage/FileSystem.html) storage to construct asset URLs. For example, requesting a `css/App.css` asset might generate a `/assets/css/App.css` URL. The default value is `/assets/`.

### Asset directories

By default, Marten will collect asset files that are defined under an `assets` folder in [application](../development/applications.md) directories. That being said, your project will probably have asset files that are not associated with a particular app. That's why you can also define an array of additional directories where assets should be looked for.

This array of directories can be defined through the use of the [`dirs`](../development/reference/settings.md#dirs) assets setting:

```crystal
config.assets.dirs = [
  Path["src/path1/assets"],
  :"src/path2/assets",
]
```

## Resolving asset URLs

As mentioned previously, assets are collected and persisted in a specific storage. When building HTML [templates](../templates/introduction.md), you will usually need to "resolve" the URL of assets to generate the absolute URLs that should be inserted into stylesheet or script tags (for example).

One possible way to do so is to leverage the [`asset`](../templates/reference/tags.md#asset) template tag. This template tag takes a single argument corresponding to the relative path of the asset you want to resolve, and it outputs the absolute URL of the asset (depending on your assets configuration).

For example:

```html
<link rel="stylesheet" type="text/css" href="{% asset 'app/app.css' %}" />
```

In the above snippet, the `app/app.css` asset could be resolved to `/assets/app/app.css` (depending on the configuration of the project obviously).

It is also possible to resolve asset URLs programmatically in Crystal. To do so, you can leverage the [`#url`](pathname:///api/0.2/Marten/Asset/Engine.html#url(filepath%3AString)%3AString-instance-method) method of the Marten assets engine:

```crystal
Marten.assets.url("app/app.css") # => "/assets/app/app.css"
```

## Serving assets in development

Marten provides a handler that you can use to serve assets in development environments only. This handler ([`Marten::Handlers::Defaults::Development::ServeAsset`](pathname:///api/0.2/Marten/Handlers/Defaults/Development/ServeAsset.html)) is automatically mapped to a route when creating new projects through the use of the [`new`](../development/reference/management-commands.md#new) management command:

```crystal
Marten.routes.draw do
  # Other routes...

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
  end
end
```

As you can see, this route will automatically use the URL that is configured as part of the [`url`](../development/reference/settings.md#url) asset setting. For example, this means that an `app/app.css` asset would be served by the `/assets/app/app.css` route in development if the [`url`](../development/reference/settings.md#url) setting is set to `/assets/`.

:::warning
It is very important to understand that this handler should **only** be used in development environments. Indeed, the [`Marten::Handlers::Defaults::Development::ServeAsset`](pathname:///api/0.2/Marten/Handlers/Defaults/Development/ServeAsset.html) handler does not require assets to have been collected beforehand through the use of the [`collectassets`](../development/reference/management-commands.md#collectassets) management command. This means that it will try to find assets in your applications' `assets` directories and in the directories configured in the [`dirs`](../development/reference/settings.md#dirs) setting. This mechanism is helpful in development, but it is not suitable for production environments since it is inneficient and (probably) insecure.
:::

## Serving assets in production

At deployment time, you will need to run the [`collectassets`](../development/reference/management-commands.md#collectassets) management command to collect all the available assets from the applications' `assets` directories and from the directories configured in the [`dirs`](../development/reference/settings.md#dirs) setting. This command will identify and "collect" those assets, and ensure they are "uploaded" into their final destination based on the storage that is currently used.

:::tip
The [`collectassets`](../development/reference/management-commands.md#collectassets) management command should be executed _after_ your assets have been bundled and packaged. For example, your project could use a [gulp](https://gulpjs.com/) pipeline to compile your assets, minify them, and place them into a `src/app/assets/build` directory. Assuming that this directory is also specified in the [`dirs`](../development/reference/settings.md#dirs) setting, these prepared assets would also be collected and uploaded into the configured storage. Which would allow you to then refer to them from your project's templates.

Obviously, every project is different and might use different tools and a different deployment pipeline, but the overall strategy would remain the same.
:::

It should be noted that there are many ways to serve assets in production. Again, every deployment situation will be different, but we can identify a few generic strategies.

### Serving assets from a web server

As mentioned previously, Marten uses a file storage mechanism to perform file operations related to assets and to "collect" them. By default, assets use the [`Marten::Core::Store::FileSystem`](pathname:///api/0.2/Marten/Core/Storage/FileSystem.html) storage backend, which ensures that assets files are collected and placed into a specific folder in the local file system. This allows these assets to easily be served by a local web server if you have one properly configured.

For example, you could use a web server like [Apache](https://httpd.apache.org/) or [Nginx](https://nginx.org) to serve your collected assets. The way to configure these web servers will obviously vary from one solution to another, but you will likely need to define a location whose URL matches the [`url`](../development/reference/settings.md#url) setting value and that serves files from the folder where assets were collected (the [`root`](../development/reference/settings.md#root) folder).

For example, a [Nginx](https://nginx.org) server configuration allowing to serve assets under a `/assets` location could look like this:

```conf
server {
  listen 443 ssl;
  server_name myapp.example.com;

  gzip on;
  gzip_disable "msie6";
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_min_length 256;
  gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

  error_log /var/log/nginx/myapp_error.log;
  access_log /var/log/nginx/myapp_access.log;

  location /assets/ {
    expires 365d;
    alias /myapp/assets/;
  }
}
```

### Serving assets from a cloud service or CDN

To serve assets from a cloud storage (like Amazon's S3 or GCS) and (optionally) a CDN (Content Delivery Network), you will likely need to write a custom file storage and set the [`storage`](../development/reference/settings.md#storage) setting accordingly. The advantage of doing so is that you are basically delegating the responsibility of serving assets to a dedicated cloud storage, which can often translate into faster-loading pages for your end users.

:::info
Marten does not provide file storage implementations for the most frequently encountered cloud storage solutions presently. This is something that is planned for future releases though.
:::

Writing a custom file storage implementation will involve subclassing the [`Marten::Core::Storage::Base`](pathname:///api/0.2/Marten/Core/Storage/Base.html) abstract class and implementing a set of mandatory methods. The main difference compared to a "local file system" storage here is that you would need to make use of the API of the chosen cloud storage to perform low-level file operations (such as reading a file's content, verifying that a file exists, or generating a file URL).
