---
title: File storages
description: File storages reference.
---

## Built-in storages

### File system storage

A basic file system storage that stores files locally.

This file storage is implemented as part of the [`Marten::Core::Storage::FileSystem`](pathname:///api/dev/Marten/Core/Storage/FileSystem.html) class. It ensures that files are persisted in the local file system, where the Marten application is running.

For example:

```crystal
Marten.configure do |config|
  config.media_files.storage = Marten::Core::Storage::FileSystem.new(root: "media", base_url: "/media/")
end
```

## Other stores

Additional file storages shards are also maintained under the umbrella of the Marten project or by the community itself and can be used as part of your application depending on your specific caching requirements:

* [`marten-s3`](https://github.com/martenframework/marten-s3) provides an [S3](https://aws.amazon.com/s3/) file storage

:::info
Feel free to contribute to this page and add links to your shards if you've created file storages that are not listed here!
:::
