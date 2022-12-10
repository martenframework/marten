---
title: Testing
description: Learn how to test your Marten project.
sidebar_label: Testing
---

This section covers the basics regarding how to test a Marten project and the various tools that you can leverage in this regard.

## The basics

You should test your Marten project to ensure that it adheres to the specifications it was built for. Like any Crystal project, Marten lets you write "specs" (see the [official documentation related to testing in Crystal](https://crystal-lang.org/reference/guides/testing.html) to learn more about those).

By default, when creating a project through the use of the [`new`](./reference/management-commands#new) management command, Marten will automatically create a `spec/` folder at the root of your project structure. This folder contains a unique `spec_helper.cr` file allowing you to initialize the test environment for your Marten project.

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

By default, the [`new`](./reference/management-commands#new) management command always creates a `test` environment when generating new projects. As such, you should ensure that the `MARTEN_ENV` environment variable is set to `test` when running your Crystal specs. It should also be reminded that this `test` environment is associated with a dedicated settings file where test-related settings can be specified and/or overridden if necessary (see [Settings](./settings#environments) for more details about this).

### The test database

Marten **must** use a different database when running tests in order to not tamper with your regular database. Indeed, the database used in the context of specs will be flushed and generated automatically every time the specs suite is executed. You should not set these database names to the same names as the ones used for your development or production environments. If test database names are not explicitly set, your specs suite won't be allowed to run at all.

One way to ensure you use a dedicated database specifically for tests is to override the [`database`](./reference/settings#database-settings) settings as follows:

```crystal title=config/settings/test.cr
Marten.configure :test do |config|
  config.database do |db|
    db.name = "my_project_test"
  end
end
```
