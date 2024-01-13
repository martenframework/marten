---
title: Settings
description: Learn the basics of Marten settings.
sidebar_label: Settings
---

Marten projects can be configured through the use of settings files. This section explains how settings work, how they relate to environments, and how they can be altered.

## Overview

Settings will be usually defined under a `config/settings` folder at the root of your project structure. There are no strict requirements regarding _where_ settings are defined nor how they are organized, but as a general rule of thumb, it is recommended to organize settings on a per-environment basis (shared settings, development settings, production settings, etc).

In such configuration, you will usually define shared settings (settings that are shared across all your environments) in a dedicated settings file (eg. `config/settings/base.cr`) and other environment-specific settings in other files (eg. `config/settings/development.cr`).

To define settings, it is necessary to access the global Marten configuration object through the use of the [`Marten#configure`](pathname:///api/0.4/Marten.html#configure(env%3ANil|String|Symbol%3Dnil%2C%26)-class-method) method. This method returns a [`Marten::Conf::GlobalSettings`](pathname:///api/0.4/Marten/Conf/GlobalSettings.html) object that you can use to define setting values. For example:

```crystal
Marten.configure do |config|
  config.installed_apps = [
    FooApp,
    BarApp,
  ]

  config.middleware = [
    Marten::Middleware::Session,
    Marten::Middleware::Flash,
    Marten::Middleware::GZip,
    Marten::Middleware::XFrameOptions,
  ]

  config.database do |db|
    db.backend = :postgresql
    db.name = "dummypress"
    db.host = "localhost"
    db.password = ""
  end
end
```

It should be noted that the [`Marten#configure`](pathname:///api/0.4/Marten.html#configure(env%3ANil|String|Symbol%3Dnil%2C%26)-class-method) method can be called with an additional argument to ensure that the underlying settings are defined for a specific environment only:

```crystal
Marten.configure :development do |config|
  config.secret_key = "INSECURE"
end
```

:::caution
You should avoid altering setting values outside of the configuration block provided by the [`Marten#configure`](pathname:///api/0.4/Marten.html#configure(env%3ANil|String|Symbol%3Dnil%2C%26)-class-method) method. Most settings are "read" and applied when the Marten project is set up, that is before the server actually starts. Changing these setting values afterward won't produce any meaningful result.
:::

## Environments

When creating new projects by using the [`new`](./reference/management-commands.md#new) management command, the following environments will be created automatically:

* Development (settings defined in `config/settings/development.cr`)
* Test (settings defined in `config/settings/test.cr`)
* Production (settings defined in `config/settings/production.cr`)

When your application is running, Marten will rely on the `MARTEN_ENV` environment variable to determine the current environment. If this environment variable is not found, the environment will automatically default to `development`. The value you specify in the `MARTEN_ENV` environment variable must correspond to the argument you pass to the [`Marten#configure`](pathname:///api/0.4/Marten.html#configure(env%3ANil|String|Symbol%3Dnil%2C%26)-class-method) method.

It should be noted that the current environment can be retrieved through the use of the [`Marten#env`](pathname:///api/0.4/Marten.html#env-class-method) method, which returns a [`Marten::Conf::Env`](pathname:///api/0.4/Marten/Conf/Env.html) object. For example:

```crystal
Marten.env              # => <Marten::Conf::Env:0x1052b8060 @id="development">
Marten.env.id           # => "development"
Marten.env.development? # => true
```

## Available settings

All the available settings are listed in the [settings reference](./reference/settings.md).
