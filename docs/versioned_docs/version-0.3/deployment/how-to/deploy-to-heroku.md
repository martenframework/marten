---
title: Deploy to Heroku
description: Learn how to deploy a Marten project to Heroku.
---

This guide covers how to deploy a Marten project to [Heroku](https://heroku.com).

## Prerequisites

To complete the steps in this guide, you will need:

* An active account on [Heroku](https://heroku.com).
* The [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed and correctly configured.
* A functional Marten project.

## Make your Marten project Heroku-ready

Before creating the Heroku application, it is important to ensure that your project is properly configured for deployment to Heroku. This section outlines some necessary steps to ensure that your project can be deployed to Heroku without issues.

### Create a `Procfile`

You should first ensure that your project defines a [`Procfile`](https://devcenter.heroku.com/articles/procfile), at the root of your project folder. A Procfile specifies the commands Heroku's dynos run, defining process types like web servers and background workers.

Your Procfile should contain the following content at least:

```procfile title="Procfile"
web: bin/server --port \$PORT
```

:::info
The `PORT` environment variable is automatically defined by Heroku. That's why we have to ensure that its value is forwarded to your server.
:::

If your application requires the use of a database, you should also add a [release process](https://devcenter.heroku.com/articles/procfile#the-release-process-type) that runs the [`migrate`](../../development/reference/management-commands.md#migrate) management command to your Procfile:

```procfile title="Procfile"
web: bin/server --port \$PORT
release: marten migrate
```

This will ensure that your database is properly migrated during each deployment.

### Configure the root path

During deployment on Heroku, your application is prepared and compiled in a temporary directory, which is distinct from the location where the server runs your application. Specifically, the root of your application will be available under the `/app` folder on the Heroku platform. It's important to keep this in mind when setting up your application for deployment to Heroku.

Marten's [application mechanism](../../development/applications.md) relies heaviliy on paths when it comes to locate things like [templates](../../templates.mdx), [translations](../../i18n.mdx), or [assets](../../assets.mdx). Because the path where your application is compiled will differ from the path where it runs, we need to ensure that you explicitly configure Marten so that it can find your project structure.

To address this, we need to define a specific "root path" for your project in production. The root path specifies the actual location of the project sources in your system. This can prove helpful in scenarios where the project was compiled in a specific location different from the final destination where the project sources (and the `lib` folder) are copied, which is the case with Heroku.

In this light, we can set the [`root_path`](../../development/reference/settings.md#root_path) setting to `/app` as follows:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  config.root_path = "/app"

  # Other settings...
end
```

As highlighted in the above example, this should be done in your "production" settings file.

### Configure key settings from environment variables

When deploying to Heroku, you will have to set a few environment variables (later in this guide) that will be used to populate key settings. This should be the case for the [`secret_key`](../../development/reference/settings.md#secret_key) and [`allowed_hosts`](../../development/reference/settings.md#allowed_hosts) settings at least.

As such, it is important to ensure that your project populates these settings by reading their values in corresponding environment variables. This can be achieved by updating your `config/settings/production.cr` production settings file as follows:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  config.secret_key = ENV.fetch("MARTEN_SECRET_KEY")
  config.allowed_hosts = ENV.fetch("MARTEN_ALLOWED_HOSTS", "").split(",")

  # Other settings...
end
```

It should be noted that if your application requires a database, you should also make sure to parse the `DATABASE_URL` environment variable and to configure your [database settings](../../development/reference/settings.md#database-settings) from the parsed database URL properties. The `DATABASE_URL` variable contains a URL-encoded string that specifies the connection details of your database, such as the database type, hostname, port, username, password, and database name.

This can be accomplished as follows for a PostgreSQL database:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  config.database do |db|
    database_uri = URI.parse(ENV.fetch("DATABASE_URL"))

    db.backend = :postgresql
    db.host = database_uri.host
    db.port = database_uri.port
    db.user = database_uri.user
    db.password = database_uri.password
    db.name = database_uri.path[1..]
  end

  # Other settings...
end
```

### Optional: set up the asset serving middleware

In order to easily serve your application's assets in Heroku, you can make use of the [`Marten::Middleware::AssetServing`](../../handlers-and-http/reference/middlewares.md#asset-serving-middleware) middleware. Indeed, it won't be possible to configure a web server such as [Nginx](https://nginx.org) to serve your assets directly on Heroku if you intend to use a "local file system" asset store (such as [`Marten::Core::Store::FileSystem`](pathname:///api/0.3/Marten/Core/Storage/FileSystem.html)).

To palliate this, you can make use of the [`Marten::Middleware::AssetServing`](../../handlers-and-http/reference/middlewares.md#asset-serving-middleware) middleware. Obviously, this is not necessary if you intend to leverage a cloud storage provider (like Amazon's S3 or GCS) to store and serve your collected assets (in this case, you can simply skip this section).

In order to use this middleware, you can "insert" the corresponding class at the beginning of the [`middleware`](../../development/reference/settings.md#middleware) setting when defining production settings. For example:

```crystal
Marten.configure :production do |config|
  config.middleware.unshift(Marten::Middleware::AssetServing)

  # Other settings...
end
```

The middleware will serve the collected assets available under the assets root ([`assets.root`](../../development/reference/settings.md#root) setting). It is also important to note that the [`assets.url`](../../development/reference/settings.md#url) setting must align with the Marten application domain or correspond to a relative URL path (e.g., `/assets/`) for this middleware to work correctly.

## Create the Heroku app

To begin, the initial action required is to generate your Heroku application itself. This can be achieved by executing the `heroku create` command as follows:

```bash
heroku create <yourapp>
```

:::info
In this guide, the `<yourapp>` placeholder refers to the Heroku application name that you have chosen for your project. You should replace `<yourapp>` with the actual name of your application in all the relevant commands and code snippets mentioned in this guide.
:::

## Set up the required buildpacks

Heroku leverages [buildpacks](https://devcenter.heroku.com/articles/buildpacks) in order to "compile" web applications (which can include installing dependencies, compiling actual binaries, etc). In the context of a Marten project, it is recommended to use two buildbacks:

1. First, the [Node.js official buildback](https://github.com/heroku/heroku-buildpack-nodejs) in order to "build" your project's assets.
2. Second, the [Marten official buildback](https://github.com/martenframework/heroku-buildpack-marten) in order to (i) compile your server's binary, (ii) compile the Marten CLI, and (iii) [collect assets](../../assets/introduction.md).

The sequence of buildpacks applied during the deployment process is critical: the Node.js buildpack must be the first one applied, to ensure that Heroku can initiate the necessary Node.js installations and configurations. This approach will guarantee that when the Marten buildpack is activated, the assets will have already been created and are ready to be "collected" through the [`collectassets`](../../development/reference/management-commands.md#collectassets) management command.

You can ensure that these buildpacks are used by running the following commands:

```bash
heroku buildpacks:add heroku/nodejs
heroku buildpacks:add https://github.com/martenframework/heroku-buildpack-marten
```

:::tip
It is important to mention that the use of the [Node.js official buildback](https://github.com/heroku/heroku-buildpack-nodejs) is completely optional: you should only use it if your project leverages Node.js to build some assets.
:::

## Set up environment variables

### `MARTEN_ENV`

At least one environment variable needs to be configured in order to ensure that your Marten project operates in production mode in Heroku: the `MARTEN_ENV` variable. This variable determines the current environments (and the associated settings to apply).

To set this environment variable, you can leverage the `heroku config:set` command as follows:

```bash
heroku config:set MARTEN_ENV=production
```

### `MARTEN_SECRET_KEY`

It is also recommended to define the `MARTEN_SECRET_KEY` environment variable in order to populate the [`secret_key`](../../development/reference/settings.md#secret_key) setting, as mentioned in [Configure key settings from environment variables](#configure-key-settings-from-environment-variables).

To set this environment variable, you can leverage the `heroku config:set` command as follows:

```bash
heroku config:set MARTEN_SECRET_KEY=$(openssl rand -hex 16)
```

### `MARTEN_ALLOWED_HOSTS`

Finally, we want to ensure that the [`allowed_hosts`](../../development/reference/settings.md#allowed_hosts) setting contains the actual domain of your Heroku application, which is required as part of Marten's [HTTP Host Header Attacks Protection mechanism](../../security/introduction.md#http-host-header-attacks-protection).

To set this environment variable, you can use the following command:

```bash
heroku config:set MARTEN_ALLOWED_HOSTS=<yourapp>.herokuapp.com
```

## Set up a database

You'll need to provision a Heroku PostgreSQL database if your application makes use of models and migrations. To do so, you can make use of the following command:

```bash
heroku addons:create heroku-postgresql:mini
```

:::info
You should replace `mini` in the above command by your desired [Postgres plan](https://devcenter.heroku.com/articles/heroku-postgres-plans).
:::

## Upload the application

The final step is to upload your application's code to Heroku. This can be done by using the standard `git push` command to copy the local `main` branch to the `main` branch on Heroku:

```bash
git push heroku main
```

It is worth mentioning that a few things will happen when you push your application's code to Heroku like in the above example. Indeed, Heroku will detect the type of your application and apply the buildpacks you [configured previously](#set-up-the-required-buildpacks) (ie. first the Node.js one and then the Marten one). As part of this step, your application's dependencies will be installed and your project will be compiled. If you defined a `release` process in your `Procfile` (like explained in [Create a Procfile](#create-a-procfile)), the specfied command will also be executed (for example in order to run your project's migrations).

A few additional things should also be noted:

* The compiled server binary will be placed under the `bin/server` path.
* Your project's `manage.cr` file will be compiled as well and will be available by simply calling the `marten` command. This means that you can run `marten <command>` if you need to call specific [management commands](../../development/management-commands.md).
* The Marten buildpack will automatically call the [`collectassets`](../../development/reference/management-commands.md#collectassets) management command in order to collect your project's [assets](../../assets/introduction.md) and copy them to your configured assets storage. You can set the `DISABLE_COLLECTASSETS` environment variable to `1` if you don't want this behavior.

## Run management commands

If you need to run additional [management commands](../../development/management-commands.md) in your provisioned application, you can use the `heroku run` command. For instance:

```bash
heroku run marten listmigrations
```
