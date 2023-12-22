---
title: Introduction to authentication
description: Learn how to set up authentication for your Marten project.
sidebar_label: Introduction
---

Marten allows the generation of new projects with a built-in authentication application that handles basic user management needs. You can then extend and adapt this application so that it accommodates your project's needs.

## Overview

Marten's [`new`](../development/reference/management-commands.md#new) management command allows the generation of projects with a built-in `auth` application. The same application can also be added to existing projects by leveraging the [`auth`](../development/reference/generators.md#auth) generator.

The generated authentication application is part of your project: it provides the necessary [models](../models-and-databases.mdx), [handlers](../handlers-and-http.mdx), [schemas](../schemas.mdx), [emails](../emailing.mdx), and [templates](../templates.mdx) allowing to authenticate users with email addresses and passwords, while also supporting standard password reset flows. On top of that, an `Auth::User` model is automatically generated for your newly created projects. Since this model is also part of your project, this means that it's possible to easily add new fields to it and generate migrations for it as well.

Here is the list of responsibilities of the generated authentication application:

* Signing up users
* Signing in users
* Signing out users
* Allowing users to reset their passwords
* Allowing users to access a basic profile page

Internally, this authentication application relies on the official [`marten-auth`](https://github.com/martenframework/marten-auth) shard. This shard implements low-level authentication operations (such as authenticating user credentials, generating securely encrypted passwords, generating password reset tokens, etc).

## Generating projects with authentication

Generating new projects with authentication can be easily achieved by leveraging the `--with-auth` option of the [`new`](../development/reference/management-commands.md#new) management command.

For example:

```bash
marten new project myblog --with-auth
```

When using this option, Marten will generate an `auth` [application](../development/applications.md) under the `src/apps/auth` folder of your project. As mentioned previously, this application provides a set of [models](../models-and-databases.mdx), [handlers](../handlers-and-http.mdx), [schemas](../schemas.mdx), [emails](../emailing.mdx), and [templates](../templates.mdx) that implement basic authentication operations.

You can test the generated authentication application by going to your application at [http://localhost:8000/auth/signup](http://localhost:8000/auth/signup) after having started the Marten development server (using `marten serve`).

:::info
You can see the full list of files generated for the `auth` application in [Generated files](./reference/generated-files.md).
:::

## Adding authentication to existing projects

The [`auth`](../development/reference/generators.md#auth) generator can be leveraged in order to add an authentication application to an existing project.

For example, the following command will add a new authentication app with the `auth` label to the current project:

```bash
marten gen auth
```

:::tip
Note that you can also customize the label given to the generated authentication app by providing an additional argument containing the intended app label:

```bash
marten gen auth my_auth
```
:::

This generator will add an authentication application under your project's `src` folder (or `src/apps` folder if it is defined). As mentioned previously, this application provides a set of [models](../models-and-databases.mdx), [handlers](../handlers-and-http.mdx), [schemas](../schemas.mdx), [emails](../emailing.mdx), and [templates](../templates.mdx) that implement basic authentication operations.

Note that the generator will also add the generated application to the [`installed_apps`](../development/reference/settings.md#installed_apps) setting and will also configure Crystal requirements for it (in the `src/project.cr` and `src/cli.cr` files). It will also add authentication-related settings to your base settings file and will add the [`marten-auth`](https://github.com/martenframework/marten-auth) shard to your project's `shard.yml` automatically.

:::info
You can see the full list of files generated for the generated authentication application in [Generated files](./reference/generated-files.md).
:::

:::tip
Don't forget to run [`marten migrate`](../development/reference/management-commands.md#migrate) after the authentication app has been generated so that your user model gets created at the database level. You should also check the `config/routes.cr` file or run the [`marten routes`](../development/reference/management-commands.md#routes) management command to see the routes associated with your generated authentication app.
:::

## Usage

This section covers the basics of how to use the `auth` application - powered by [`marten-auth`](https://github.com/martenframework/marten-auth) - that is generated when creating projects with the `--with-auth` option.

### The `User` model

The `auth` application defines a single `Auth::User` model that inherits its fields from the abstract `MartenAuth::User` model. As such, this model automatically provides the following fields:

* `id` - a [`big_int`](../models-and-databases/reference/fields.md#big_int) field containing the primary key of the user
* `email` - an [`email`](../models-and-databases/reference/fields.md#email) field containing the user's email address
* `password` - a [`string`](../models-and-databases/reference/fields.md#string) field containing the user's encrypted password
* `created_at` - a [`date_time`](../models-and-databases/reference/fields.md#date_time) field containing the user creation date
* `updated_at` - a [`date_time`](../models-and-databases/reference/fields.md#date_time) field containing the last user modification date

### Retrieving the current user

Projects that are generated with the `auth` application automatically make use of a middleware (`MartenAuth::Middleware`) that ensures that the currently authenticated user ID is associated with the current request. This means that given a specific HTTP request (instance of [`Marten::HTTP::Request`](pathname:///api/dev/Marten/HTTP/Request.html)), it is possible to identify which user is signed-in or not. Concretely, the following methods are made available on the standard [`Marten::HTTP::Request`](pathname:///api/dev/Marten/HTTP/Request.html) object in order to interact with the currently signed-in user:

| Method | Description |
| --- | --- |
| `#user_id` | Returns the current user ID associated with the considered request, or `nil` if there is no authenticated user. |
| `#user` | Returns the user associated with the request, or `nil` if there is no authenticated user. |
| `#user!` | Returns the user associated with the request, or raise `NilAssertionError` if there is no authenticated user. |
| `#user?` | Returns `true` if a user is authenticated for the request. |

This makes it possible to easily check whether a user is authenticated in handlers in order to implement different logic. For example:

```crystal
class MyHandler < Marten::Handler
  def get
    if request.user?
      respond "User ##{request.user!.id} is signed-in"
    else
      respond "No signed-in user"
    end
  end
end
```

### Creating users

Creating a user is as simple as initializing an instance of the `Auth::User` model and defining its properties. That being said it is important to note that the user's password (`password` field) must be set using the `#set_password` method: this will ensure that the _raw_ password you provide to this method is properly encrypted and that the resulting hash is assigned to the `password` field. Because of this, you should not attempt to manipulate the `password` field attribute of user records directly.

For example:

```crystal
user = Auth::User.new(email: "test@example.com") do |user|
  user.set_password("insecure")
end

user.save!
```

### Authenticating users

Authentication is the act of verifying a user's credentials. This capability is provided by the [`marten-auth`](https://github.com/martenframework/marten-auth) shard through the use of the `MartenAuth#authenticate` method: this method tries to authenticate the user associated identified by a natural key (typically, an email address) and check that the given raw password is valid. The method returns the corresponding user record if the authentication is successful. Otherwise, it returns `nil` if the credentials can't be verified because the user does not exist or because the password is invalid.

For example:

```crystal
user = MartenAuth.authenticate("test@example.com", "insecure")
if user
  puts "User credentials are valid!"
else
  puts "User credentials are not valid!"
end
```

:::caution
It is important to realize that this method _only_ verifies user credentials. **It does not sign in users** for a specific request. Signing in users (and attaching them to the current session) is handled by the `#sign_in` method, which is discussed in [Signing in users](#signing-in-users).
:::

:::info
The `MartenAuth#authenticate` method is automatically used by the handlers that are generated for your `auth` application before signing in users.
:::

### Signing in users

Signing in a user is the act of attaching it to the current session - after having verified that the associated credentials are valid (see [Authenticating users](#authenticating-users)). This capability is provided by the [`marten-auth`](https://github.com/martenframework/marten-auth) shard through the use of the `MartenAuth#sign_in` method: This method takes a request object (instance of [`Marten::HTTP::Request`](pathname:///api/dev/Marten/HTTP/Request.html)) and a user record as arguments and ensures that the user ID is attached to the current session so that they do not have to reauthenticate for every request.

For example:

```crystal
class MyHandler < Marten::Handler
  def post
    user = MartenAuth.authenticate(request.data["email"].to_s, request.data["password"].to_s)

    if user
      MartenAuth.sign_in(request, user)
      redirect reverse("auth:profile")
    else
      redirect reverse("auth:sign_in")
    end
  end
end
```

:::caution
It is important to understand that this method is intended to be used for a user record whose credentials were validated using the `#authenticate` method beforehand. See [Authenticating users](#authenticating-users) for more details.
:::

### Signing out users

The ability to sign out users is provided by the [`marten-auth`](https://github.com/martenframework/marten-auth) shard through the use of the `MartenAuth#sign_out` method: this method takes a request object (instance of [`Marten::HTTP::Request`](pathname:///api/dev/Marten/HTTP/Request.html)) as argument, removes the authenticated user ID from the current request, and flushes the associated session data.

For example:

```crystal
class MyHandler < Marten::Handler
  def get
    MartenAuth.sign_out(request)
    redirect reverse("auth:sign_in")
  end
end
```

### Changing a user's password

The ability to change a user password is provided by the `#set_password` method of the `Auth::User` model (which is inherited from the `MartenAuth::User` abstract class that is provided by the [`marten-auth`](https://github.com/martenframework/marten-auth) shard).

For example:

```crystal
use = User.get!(email: "test@example.com")
user.set_password("insecure")
user.save!
```

:::info
Passwords are encrypted using [`Crypto::Bcrypt`](https://crystal-lang.org/api/Crypto/Bcrypt.html).
:::

As mentioned previously, you should not attempt to manipulate the `password` field directly: this field contains the hash value that results from the encryption of the raw password.

### Limiting access to signed-in users

Limiting access to signed-in users can easily be achieved by leveraging the `#user?` method that is available from [`Marten::HTTP::Request`](pathname:///api/dev/Marten/HTTP/Request.html) objects. Using this method, you can easily implement  [`#before_dispatch`](../handlers-and-http/callbacks.md#before_dispatch) handler callbacks in order to redirect anonymous users to a sign-in page or to an error page.

For example:

```crystal
class UserProfileHandler < Marten::Handler
  before_dispatch :require_signed_in_user

  def get
    render "auth/profile.html" { user: request.user }
  end

  private def require_signed_in_user
    redirect reverse("auth:sign_in") unless request.user?
  end
end
```

It should be noted that the `auth` application generated for your project already contains an `Auth::RequireSignedInUser` concern module that you can include in your handlers in order to ensure that they can only be accessed by signed-in users (and that anonymous users are redirected to the sign-in page).

For example:

```crystal
class UserProfileHandler < Marten::Handler
  include Auth::RequireSignedInUser

  def get
    render "auth/profile.html" { user: request.user }
  end
end
```
