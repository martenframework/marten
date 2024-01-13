---
title: Cookies
description: Learn how to use cookies to persist data on the client.
---

Handlers are able to interact with a cookies store that you can use to store small amounts of data - called cookies - on the client. This data will be persisted across requests and will be made accessible with every incoming request.

## Basic usage

### Accessing the cookie store

Cookies can be interacted with by leveraging a cookie store: an instance of [`Marten::HTTP::Cookies`](pathname:///api/0.4/Marten/HTTP/Cookies.html) that provides a hash-like interface allowing to retrieve and store cookie values. This cookie store can be accessed from three different places:

* Handlers can access it through the use of the [`#cookies`](pathname:///api/0.4/Marten/Handlers/Cookies.html#cookies(*args%2C**options)-instance-method) method.
* [`Marten::HTTP::Request`](pathname:///api/0.4/Marten/HTTP/Request.html) objects give access to the cookies associated with the request via the [`#cookies`](pathname:///api/0.4/Marten/HTTP/Request.html#cookies-instance-method) method.
* [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) objects give access to the cookies that will be returned with the HTTP response via the [`#cookies`](pathname:///api/0.4/Marten/HTTP/Response.html#cookies%3AMarten%3A%3AHTTP%3A%3ACookies-instance-method) method.


Here is a very simple example of how to interact with the cookies store within a handler:

```crystal
class MyHandler < Marten::Handler
  def get
    cookies[:foo] = "bar"
    respond "Hello World!"
  end
end
```

### Retrieving cookie values

The most simple way to retrieve the value of a cookie is to leverage the [`#[]`](pathname:///api/0.4/Marten/HTTP/Cookies.html#[](name%3AString|Symbol)-instance-method) method or one of its variants.

For example, the following lines could be used to read the value of a cookie named `foo`:

```crystal
request.cookies[:foo]  # => returns the value of "foo" or raises a KeyError if not found
request.cookies[:foo]? # => returns the value of "foo" or returns nil if not found
```

Alternatively, the [`#fetch`](pathname:///api/0.4/Marten/HTTP/Cookies.html#fetch(name%3AString|Symbol%2Cdefault%3Dnil)-instance-method) method can also be leveraged in order to execute a block or return a default value if the specified cookie is not found:

```crystal
request.cookies.fetch(:foo, "defaultval")
request.cookies.fetch(:foo) { "defaultval" }
```

### Setting cookies

The most simple way to set a new cookie is to call the [`#[]=`](pathname:///api/0.4/Marten/HTTP/Cookies.html#[]%3D(name%2Cvalue)-instance-method) method on a cookie store. For example:

```crystal
request.cookies[:foo] = "bar"
```

Calling this method will create a new cookie with the specified name and value. It should be noted that cookies created with the [`#[]=`](pathname:///api/0.4/Marten/HTTP/Cookies.html#[]%3D(name%2Cvalue)-instance-method) method will _not_ expire, will be associated with the root path (`/`), and will not be secure.

Alternatively, it is possible to leverage the [`#set`](pathname:///api/0.4/Marten/HTTP/Cookies.html#set(name%3AString|Symbol%2Cvalue%2Cexpires%3ATime|Nil%3Dnil%2Cpath%3AString%3D"/"%2Cdomain%3AString|Nil%3Dnil%2Csecure%3ABool%3Dfalse%2Chttp_only%3ABool%3Dfalse%2Csame_site%3ANil|String|Symbol%3Dnil)%3ANil-instance-method) in order to specify custom cookie properties while setting new cookie values. For example:

```crystal
request.cookies.set(
  :foo,
  "bar",
  expires: 2.days.from_now,
  secure: true,
  same_site: "lax"
)
```

Appart from the cookie name and value, the [`#set`](pathname:///api/0.4/Marten/HTTP/Cookies.html#set(name%3AString|Symbol%2Cvalue%2Cexpires%3ATime|Nil%3Dnil%2Cpath%3AString%3D"/"%2Cdomain%3AString|Nil%3Dnil%2Csecure%3ABool%3Dfalse%2Chttp_only%3ABool%3Dfalse%2Csame_site%3ANil|String|Symbol%3Dnil)%3ANil-instance-method) method allows to define some additional cookie properties:

* The cookie expiry datetime (`expires` argument).
* The cookie `path`.
* The associated `domain` (useful in order to define cross-domain cookies).
* Whether or not the cookie should be sent for HTTPS requests only (`secure` argument).
* Whether or not client-side scripts should have access to the cookie (`http_only` argument).
* The `same_site` policy (accepted values are `"lax"` or `"strict"`).

### Deleting cookies

Cookies can be deleted by leveraging the [`#delete`](pathname:///api/0.4/Marten/HTTP/Cookies.html#delete(name%3AString|Symbol%2Cpath%3AString%3D"/"%2Cdomain%3AString|Nil%3Dnil%2Csame_site%3ANil|String|Symbol%3Dnil)%3AString|Nil-instance-method) method. This method will delete a specific cookie and return its value, or `nil` if the cookie does not exist:

```crystal
request.cookies.delete(:foo)
```

Apart from the name of the cookie, this method allows to define some additional properties of the cookie to delete:

* The cookie `path`.
* The associated `domain` (useful in order to define cross-domain cookies).
* The `same_site` policy (accepted values are `"lax"` or `"strict"`).

Note that the `path`, `domain`, and `same_site` values should always be the same as the ones that were used to create the cookie in the first place. Otherwise, the cookie might not be deleted properly.

## Signed cookies

In addition to the [regular cookie store](#accessing-the-cookie-store), Marten provides a signed cookie store version (which is accessible through the use of the [`Marten::HTTP::Cookies#signed`](pathname:///api/0.4/Marten/HTTP/Cookies.html#signed-instance-method) method) where cookies are signed (but **not** encrypted). This means that whenever a cookie is requested from this store, the signed representation of the corresponding value will be verified. This is useful to create cookies that can't be tampered by users, but it should be noted that the actual data can still be read by the client technically.

All the methods that can be used with the regular cookie store that were highlighted in [Basic usage](#basic-usage) can also be used with the signed cookie store:

```crystal
# Retrieving cookies...
request.signed.cookies[:foo]
request.signed.cookies[:foo]?
request.signed.cookies.fetch(:foo, "defaultval")
request.signed.cookies.fetch(:foo) { "defaultval" }

# Setting cookies...
request.signed.cookies[:foo] = "bar"
request.signed.cookies.set(:foo, "bar", expires: 2.days.from_now)

# Deleting cookies...
request.signed.cookies.delete(:foo)
```

The signed cookie store uses a [`Marten::Core::Signer`](pathname:///api/0.4/Marten/Core/Signer.html) signer object in order to sign cookie values and to verify the signature of retrieved cookies. This means that cookies are signed with HMAC signatures that use the **SHA256** hash algorithm.

:::info
Only cookie _values_ are signed. Cookie _names_ are not signed.
:::

## Encrypted cookies

In addition to the [regular cookie store](#accessing-the-cookie-store), Marten provides an encrypted cookie store version (which is accessible through the use of the [`Marten::HTTP::Cookies#encrypted`](pathname:///api/0.4/Marten/HTTP/Cookies.html#encrypted-instance-method) method) where cookies are signed and encrypted. This means that whenever a cookie is requested from this store, the raw value of the cookie will be decrypted and its signature will be verified. This is useful to create cookies whose values can't be read nor tampered by users.

All the methods that can be used with the regular cookie store that were highlighted in [Basic usage](#basic-usage) can also be used with the encrypted cookie store:

```crystal
# Retrieving cookies...
request.encrypted.cookies[:foo]
request.encrypted.cookies[:foo]?
request.encrypted.cookies.fetch(:foo, "defaultval")
request.encrypted.cookies.fetch(:foo) { "defaultval" }

# Setting cookies...
request.encrypted.cookies[:foo] = "bar"
request.encrypted.cookies.set(:foo, "bar", expires: 2.days.from_now)

# Deleting cookies...
request.encrypted.cookies.delete(:foo)
```

The signed cookie store uses a [`Marten::Core::Encryptor`](pathname:///api/0.4/Marten/Core/Encryptor.html) encryptor object in order to encrypt and sign cookie values. This means that cookies are:

* encrypted with an **aes-256-cbc** cipher.
* signed with HMAC signatures that use the **SHA256** hash algorithm.

:::info
Only cookie _values_ are encrypted and signed. Cookie _names_ are not encrypted.
:::
