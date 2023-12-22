---
title: Caching stores
description: Caching stores reference.
sidebar_label: Stores
---

## Built-in stores

### In-memory store

This is the default store used as part of the [`cache_store`](../../development/reference/settings.md#cache_store) setting.

This cache store is implemented as part of the [`Marten::Cache::Store::Memory`](pathname:///api/0.3/Marten/Cache/Store/Memory.html) class. This cache stores all data in memory within the same process, making it a fast and reliable option for caching in single process environments. However, it's worth noting that if you're running multiple instances of your application, the cache data will not be shared between them.

For example:

```crystal
Marten.configure do |config|
  config.cache_store = Marten::Cache::Store::Memory.new.new(expires_in: 24.hours)
end
```

### Null store

A cache store implementation doesn't store any data.

This cache store is implemented as part of the [`Marten::Cache::Store::Null`](pathname:///api/0.3/Marten/Cache/Store/Null.html) class. This cache store does not store any data, but provides a way to go through the caching interface. This can be useful in development and testing environments when caching is not desired.

For example:

```crystal
Marten.configure do |config|
  config.cache_store = Marten::Cache::Store::Null.new.new(expires_in: 24.hours)
end
```

## Other stores

Additional cache stores shards are also maintained under the umbrella of the Marten project or by the community itself and can be used as part of your application depending on your specific caching requirements:

* [`marten-memcached-cache`](https://github.com/martenframework/marten-memcached-cache) provides a [Memcached](https://memcached.org) cache store
* [`marten-redis-cache`](https://github.com/martenframework/marten-redis-cache) provides a [Redis](https://redis.io) cache store

:::info
Feel free to contribute to this page and add links to your shards if you've created cache stores that are not listed here!
:::
