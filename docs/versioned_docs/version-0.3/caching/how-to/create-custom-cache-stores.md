---
title: Create cache stores
description: How to create custom cache stores.
---

Marten lets you easily create custom [cache stores](../introduction.md#configuration-and-cache-stores) that you can then use as part of your application when it comes to perform caching operations.

## Basic store definition

Defining a cache store is as simple as creating a class that inherits from the [`Marten::Caching::Store::Base`](pathname:///api/0.3/Marten/Cache/Store/Base.html) abstract class and that implements the following methods:

* [`#clear`](pathname:///api/0.3/Marten/Cache/Store/Base.html#clear-instance-method) - called when clearing the cache
* [`#decrement`](pathname:///api/0.3/Marten/Cache/Store/Base.html#decrement(key%3AString%2Camount%3AInt32%3D1%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)%3AInt-instance-method) - called when decrementing an integer value in the cache
* [`#delete_entry`](pathname:///http://localhost:3000/docs/api/0.3/Marten/Cache/Store/Base.html#delete_entry%28key%3AString%29%3ABool-instance-method) - called when deleting an entry from the cache
* [`#increment`](pathname:///api/0.3/Marten/Cache/Store/Base.html#increment(key%3AString%2Camount%3AInt32%3D1%2Cexpires_at%3ATime|Nil%3Dnil%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Cversion%3AInt32|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil%2Ccompress%3ABool|Nil%3Dnil%2Ccompress_threshold%3AInt32|Nil%3Dnil)%3AInt-instance-method) - called when incrementing an integer value in the cache
* [`#read_entry`](pathname:///api/0.3/Marten/Cache/Store/Base.html#read_entry(key%3AString)%3AString|Nil-instance-method) - called when reading an entry in the cache
* [`#write_entry`](pathname:///api/0.3/Marten/Cache/Store/Base.html#write_entry(key%3AString%2Cvalue%3AString%2Cexpires_in%3ATime%3A%3ASpan|Nil%3Dnil%2Crace_condition_ttl%3ATime%3A%3ASpan|Nil%3Dnil)-instance-method) - called when writing an entry to the cache

For example, the following snippet implements an in-memory store that persists cache entries in a hash:

```crystal
class MemoryStore < Marten::Cache::Store::Base
  @data = {} of String => String

  def initialize(
    @namespace : String? = nil,
    @expires_in : Time::Span? = nil,
    @version : Int32? = nil,
    @compress = false,
    @compress_threshold = DEFAULT_COMPRESS_THRESHOLD
  )
    super
  end

  def clear : Nil
    @data.clear
  end

  def decrement(
    key : String,
    amount : Int32 = 1,
    expires_at : Time? = nil,
    expires_in : Time::Span? = nil,
    version : Int32? = nil,
    race_condition_ttl : Time::Span? = nil,
    compress : Bool? = nil,
    compress_threshold : Int32? = nil
  ) : Int
    apply_increment(
      key,
      amount: -amount,
      expires_at: expires_at,
      expires_in: expires_in,
      version: version,
      race_condition_ttl: race_condition_ttl,
      compress: compress,
      compress_threshold: compress_threshold
    )
  end

  def increment(
    key : String,
    amount : Int32 = 1,
    expires_at : Time? = nil,
    expires_in : Time::Span? = nil,
    version : Int32? = nil,
    race_condition_ttl : Time::Span? = nil,
    compress : Bool? = nil,
    compress_threshold : Int32? = nil
  ) : Int
    apply_increment(
      key,
      amount: amount,
      expires_at: expires_at,
      expires_in: expires_in,
      version: version,
      race_condition_ttl: race_condition_ttl,
      compress: compress,
      compress_threshold: compress_threshold
    )
  end

  private getter data

  private def apply_increment(
    key : String,
    amount : Int32 = 1,
    expires_at : Time? = nil,
    expires_in : Time::Span? = nil,
    version : Int32? = nil,
    race_condition_ttl : Time::Span? = nil,
    compress : Bool? = nil,
    compress_threshold : Int32? = nil
  )
    normalized_key = normalize_key(key.to_s)
    entry = deserialize_entry(read_entry(normalized_key))

    if entry.nil? || entry.expired? || entry.mismatched?(version || self.version)
      write(
        key: key,
        value: amount.to_s,
        expires_at: expires_at,
        expires_in: expires_in,
        version: version,
        race_condition_ttl: race_condition_ttl,
        compress: compress,
        compress_threshold: compress_threshold
      )
      amount
    else
      new_amount = entry.value.to_i + amount
      entry = Entry.new(new_amount.to_s, expires_at: entry.expires_at, version: entry.version)
      write_entry(normalized_key, serialize_entry(entry))
      new_amount
    end
  end

  private def delete_entry(key : String) : Bool
    deleted_entry = @data.delete(key)
    !!deleted_entry
  end

  private def read_entry(key : String) : String?
    data[key]?
  end

  private def write_entry(
    key : String,
    value : String,
    expires_in : Time::Span? = nil,
    race_condition_ttl : Time::Span? = nil
  )
    data[key] = value
    true
  end
end
```

## Enabling the use of custom cache stores

Custom cache store can be used by assigning an instance of the corresponding class to the [`cache_store`](../../development/reference/settings.md#cache-store1) setting.

For example:

```crystal
config.cache_store = MemoryStore.new
```
