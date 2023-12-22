---
title: Deploying Marten projects
description: Learn about the things to consider when deploying Marten web applications.
sidebar_label: Introduction
---

This section describes what's involved when it comes to deploying a Marten web application and highlights some important things to consider before performing deploys.

## Overview

Each deployment pipeline is unique and will vary from one project to another. That being said, a few things and requirements will be commonly encountered when it comes to deploying a Marten project:

1. installing your project's dependencies
2. compiling your project's server and [management CLI](../development/management-commands.md)
3. collecting your project's [assets](../assets/introduction.md)
4. applying any pending migrations to your database
5. starting the compiled server

Where, when, and how these steps are performed will vary from one project to another. Each of these steps is highlighted below along with some recommendations.

It should also be noted that a few guides highlighting common deployment strategies can be leveraged if necessary:

* [Deploying to an Ubuntu server](./how-to/deploy-to-an-ubuntu-server)

### Installing dependencies

One of the first things you need to do when deploying a Marten project is to ensure that the dependencies of the projects are available. In this light, you can leverage the `shards install` command to install your project's Crystal dependencies (assuming that Crystal is installed on your destination machine). Obviously, your project may require the installation of other types of dependencies (such as Node.js dependencies for example), which you have to take care of as well.

### Compiling your project

Your project server and [management CLI](../development/management-commands.md) need to be compiled to run your project's server and to execute additional deployment-related management commands (eg. to [collect assets](#collecting-assets) or [apply migrations](#applying-migrations)).

When it comes to your project server, you will usually need to compile the `src/server.cr` file (which is automatically created when generating new projects via the [`new`](../development/reference/management-commands.md#new) management command). This can be achieved with the following command:

```bash
crystal build src/server.cr -o bin/server --release
```

:::tip
In the above example, the server binary is compiled using the `-o bin/server` option, which ensures that the compiled binary will be named `server` and stored under the related `bin` folder. You should obviously adapt this to your production environment.
:::

The [management CLI](../development/management-commands.md) is provided by the `manage.cr` file located at the root of your project. As usual, this file is also automatically generated for you when creating Marten projects through the use of the [`new`](../development/reference/management-commands.md#new) management command. Compiling this binary can be done with the following command:

```bash
crystal build manage.cr -o bin/manage --release
```

:::info
The above compilation commands make use of the `--release` flag, which enables compiler optimizations. As a result, the compilation of the final binaries may take quite some time depending on your project. You can also avoid using `--release` if needed but technically performances could be impacted. See [Release builds](https://crystal-lang.org/reference/man/crystal/index.html#release-builds) for more details on this subject.
:::

### Collecting assets

You need to ensure that your project and applications assets (eg. JavaScripts, CSS files, etc) are "collected" at deploy time so that they are placed at the final destination from which they will be served: this operation is made available through the use of the [`collectassets`](../development/reference/management-commands.md#collectassets) management command. This "destination" depends on your deployment strategy and your configured [assets settings](../development/reference/settings.md#assets-settings): it can be as simple as moving all these assets to a dedicated folder in your server (so that they can be served by your web server), or it can involve uploading these assets to an S3 or GCS bucket for example.

In order to collect assets at deploy time, you will want to use the compiled `manage` binary and run the [`collectassets`](../development/reference/management-commands.md#collectassets) management command (as mentioned previously) with the `--no-input` flag set in order to disable user prompts:

```bash
bin/manage collectassets --no-input
```

:::info
The assets handling documentation also provides a few [guidelines](../assets/introduction.md#serving-assets-in-production) on how to serve asset files in production that may be worth reading.
:::

### Applying migrations

Your projects will likely make use of models, which means that you will need to ensure that those are properly created at your configured database level by running the associated migrations.

To do so, you can use the compiled `manage` binary and run the [`migrate`](../development/reference/management-commands.md#migrate) management command:

```bash
bin/manage migrate
```

Please refer to [Migrations](../models-and-databases/migrations.md) to learn more about model migrations.

### Running the server

You can run the compiled Marten server using the following command (obviously the location of the binary depends on [how the compilation was actually performed](#compiling-your-project)):

```bash
bin/server
```

It's important to note that the Marten server is intended to be used behind a reverse proxy such as [Nginx](https://www.nginx.com/) or [Apache](https://httpd.apache.org/): you will usually want to configure such reverse proxy so that it targets your configured Marten server host and port. In this light, you should ensure that your Marten server is not using the HTTP port 80 (instead it could use something like 8080 or 8000 for example).

Depending on your use cases, a reverse proxy will also allow you to easily serve other contents such as [assets](../assets/introduction.md) or [uploaded files](../files/managing-files.md), and to use SSL/TLS.

:::tip
It is possible to run multiple processes of the same server behind a reverse proxy such as Nginx. Indeed, each compiled server can accept optional parameters to override the host and/or port being used. These parameters are respectively `--bind` (or `-b`) and `--port` (or `-p`). For example:

```bash
bin/server -b 127.0.0.1
bin/server -p 8080
```
:::

## Additional tips

This section lists a few additional things to consider when deploying Marten projects.

### Secure critical setting values

You should pay attention to the value of some of your settings in production environments.

#### Debug mode

You should ensure that the [`debug`](../development/reference/settings.md#debug) setting is always set to `false` in production environments. Indeed, the debug mode can help for development purposes because it outputs useful tracebacks and site-related information. But there is a risk that all this information leaks somewhere if you enable this mode in production.

#### Secret key

You should ensure that the value of the [`secret_key`](../development/reference/settings.md#secret_key) setting is not hardcoded in your [config files](../development/settings.md). Indeed, this setting value must be kept secret and you should ensure that it's loaded dynamically instead. For example, this setting's value could be set in a dedicated environment variable (or dotenv file) and loaded as follows:

```crystal
Marten.configure do |config|
  config.secret_key = ENV.fetch("MARTEN_SECRET_KEY") { raise "Missing MARTEN_SECRET_KEY env variable" }

  # [...]
end
```
