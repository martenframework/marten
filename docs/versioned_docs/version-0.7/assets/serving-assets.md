---
title: Serving assets
description: Learn how to serve assets in development and production.
sidebar_label: Serving assets
---

How assets are served depends on the environment: in development, Marten can serve them directly from your applications and configured directories, while in production they must first be collected and then served from their final destination.

This page covers serving assets in development, the [`collectassets`](../development/reference/management-commands.md#collectassets) management command, fingerprinting, and the main strategies for serving collected assets in production. Asset configuration and URL resolution are covered in the [assets introduction](./introduction.md).

## Serving assets in development

Marten provides a handler that you can use to serve assets in development environments only. This handler ([`Marten::Handlers::Defaults::Development::ServeAsset`](pathname:///api/0.7/Marten/Handlers/Defaults/Development/ServeAsset.html)) is automatically mapped to a route when creating new projects through the use of the [`new`](../development/reference/management-commands.md#new) management command:

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
It is very important to understand that this handler should **only** be used in development environments. Indeed, the [`Marten::Handlers::Defaults::Development::ServeAsset`](pathname:///api/0.7/Marten/Handlers/Defaults/Development/ServeAsset.html) handler does not require assets to have been collected beforehand through the use of the [`collectassets`](../development/reference/management-commands.md#collectassets) management command. This means that it will try to find assets in your applications' `assets` directories and in the directories configured in the [`dirs`](../development/reference/settings.md#dirs) setting. This mechanism is helpful in development, but it is not suitable for production environments since it is inefficient and (probably) insecure.
:::

## Serving assets in production

At deployment time, you will need to collect your project's assets and serve them from their final destination. There are many ways to do so, and every deployment situation will be different, but we can identify a few generic strategies.

### Collecting assets

You will need to run the [`collectassets`](../development/reference/management-commands.md#collectassets) management command to collect all the available assets from the applications' `assets` directories and from the directories configured in the [`dirs`](../development/reference/settings.md#dirs) setting. This command will identify and "collect" those assets, and ensure they are "uploaded" into their final destination based on the storage that is currently used.

:::tip
The [`collectassets`](../development/reference/management-commands.md#collectassets) management command should be executed _after_ your assets have been bundled and packaged. For example, your project could use a [gulp](https://gulpjs.com/) pipeline to compile your assets, minify them, and place them into a `src/app/assets/build` directory. Assuming that this directory is also specified in the [`dirs`](../development/reference/settings.md#dirs) setting, these prepared assets would also be collected and uploaded into the configured storage. Which would allow you to then refer to them from your project's templates.

Obviously, every project is different and might use different tools and a different deployment pipeline, but the overall strategy would remain the same.
:::

### Fingerprinting collected assets

The [`collectassets`](../development/reference/management-commands.md#collectassets) command provides a `--fingerprint` option. Using this option automatically fingerprints the collected assets and generates a `manifest.json` file, which maps the original file paths to their fingerprinted versions.

When the `--fingerprint` option is used, it's important to include the path to the generated `manifest.json` in the appropriate [`assets.manifests`](../development/reference/settings.md#manifests) environment config file, otherwise the collected assets can't be found when the URL is resolved.

Please refer to [Asset manifests and fingerprinting](./introduction.md#asset-manifests-and-fingerprinting) to learn more about how Marten uses manifest files when resolving asset URLs.

### Serving assets from a web server

As mentioned previously, Marten uses a file storage mechanism to perform file operations related to assets and to "collect" them. By default, assets use the [`Marten::Core::Store::FileSystem`](pathname:///api/0.7/Marten/Core/Storage/FileSystem.html) storage backend, which ensures that assets files are collected and placed into a specific folder in the local file system. This allows these assets to easily be served by a local web server if you have one properly configured.

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

Writing a custom file storage implementation will involve subclassing the [`Marten::Core::Storage::Base`](pathname:///api/0.7/Marten/Core/Storage/Base.html) abstract class and implementing a set of mandatory methods. The main difference compared to a "local file system" storage here is that you would need to make use of the API of the chosen cloud storage to perform low-level file operations (such as reading a file's content, verifying that a file exists, or generating a file URL). Please refer to [Create custom file storages](../files/how-to/create-custom-file-storages.md) for more details on how to implement a custom storage.

### Serving assets using a middleware

There are some situations where it is not possible to easily configure a web server such as [Nginx](https://nginx.org) or a third-party service (like Amazon's S3 or GCS) to serve your assets directly. To palliate this, Marten provides the [`Marten::Middleware::AssetServing`](../handlers-and-http/reference/middlewares.md#asset-serving-middleware) middleware.

The purpose of this middleware is to distribute collected assets stored under the configured assets root ([`assets.root`](../development/reference/settings.md#root) setting). These assets are assumed to have been collected using the [`collectassets`](../development/reference/management-commands.md#collectassets) management command, and it is also assumed that a "local file system" storage (such as [`Marten::Core::Store::FileSystem`](pathname:///api/0.7/Marten/Core/Storage/FileSystem.html)) is used.

In order to use this middleware, you can "insert" the corresponding class at the beginning of the [`middleware`](../development/reference/settings.md#middleware) setting when defining production settings. For example:

```crystal
Marten.configure :production do |config|
  config.middleware.unshift(Marten::Middleware::AssetServing)

  # Other settings...
end
```

It is important to note that the [`assets.url`](../development/reference/settings.md#url) setting must align with the Marten application domain or correspond to a relative URL path (e.g., /assets/) for this middleware to work correctly. This guarantees proper mapping and accessibility of the assets within the application, allowing them to be served by this middleware.
