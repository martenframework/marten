---
title: Testing
description: Learn how to test your Marten project.
sidebar_label: Testing
---

This section covers the basics regarding how to test a Marten project and the various tools that you can leverage in this regard.

## The basics

You should test your Marten project to ensure that it adheres to the specifications it was built for. Like any Crystal project, Marten lets you write "specs" (see the [official documentation related to testing in Crystal](https://crystal-lang.org/reference/guides/testing.html) to learn more about those).

By default, when creating a project through the use of the [`new`](./reference/management-commands.md#new) management command, Marten will automatically create a `spec/` folder at the root of your project structure. This folder contains a unique `spec_helper.cr` file allowing you to initialize the test environment for your Marten project.

This file should look something like this:

```crystal title=spec/spec_helper.cr
ENV["MARTEN_ENV"] = "test"

require "spec"
require "marten"
require "marten/spec"

require "../src/project"
```

As you can see, the `spec_helper.cr` file forces the Marten environment variable to be set to `test` and requires the spec library as well as Marten and your actual project. This file should be required by all your spec files.

:::info
It's very important to require `marten/spec` in your top-level spec helper as this will ensure that the mandatory spec callbacks are configured for your spec suite (eg. in order to ensure that your database is properly set up before each spec is executed).
:::

When it comes to running your tests, you can simply make use of the standard [`crystal spec`](https://crystal-lang.org/reference/man/crystal/index.html#crystal-spec) command.

## Writing tests

To write tests, you should write regular [specs](https://crystal-lang.org/reference/guides/testing.html) and ensure that your spec files always require the `spec/spec_helper.cr` file.

For example:

```crystal
require "./spec_helper"

describe MySuperAbstraction do
  describe "#foo" do
    it "returns bar" do
      obj = MySuperAbstraction.new
      obj.foo.should eq "bar"
    end
  end
end
```

You are encouraged to organize your spec files by following the structure of your projects. For example, you could create a `models` folder and define specs related to your models in it.

:::tip
When organizing spec files across multiple folders, one good practice is to define a `spec_helper.cr` file at each level of your folders structure. These additional `spec_helper.cr` files should require the same file from the parent folder.

For example:

```crystal title=spec/models/spec_helper.cr
require "../spec_helper"
```

```crystal title=spec/models/article_spec.cr
require "./spec_helper"

describe Article do
  # ...
end
```
:::

## Running tests

As mentioned before, running specs involves making use of the standard [`crystal spec`](https://crystal-lang.org/reference/man/crystal/index.html#crystal-spec) command.

### The test environment

By default, the [`new`](./reference/management-commands.md#new) management command always creates a `test` environment when generating new projects. As such, you should ensure that the `MARTEN_ENV` environment variable is set to `test` when running your Crystal specs. It should also be reminded that this `test` environment is associated with a dedicated settings file where test-related settings can be specified and/or overridden if necessary (see [Settings](./settings.md#environments) for more details about this).

### The test database

Marten **must** use a different database when running tests in order to not tamper with your regular database. Indeed, the database used in the context of specs will be flushed and generated automatically every time the specs suite is executed. You should not set these database names to the same names as the ones used for your development or production environments. If test database names are not explicitly set, your specs suite won't be allowed to run at all.

One way to ensure you use a dedicated database specifically for tests is to override the [`database`](./reference/settings.md#database-settings) settings as follows:

```crystal title=config/settings/test.cr
Marten.configure :test do |config|
  config.database do |db|
    db.name = "my_project_test"
  end
end
```

## Testing tools

Marten provides some tools that can become useful when writing specs.

### Using the test client

The test client is an abstraction that is provided when requiring `marten/spec` and that acts as a very basic web client. This tool allows you to easily test your handlers and the various routes of your application by issuing requests and by introspecting the returned responses.

By leveraging the test client, you can easily simulate various requests (eg. GET or POST requests) for specific URLs and observe the returned responses. While doing so, you can introspect the response properties (such as its status code, content, and headers) in order to verify that your handlers behave as expected.

#### A simple example

To use the test client, you can either initialize a [`Marten::Spec::Client`](pathname:///api/0.4/Marten/Spec/Client.html) object or make use of the per-spec test client that is provided by the [`Marten::Spec#client`](pathname:///api/0.4/Marten/Spec.html#client%3AClient-class-method) method. Initializing new [`Marten::Spec::Client`](pathname:///api/0.4/Marten/Spec.html#client%3AClient-class-method) objects allow you to set client-wide properties, like a default content type.

:::info
Note that the client returned by the [`Marten::Spec#client`](pathname:///api/0.4/Marten/Spec.html#client%3AClient-class-method) method is memoized and is reset after _each_ spec execution.
:::

Let's have a look at a simple way to use the test client and verify the corresponding responses:

```crystal
describe MyRedirectHandler do
  describe "#get" do
    it "returns the expected redirect response" do
      response = Marten::Spec.client.get("/my-redirect-handler", query_params: {"foo" => "bar"})

      response.status.should eq 302
      response.headers["Location"].should eq "/redirected"
    end
  end
end
```

:::tip
In the above example we are simply specifying a "raw" path by hardcoding its value. In a real scenario, you will likely want to [resolve your handler URLs](../handlers-and-http/routing.md#reverse-url-resolutions) using the [`Marten::Routing::Map#reverse`](pathname:///api/0.4/Marten/Routing/Map.html#reverse(name%3AString|Symbol%2Cparams%3AHash(String|Symbol%2CParameter%3A%3ATypes))-instance-method) method of the main routes map (that way, you don't hardcode route paths in your specs). For example

```crystal
url = Marten.routes.reverse("article_detail", pk: 42)
response = Marten::Spec.client.get(url, query_params: {"foo" => "bar"})
```
:::

Here we are simply issuing a GET request (by leveraging the [`#get`](pathname:///api/0.4/Marten/Spec/Client.html#get(path%3AString%2Cquery_params%3AHash|NamedTuple|Nil%3Dnil%2Ccontent_type%3AString|Nil%3Dnil%2Cheaders%3AHash|NamedTuple|Nil%3Dnil%2Csecure%3Dfalse)%3AMarten%3A%3AHTTP%3A%3AResponse-instance-method) test client method) and testing the obtained response. A few things can be noted:

* The test client does not require your project's server to be running: internally it uses a lightweight server handlers chain that ensures that your project's middlewares are applied and that the URL you requested is resolved and mapped to the right handler
* Only the path to the handler needs to be specified when issuing requests (eg. `/foo/bar`)

Note that you can also issue other types of requests by leveraging methods like [`#post`](pathname:///api/0.4/Marten/Spec/Client.html#post(path%3AString%2Cdata%3AHash|NamedTuple|Nil|String%3Dnil%2Cquery_params%3AHash|NamedTuple|Nil%3Dnil%2Ccontent_type%3AString|Nil%3Dnil%2Cheaders%3AHash|NamedTuple|Nil%3Dnil%2Csecure%3Dfalse)%3AMarten%3A%3AHTTP%3A%3AResponse-instance-method), [`#put`](pathname:///api/0.4/Marten/Spec/Client.html#put(path%3AString%2Cdata%3AHash|NamedTuple|Nil|String%3Dnil%2Cquery_params%3AHash|NamedTuple|Nil%3Dnil%2Ccontent_type%3AString|Nil%3Dnil%2Cheaders%3AHash|NamedTuple|Nil%3Dnil%2Csecure%3Dfalse)%3AMarten%3A%3AHTTP%3A%3AResponse-instance-method), or [`#delete`](pathname:///api/0.4/Marten/Spec/Client.html#delete(path%3AString%2Cdata%3AHash|NamedTuple|Nil|String%3Dnil%2Cquery_params%3AHash|NamedTuple|Nil%3Dnil%2Ccontent_type%3AString|Nil%3Dnil%2Cheaders%3AHash|NamedTuple|Nil%3Dnil%2Csecure%3Dfalse)%3AMarten%3A%3AHTTP%3A%3AResponse-instance-method). For example:

```crystal
describe MySchemaHandler do
  describe "#post" do
    it "validates the data and redirects" do
      response = Marten::Spec.client.post("/my-schema-handler", data: {"first_name" => "John", "last_name" => "Doe"})

      response.status.should eq 302
      response.headers["Location"].should eq "/redirected"
    end
  end
end
```

:::info
By default, CSRF checks are disabled for requests issued by the test client. If for some reasons you need to ensure that those are enabled, you can initialize a [`Marten::Spec::Client`](pathname:///api/0.4/Marten/Spec/Client.html) object with `disable_request_forgery_protection: false`.
:::

#### Introspecting responses

Responses returned by the test client are instances of the standard [`Marten::HTTP::Response`](pathname:///api/0.4/Marten/HTTP/Response.html) class. As such you can easily access response attributes such as the status code, the content and content type, cookies, and headers in your specs in order to verify that the expected response was returned by your handler.

#### Exceptions

It is important to note that exceptions raised in your handlers will be visible from your spec. This means that you should use the standard [`#expect_raises`](https://crystal-lang.org/api/Spec/Expectations.html#expect_raises%28klass%3AT.class%2Cmessage%3AString%7CRegex%7CNil%3Dnil%2Cfile%3D__FILE__%2Cline%3D__LINE__%2C%26%29forallT-instance-method) expectation helper to verify that these exceptions are indeed raised.

#### Session and cookies

Test clients are always stateful: if a handler sets a cookie in the returned response, then this cookie will be stored in the client's cookie store (available via the [`#cookies`](pathname:///api/0.4/Marten/Spec/Client.html#cookies-instance-method) method) and will be automatically sent for subsequent requests issued by the client.

The same goes for session values: such values can be set using the session store returned by the [`#sessions`](pathname:///api/0.4/Marten/Spec/Client.html#session-instance-method) client method. If you set session values in this store prior to any request, the matched handler will have access to them and the new values that are set by the handler will be available for further inspection once the response is returned. These session values are also maintained between requests issued by a single client.

For example:

```crystal
describe MyHandler do
  describe "#get" do
    it "renders the expected content if the right value is in the session" do
      Marten::Spec.client.session["foo"] = "bar"

      url = Marten.routes.reverse("initiate_request")
      response = Marten::Spec.client.get(url)

      response.status.should eq 200
      response.content.includes?("Initiate request").should be_true
    end
  end
end
```

#### Testing client and authentication

When using the [marten-auth](https://github.com/martenframework/marten-auth) shard and the built-in [authentication](../authentication.mdx), a few additional helpers can be leveraged in order to easily sign in/sign out users while using the test client:

* The `#sign_in` method can be used to simulate the effect of a signed-in user. This means that the user ID will be persisted into the test client session and that requests issued with it will be associated with the considered user
* The `#sign_out` method can be used to ensure that any signed-in user is logged out and that the session is flushed

For example:

```crystal
describe MyHandler do
  describe "#get" do
    it "shows the profile page of the authenticated user" do
      user = Auth::User.create!(email: "test@example.com") do |user
        user.set_password("insecure")
      end

      url = Marten.routes.reverse("auth:profile")

      Marten::Spec.client.sign_in(user)
      response = Marten::Spec.client.get(url)

      response.status.should eq 200
      response.content.includes?("Profile").should be_true
    end
  end
end
```

### Collecting emails

If your code is sending [emails](../emailing/introduction.md), you might want to test that these emails are sent as expected. To do that, you can leverage the [development emailing backend](../emailing/reference/backends.md#development-backend) to ensure that sent emails are collected as part of each spec execution.

To do that, the emailing backend needs to be initialized with `collect_emails: true` when configuring the [`emailing.backend`](./reference/settings.md#backend-1) setting. For example:

```crystal title=config/settings/test.cr
Marten.configure :test do |config|
  config.backend = Marten::Emailing::Backend::Development.new(collect_emails: true)
end
```

Doing so will ensure that all sent emails are "collected" for further inspection. You can easily retrieve collected emails by calling the [`Marten::Spec#delivered_emails`](pathname:///api/0.4/Marten/Spec.html#delivered_emails%3AArray(Emailing%3A%3AEmail)-class-method) method, which returns an array of [`Marten::Email`](pathname:///api/0.4/Marten/Emailing/Email.html) instances. For example:

```crystal
describe MyObject do
  describe "#do_something" do
    it "sends an email as expected" do
      obj = MyObject.new
      obj.do_something

      Marten::Spec.delivered_emails.size.should eq 1
      Marten::Spec.delivered_emails[0].subject.should eq "Test subject"
    end
  end
end
```

:::info
Note that Marten also automatically ensures that the collected emails are automatically reset after each spec execution so that you don't have to take care of that directly.
:::
