---
title: Introduction to caching
description: Learn how to leverage caching in a Marten project.
sidebar_label: Introduction
---

Marten provides a set of features allowing you to leverage caching as part of your application. By using caching, you can save the result of expensive operations so that you don't have to perform them for every request.

## Configuration and cache stores

In order to be able to leverage caching in your application, you need to configure a "cache store". A cache store allows interacting with the underlying cache system and performing basic operations such as fetching cached entries, writing new entries, etc. Depending on the chosen cache store, these operations could be performed in-memory or by leveraging external caching systems such as [Redis](https://redis.io) or [Memcached](https://memcached.org).

The global cache store used by Marten can be configured by leveraging the [`cache_store`](../development/reference/settings.md#cache_store) setting. All the available cache stores are listed in the [cache store reference](./reference/stores.md).

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

### Basic usage

Low-level caching allows you to interact directly with the global cache store and perform caching operations. To do that, you can access the global cache store by calling the [`Marten#cache`](pathname:///api/dev/Marten.html#cache%3ACache%3A%3AStore%3A%3ABase-class-method) method.

The main way to put new values in cache is to leverage the [`#fetch`](pathname:///api/dev/Marten/Cache/Store/Base.html#fetch(key%3AString|Symbol%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Cforce%3Dfalse%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil%2C%26)%3AString|Nil-instance-method) method, which is provided on all cache stores. This method allows fetching data from the cache by using a specific key: if an entry exists for this key in cache, then the data is returned. Otherwise the return value of the block (that _must_ be specified when calling [`#fetch`](pathname:///api/dev/Marten/Cache/Store/Base.html#fetch(key%3AString|Symbol%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Cforce%3Dfalse%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil%2C%26)%3AString|Nil-instance-method)) is written to the cache and returned. This method supports a few additional arguments that allow to further customize how the entry is written to the cache (eg. the expiry time associated with the entry).

For example:

```crystal
Marten.cache.fetch("mykey", expires_in: 4.hours) do
  "myvalue"
end
```

### Reading from and writing to the cache

It is worth mentioning that you can also explicitly read from the cache and write to the cache by leveraging the [`#read`](pathname:///api/dev/Marten/Cache/Store/Base.html#read(key%3AString|Symbol%2Cversion%3AInt32|Nil%3Dnil)%3AString|Nil-instance-method) and [`#write`](pathname:///api/dev/Marten/Cache/Store/Base.html#write(key%3AString|Symbol%2Cvalue%3AString%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)-instance-method) methods respectively. Verifying that a key exists can be done using the [`#exists?`](pathname:///api/dev/Marten/Cache/Store/Base.html#exists%3F(key%3AString|Symbol%2Cversion%3AInt32|Nil%3Dnil)%3ABool-instance-method) method.

For example:

```crystal
# No entry in the cache yet.
Marten.cache.read("foo") # => nil
Marten.cache.exists?("foo") # => false

# Let's add the entry to the cache.
Marten.cache.write("foo", "bar", expires_in: 10.minutes) # => true

# Let's read from the cache.
Marten.cache.read("foo") # => "bar"
Marten.cache.exists?("foo") # => true
```

### Deleting an entry from the cache

Deleting an entry from the cache is made possible through the use of the [`#delete`](pathname:///api/dev/Marten/Cache/Store/Base.html#delete(key%3AString|Symbol)%3ABool-instance-method) method. This method takes the key of the entry to delete as argument and returns a boolean indicating whether an entry was actually deleted.

For example:

```crystal
# No entry in the cache yet.
Marten.cache.delete("foo") # => false

# Let's add an entry to the cache and then delete it.
Marten.cache.write("foo", "bar", expires_in: 10.minutes) # => true
Marten.cache.delete("foo") # => true
```

### Incrementing and decrementing values

If you need to persist integer values that are intended to be incremented or decremented, then you can leverage the [`#increment`](pathname:///api/dev/Marten/Cache/Store/Base.html#increment(key%3AString%2Camount%3AInt32%3D1%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)%3AInt-instance-method) and [`#decrement`](pathname:///api/dev/Marten/Cache/Store/Base.html#decrement(key%3AString%2Camount%3AInt32%3D1%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)%3AInt-instance-method) methods. The advantage of doing so is that the increment/decrement operation will be performed in an atomic fashion depending on the cache store you are using (eg. this is the case for the stores provided by the [`marten-memcached-cache`](https://github.com/martenframework/marten-memcached-cache) and [`marten-redis-cache`](https://github.com/martenframework/marten-redis-cache) shards).

For example:

```crystal
Marten.cache.increment("mycounter") # => 1
Marten.cache.increment("mycounter", amount: 2) # => 3
Marten.cache.decrement("mycounter") # => 2
```

### Clearing the cache

It's possible to fully clear the content of the cache by leveraging the [`#clear`](pathname:///api/dev/Marten/Cache/Store/Base.html#clear-instance-method).

For example:

```crystal
# Let's add an entry to the cache and then let's clear the cache.
Marten.cache.write("foo", "bar", expires_in: 10.minutes)
Marten.cache.clear
```

:::caution
You should be extra careful when using this method because it will fully remove all the entries stored in the cache. Depending on the store implementation, only _namespaced_ entries may be removed (this is the case for the [Redis cache store](https://github.com/martenframework/marten-redis-cache) for example).
:::

## Template fragment caching

You can leverage template fragment caching when you want to cache some parts of your [templates](../templates.mdx). This capability is enabled by the use of the [`cache`](../templates/reference/tags.md#cache) template tag.

This template tag allows caching the content of a template fragment (enclosed within the `{% cache %}...{% endcache %}` tags) for a specific duration. This caching operation is done by leveraging the configured [global cache store](#configuration-and-cache-stores). The tag itself takes at least two arguments: the name to give to the cache fragment and a cache timeout - expressed in seconds.

For example, the following snippet caches the content enclosed within the `{% cache %}...{% endcache %}` tags for a duration of 3600 seconds and associates it to the "articles" fragment name:

```html
{% cache "articles" 3600 %}
  <ul>
  {% for article in articles %}
    <li>{{ article.title }}</li>
  {% endfor %}
  </ul>
{% endcache %}
```

It's worth noting that the [`cache`](../templates/reference/tags.md#cache) template tag allows for the inclusion of additional arguments. These arguments, referred to as "vary on" values, play a crucial role in generating the cache key of the template fragment. Essentially, the cache is invalidated if the value of any of these arguments changes. This feature comes in handy when you need to ensure that the template fragment is cached based on other dynamic values that may impact the generation of the cached content itself.

For instance, suppose the cached content is dependent on the current locale. In that case, you'd want to make sure that the current locale value is taken into account while caching the template fragment. The ability to pass additional arguments as "vary on" values enables you to achieve precisely that.

For example:

```html
{% cache "articles" 3600 current_locale user.id %}
  <ul>
  {% for article in articles %}
    <li>{{ article.title }}</li>
  {% endfor %}
  </ul>
{% endcache %}
```

:::tip
The "key" used for the template fragment cache entry can be a template variable. The same goes for the cache timeout. For example:

```html
{% cache fragment_name fragment_expiry %}
  <ul>
  {% for article in articles %}
    <li>{{ article.title }}</li>
  {% endfor %}
  </ul>
{% endcache %}
```
:::
