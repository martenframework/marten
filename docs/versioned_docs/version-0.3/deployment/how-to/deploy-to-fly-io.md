---
title: Deploy to Fly.io
description: Learn how to deploy a Marten project to Fly.io.
---

This guide covers how to deploy a Marten project to [Fly.io](https://fly.io).

## Prerequisites

To complete the steps in this guide, you will need:

* An active account on [Fly.io](https://fly.io).
* The Fly.io CLI [installed](https://fly.io/docs/hands-on/install-flyctl/) and correctly [configured](https://fly.io/docs/getting-started/log-in-to-fly/).
* A functional Marten project.

## Make your Marten project Fly.io-ready

Before creating the Fly.io application, it is important to ensure that your project is properly configured for deployment to Fly.io. This section outlines some steps to ensure that your project can be deployed to Fly.io without issues.

### Create a `Dockerfile`

We will be deploying our Marten project to Fly.io by leveraging a [Dockerfile strategy](https://fly.io/docs/languages-and-frameworks/dockerfile/). A `Dockerfile` is a text file that contains a set of instructions for building a [Docker](https://www.docker.com/) image. It typically includes a base image, commands to install dependencies, and steps to configure the environment and copy files into the image.

Your `Dockerfile` should be placed at the root of your project folder and should contain the following content at least:

```Dockerfile title="Dockerfile"
FROM crystallang/crystal:latest
WORKDIR /app
COPY . .

ENV MARTEN_ENV=production

RUN apt-get update
RUN apt-get install -y curl cmake build-essential

RUN shards install
RUN bin/marten collectassets --no-input
RUN crystal build manage.cr -o bin/manage
RUN crystal build src/server.cr -o bin/server --release

CMD ["/app/bin/server"]
```

As you can see, this Dockerfile builds a Docker image based on the latest version of the Crystal programming language image. It also installs your project's Crystal dependencies, runs the [`collectassets`](../../development/reference/management-commands.md) management command, and compiles your server's binary.

It should be noted that this Dockerfile could perform additional operations if needed. For example, some projects may require Node.js in order to install additional dependencies and build your project's assets. This could be achieved with the following additions:

```Dockerfile title="Dockerfile"
FROM crystallang/crystal:latest
WORKDIR /app
COPY . .

ENV MARTEN_ENV=production

RUN apt-get update
RUN apt-get install -y curl cmake build-essential
// highlight-next-line
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
// highlight-next-line
RUN apt-get install -y nodejs
// highlight-next-line

// highlight-next-line
RUN npm install
// highlight-next-line
RUN npm run build

RUN shards install
RUN bin/marten collectassets --no-input
RUN crystal build manage.cr -o bin/manage
RUN crystal build src/server.cr -o bin/server --release

CMD ["/app/bin/server"]
```

### Configure your production server's host and port

You should ensure that your production server can be accessed from other containers, and on a specific port. To do so, it's important to set the [`host`](../../development/reference/settings.md#host) setting to `0.0.0.0` and the [`port`](../../development/reference/settings.md#port) setting to a specific value such as `8000` (which is the port we'll be using throughout this guide).

This can be achieved by updating your `config/settings/production.cr` production settings file as follows:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  config.host = "0.0.0.0"
  config.port = 8000

  # Other settings...
end
```

### Configure key settings from environment variables

When deploying to Fly.io, you will have to set a few environment variables (later in this guide) that will be used to populate key settings. This should be the case for the [`secret_key`](../../development/reference/settings.md#secret_key) and [`allowed_hosts`](../../development/reference/settings.md#allowed_hosts) settings at least.

As such, it is important to ensure that your project populates these settings by reading their values in corresponding environment variables. This can be achieved by updating your `config/settings/production.cr` production settings file as follows:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  config.secret_key = ENV.fetch("MARTEN_SECRET_KEY", "")
  config.allowed_hosts = ENV.fetch("MARTEN_ALLOWED_HOSTS", "").split(",")

  # Other settings...
end
```

It should be noted that if your application requires a database, you should also make sure to parse the `DATABASE_URL` environment variable and to configure your [database settings](../../development/reference/settings.md#database-settings) from the parsed database URL properties. The `DATABASE_URL` variable contains a URL-encoded string that specifies the connection details of your database, such as the database type, hostname, port, username, password, and database name.

This can be accomplished as follows for a PostgreSQL database:

```crystal title="config/settings/production.cr"
Marten.configure :production do |config|
  if ENV.has_key?("DATABASE_URL")
    # Note: DATABASE_URL isn't available at build time...
    config.database do |db|
      database_uri = URI.parse(ENV.fetch("DATABASE_URL"))

      db.backend = :postgresql
      db.host = database_uri.host
      db.port = database_uri.port
      db.user = database_uri.user
      db.password = database_uri.password
      db.name = database_uri.path[1..]

      # Fly.io's Postgres works over an internal & encrypted network which does not support SSL.
      # Hence, SSL must be disabled.
      db.options = {"sslmode" => "disable"}
    end
  end

  # Other settings...
end
```

### Optional: set up the asset serving middleware

In order to easily serve your application's assets in Fly.io, you can make use of the [`Marten::Middleware::AssetServing`](../../handlers-and-http/reference/middlewares.md#asset-serving-middleware) middleware. Indeed, it won't be possible to configure a web server such as [Nginx](https://nginx.org) to serve your assets directly on Fly.io if you intend to use a "local file system" asset store (such as [`Marten::Core::Store::FileSystem`](pathname:///api/0.3/Marten/Core/Storage/FileSystem.html)).

To palliate this, you can make use of the [`Marten::Middleware::AssetServing`](../../handlers-and-http/reference/middlewares.md#asset-serving-middleware) middleware. Obviously, this is not necessary if you intend to leverage a cloud storage provider (like Amazon's S3 or GCS) to store and serve your collected assets (in this case, you can simply skip this section).

In order to use this middleware, you can "insert" the corresponding class at the beginning of the [`middleware`](../../development/reference/settings.md#middleware) setting when defining production settings. For example:

```crystal
Marten.configure :production do |config|
  config.middleware.unshift(Marten::Middleware::AssetServing)

  # Other settings...
end
```

The middleware will serve the collected assets available under the assets root ([`assets.root`](../../development/reference/settings.md#root) setting). It is also important to note that the [`assets.url`](../../development/reference/settings.md#url) setting must align with the Marten application domain or correspond to a relative URL path (e.g., `/assets/`) for this middleware to work correctly.

## Create the Fly.io app

To begin, the initial action required is to generate your Fly.io application itself. This can be achieved by executing the `fly launch` command as follows:

```bash
fly launch --no-deploy --no-cache --internal-port 8000 --name <yourapp> --env MARTEN_ALLOWED_HOSTS=<yourapp>.fly.dev
```

The above command creates a Fly.io application whose internal port is set to `8000` while also ensuring that the `MARTEN_ALLOWED_HOSTS` environment variable is set to your future app domain. The command will ask you to choose a specific [region](https://fly.io/docs/reference/regions/) for your application and will create a `fly.toml` file whose content should look like this:

```toml title="fly.toml"
app = "<yourapp>"
primary_region = "<yourregion>"

[env]
  MARTEN_ALLOWED_HOSTS = "<yourapp>.fly.dev"

[http_service]
  internal_port = 8000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
```

The `fly.toml` is a configuration file used by Fly.io to know how to deploy your application to the Fly.io platform.

:::info
In this guide, the `<yourapp>` placeholder refers to the Fly.io application name that you have chosen for your project. You should replace `<yourapp>` with the actual name of your application in all the relevant commands and code snippets mentioned in this guide.
:::

## Set up environment secrets

It is recommended to define the `MARTEN_SECRET_KEY` environment variable order to populate the [`secret_key`](../../development/reference/settings.md#secret_key) setting, as mentioned in [Configure key settings from environment variables](#configure-key-settings-from-environment-variables).

Fly.io gives the ability to define such sensitive setting values using [runtime secrets](https://fly.io/docs/reference/secrets/). In this light, we can create a `MARTEN_SECRET_KEY` secret by using the `fly secrets` command as follows:

```bash
fly secrets set MARTEN_SECRET_KEY=$(openssl rand -hex 16)
```

## Set up a database

You'll need to provision a Fly.io PostgreSQL database if your application makes use of models and migrations (otherwise you can skip this step!). 

In this light, you first need to create a PostgreSQL cluster with the following command:

```bash
fly pg create --name <yourapp>-db
```

Then you will need to "attach" the PostgreSQL cluster you just created with your actual application. This can be achieved with the following command:

```bash
fly postgres attach <yourapp>-db --app <yourapp>
```

Additionally, you will want to ensure that migrations are automatically applied every time your project is deployed. To do so, you can update the `fly.toml` file that was generated previously and add the following section to it:

```toml title="fly.toml"
app = "<yourapp>"
primary_region = "<yourregion>"

[env]
  MARTEN_ALLOWED_HOSTS = "<yourapp>.fly.dev"

[http_service]
  internal_port = 8000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true

// highlight-next-line
[deploy]
// highlight-next-line
  release_command = "bin/manage migrate"
```

## Deploy the application

The final step is to upload your application's code to Fly.io. This can be done by using the following command:

```bash
fly deploy
```

It is worth mentioning that a few things will happen when you push your application's code to Fly.io like in the above example. Indeed, Fly.io will build a Docker image of your application based on the `Dockerfile` you defined [previously](#create-a-dockerfile) and then push it to the Fly.io registry (a private Docker registry maintained by Fly.io). Once this is done, it will launch a Docker container by using the obtained Docker image, and then route incoming traffic to the running container.
