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

When a project is deployed, it is expected that all these asset files will be "collected" to be placed to the final destination from which they will be served: this operation is made available through the use of the [`collectassets`](../development/reference/management-commands.md#collectassets) management command. This "destination" depends on your deployment strategy: it can be as simple as moving all these assets to a dedicated folder in your server (so that they can be served by your web server), or it can involve uploading these assets to an S3 or GCS bucket for example. Please refer to [Serving assets](./serving-assets.md) for more details about this process.

:::info
The assets flow provided by Marten is **intentionally simple**. Indeed, Marten being a backend-oriented framework, can't account for all the ways assets can be packaged and/or bundled together. Some projects might require a webpack strategy to bundle assets, some might require a fingerprinting step on top of that, and others might need something entirely different. How these toolchains are configured or set up is left to the discretion of web application developers; it is just expected that these operations will be applied _before_ the [`collectassets`](../development/reference/management-commands.md#collectassets) management command is executed.
:::

Once assets have been "collected", it is possible to generate their URLs through the use of dedicated helpers:

* by using the [assets engine](pathname:///api/dev/Marten/Asset/Engine.html#url(filepath%3AString)%3AString-instance-method) in Crystal
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

One of the most important asset settings is the [`storage`](../development/reference/settings.md#storage) one. Indeed, Marten uses a file storage mechanism to perform file operations related to assets (like uploading files, generating URLs, etc) by leveraging a standardized API. By default, assets use the [`Marten::Core::Store::FileSystem`](pathname:///api/dev/Marten/Core/Storage/FileSystem.html) storage backend, which ensures that assets files are collected and placed to a specific folder in the local file system: this allows these files to then be served by a web server such as Nginx for example.

### Assets root directory

This directory - which can be configured through the use of the [`root`](../development/reference/settings.md#root) setting - corresponds to the absolute path where collected assets will be persisted (when running the [`collectassets`](../development/reference/management-commands.md#collectassets) command). By default, assets will be persisted in a folder that is relative to the Marten project's directory. Obviously, this folder should be empty before running the `collectassets` command in order to not overwrite existing files. The default value is `assets`.

### Assets URL

The asset URL is used when generating URLs for assets. This base URL will be used by the default [`Marten::Core::Store::FileSystem`](pathname:///api/dev/Marten/Core/Storage/FileSystem.html) storage to construct asset URLs. For example, requesting a `css/App.css` asset might generate a `/assets/css/App.css` URL. The default value is `/assets/`.

### Asset directories

By default, Marten will collect asset files that are defined under an `assets` folder in [application](../development/applications.md) directories. That being said, your project will probably have asset files that are not associated with a particular app. That's why you can also define an array of additional directories where assets should be looked for.

This array of directories can be defined through the use of the [`dirs`](../development/reference/settings.md#dirs) assets setting:

```crystal
config.assets.dirs = [
  Path["src/path1/assets"],
  :"src/path2/assets",
]
```

### Asset manifests and fingerprinting

Fingerprinting involves adding a unique string of characters to the filename of each asset. This enables the browser to cache the file securely. When an asset is modified, its fingerprint changes, prompting the browser to retrieve and use the updated version.

Modern asset bundling tools often provide the capability to generate manifest files. These manifest files typically contain mappings between the original asset filenames and their corresponding fingerprinted versions. Marten supports configuring paths to these manifest files so that [resolving assets](#resolving-asset-urls) produces URLs that automatically include the correct fingerprinted version of each asset.

This can be achieved by adding manifest paths to the [`assets.manifests`](../development/reference/settings.md#manifests) setting. For example:

```crystal
config.assets.manifests = [
  "src/assets/build/manifest.json",
]
```

It is assumed that the files whose paths are referenced in this setting are regular JSON manifests, containing mappings between original asset file names and their fingerprinted versions. For example:

```json
{
  "app/home.css": "app/home.9495841be78cdf06c45d.css",
  "app/home.js": "app/home.9495841be78cdf06c45d.js"
}
```

Considering the above manifest example, trying to resolve `app/home.css` would produce a URL ending with `app/home.9495841be78cdf06c45d.css`:

```crystal
Marten.assets.url("app/home.css") # => "/assets/app/home.9495841be78cdf06c45d.css"
```

:::info
The [`collectassets`](../development/reference/management-commands.md#collectassets) command can also fingerprint assets at collect time. See [Fingerprinting collected assets](./serving-assets.md#fingerprinting-collected-assets) for more details.
:::

## Resolving asset URLs

As mentioned previously, assets are collected and persisted in a specific storage. When building HTML [templates](../templates/introduction.md), you will usually need to "resolve" the URL of assets to generate the absolute URLs that should be inserted into stylesheet or script tags (for example).

One possible way to do so is to leverage the [`asset`](../templates/reference/tags.md#asset) template tag. This template tag takes a single argument corresponding to the relative path of the asset you want to resolve, and it outputs the absolute URL of the asset (depending on your assets configuration).

For example:

```html
<link rel="stylesheet" type="text/css" href="{% asset 'app/app.css' %}" />
```

In the above snippet, the `app/app.css` asset could be resolved to `/assets/app/app.css` (depending on the configuration of the project obviously).

It is also possible to resolve asset URLs programmatically in Crystal. To do so, you can leverage the [`#url`](pathname:///api/dev/Marten/Asset/Engine.html#url(filepath%3AString)%3AString-instance-method) method of the Marten assets engine:

```crystal
Marten.assets.url("app/app.css") # => "/assets/app/app.css"
```

Please refer to [Serving assets](./serving-assets.md) to learn how to serve assets in development and in production.
