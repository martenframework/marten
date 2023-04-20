---
title: Introduction to caching
description: Learn how to leverage caching in a Marten project.
sidebar_label: Introduction
---

Marten provides a set of features allowing you to leverage caching as part of your application. By using caching, you can save the result of expensive operations so that you don't have to perform them for every request.

## Configuration and cache stores

In order to be able to leverage caching in your application, you need to configure a "cache store". A cache store allows interacting with the underlying cache system and performing basic operations such as fetching cached entries, writing new entries, etc. Depending on the chosen cache store, these operations could be performed in-memory or by leveraging external caching systems such as [Redis](https://redis.io) or [Memcached](https://memcached.org).

The global cache store used by Marten can be configured by leveraging the [`cache_store`](../development/reference/settings#cache_store) setting. All the available cache stores are listed in the [cache store reference](./reference/stores.md).

For example, the following configuration configures an in-memory cache as the global cache:

```crystal
Marten.configure do |config|
  config.cache_store = Marten::Cache::Store::Memory.new.new(expires_in: 24.hours)
end
```

:::info
By default, Marten uses an in-memory cache (instance of [`Marten::Cache::Store::Memory`](pathname:///api/dev/Marten/Cache/Store/Memory.html)). Note that this simple in-memory cache does not allow to perform cross-process caching since each process running your app will have its own private cache instance. In situations where you have multiple separate processes running your application, it's preferable to use a proper caching system such as [Redis](https://redis.io) or [Memcached](https://memcached.org), which can be done by leveraging respectively the [`marten-redis-cache`](https://github.com/martenframework/marten-redis-cache) or [`marten-memcached-cache`](https://github.com/martenframework/marten-memcached-cache) shards.

In testing environments, you could configure your project so that it uses an instance of [`Marten::Cache::Store::Null`](pathname:///api/dev/Marten/Cache/Store/Null.html) as the global cache. This approach can be helpful when caching is not necessary, but you still want to ensure that your code is passing through the caching interface.
:::

## Low-level caching

Low-level caching allows you to interact directly with the global cache store and perform caching operations. To do that, you can access the global cache store by calling the [`Marten#cache`](pathname:///api/dev/Marten.html#cache%3ACache%3A%3AStore%3A%3ABase-class-method) method.

The main way to put new values in cache is to leverage the [`#fetch`](pathname:///api/dev/Marten/Cache/Store/Base.html#fetch(key%3AString|Symbol%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Cforce%3Dfalse%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil%2C%26)%3AString|Nil-instance-method) method, which is provided on all cache stores. This method allows fetching data from the cache by using a specific key: if an entry exists for this key in cache, then the data is returned. Otherwise the return value of the block (that _must_ be specified when calling [`#fetch`](pathname:///api/dev/Marten/Cache/Store/Base.html#fetch(key%3AString|Symbol%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Cforce%3Dfalse%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil%2C%26)%3AString|Nil-instance-method)) is written to the cache and returned. This method supports a few additional arguments that allow to further customize how the entry is written to the cache (eg. the expiry time associated with the entry).

For example:

```crystal
Marten.cache("mykey", expires_in: 4.hours) do
  "myvalue"
end
```

It is worth mentioning that you can also explicitly read from the cache and write to the cache by leveraging the [`#read`](pathname:///api/dev/Marten/Cache/Store/Base.html#read(key%3AString|Symbol%2Cversion%3AInt32|Nil%3Dnil)%3AString|Nil-instance-method) and [`#write`](pathname:///api/dev/Marten/Cache/Store/Base.html#write(key%3AString|Symbol%2Cvalue%3AString%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)-instance-method) methods respectively. Verifying that a key exists can be done using the [`#exists?`](pathname:///api/dev/Marten/Cache/Store/Base.html#exists%3F(key%3AString|Symbol%2Cversion%3AInt32|Nil%3Dnil)%3ABool-instance-method) method.

For example:

```crystal
# No entry in the cache yet.
Marten.cache.read("foo") # => nil
Marten.cache.exists?("foo") => false

# Let's add the entry to the cache.
Marten.cache.write("foo", "bar", expries_in: 10.minutes) => true

# Let's read from the cache.
Marten.cache.read("foo") # => "bar"
Marten.cache.exists?("foo") => true
```
