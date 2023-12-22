---
title: Applications
description: Learn how to leverage applications to structure your projects.
sidebar_label: Applications
---

Marten projects can be organized into logical and reusable components called "applications". These applications can contribute specific behaviors and abstractions to a project, including [models](../models-and-databases.mdx), [handlers](../handlers-and-http.mdx), and [templates](../templates.mdx). They can be packaged and reused across various projects as well.

## Overview

A Marten **application** is a set of abstractions (defined under a dedicated and unique folder) that provides some set of features. These abstractions can correspond to [models](../models-and-databases.mdx), [handlers](../handlers-and-http.mdx), [templates](../templates.mdx), [schemas](../schemas.mdx), etc.

Marten projects always use one or many applications. Indeed, each Marten project comes with a default [main application](#the-main-application) that corresponds to the standard `src` folder: models, migrations, or other classes defined in this folder are associated with the main application by default (unless they are part of another _explicitly defined_ application). As projects grow in size and scope, it is generally encouraged to start thinking in terms of applications and how to split models, handlers, or features across multiple apps depending on their intended responsibilities.

Another benefit of applications is that they can be packaged and reused across multiple projects. This allows third-party libraries and shards to easily contribute models, migrations, handlers, or templates to other projects.

## Using applications

The use of applications must be manually enabled within projects: this is done through the use of the [`installed_apps`](./reference/settings.md#installedapps) setting.

This setting corresponds to an array of installed app classes. Indeed, each Marten application must define a subclass of [`Marten::App`](pathname:///api/0.3/Marten/App.html) to specify a few things such as the application label (see [Creating applications](#creating-applications) for more information about this). When those subclasses are specified in the `installed_apps` setting, the applications' models, migrations, assets, and templates will be made available to the considered project.

For example:

```crystal
Marten.configure do |config|
  config.installed_apps = [
    FooApp,
    BarApp,
  ]
end
```

Adding an application class inside this array will have the following impact on the considered project:

* the models of this application and the associated migrations will be used
* the templates of the application will be made available to the templates engine
* the assets of the application will be made available to the assets engine
* the management commands defined by the application will be made available to the Marten CLI

### The main application

The "main" application is a default application that is always implicitly used by Marten projects (which means that it does not appear in the [`installed_apps`](./reference/settings.md#installedapps) setting). This application is associated with the standard `src` folder: this means that models, migrations, assets, or templates defined in this folder will be associated with the main application by default. For example, models defined under a `src/models` folder would be associated with the main application.

:::info
The main application is associated with the `main` label. This means that models of the main application that do not define an explicit table name will have table names starting with `main_`.
:::

It should be noted that it is possible to create _explicitly defined_ applications whose structures live under the `src` folder as well: the abstractions (eg. models, migrations, etc) of these applications will be associated with them and _not_ with the main application. This is because abstractions are always associated with the closest application in the files/folders structure.

In the end, the main application provides a convenient way for starting projects and prototyping without requiring to spec out how projects will be organized in terms of applications upfront. That being said, as projects grow in size and scope, it is really encouraged to start thinking in terms of applications and how to split abstractions and features across multiple apps depending on their intended responsibilities.

### Order of installed applications

You should note that the order in which installed applications are defined in the [`installed_apps`](./reference/settings.md#installedapps) setting can actually matter.

For example, a "foo" app might define a `test.html` template, and a similar template with the exact same name might be defined by a "bar" app. If the "foo" app appears before the "bar" app in the array of installed apps, then requesting and rendering the `test.html` template will actually involve the "foo" app's template only. This is because template loaders associated with app directories iterate over applications in the order in which they are defined in the installed apps array.

This is why it is always important to _namespace_ abstractions, assets, templates, and locales when creating applications. Failing to do so exposes apps to conflicts with other applications' code. As such, in the previous example, the "foo" app should've defined a `foo/test.html` template while the "bar" app should've defined a `bar/test.html` template to avoid possible conflicts.

## Creating applications

Creating applications can be done very easily through the use of the [`new`](./reference/management-commands.md#new) management command. For example:

```bash
marten new app blog --dir=src/blog
```

Running such a command will usually create the following directory structure:

```
src/blog
├── handlers
├── migrations
├── models
├── schemas
├── templates
├── app.cr
└── cli.cr
```

These files and folders are described below:

| Path | Description |
| ----------- | ----------- |
| handlers/ | Empty directory where the request handlers of the application will be defined. |
| migrations/ | Empty directory that will store the migrations that will be generated for the models of the application. |
| models/ | Empty directory where the models of the application will be defined. |
| schemas/ | Empty directory where the schemas of the application will be defined. |
| templates/ | Empty directory where the templates of the application will be defined. |
| app.cr | Definition of the application configuration abstraction; this is also where application files requirements should be defined. |
| cli.cr | Requirements of CLI-related files, such as migrations for example. |

The most important file of an application is the `app.cr` one. This file usually includes all the app requirements and defines the application configuration class itself, which must be a subclass of the [`Marten::App`](pathname:///api/0.3/Marten/App.html) abstract class. This class allows mainly to define the "label" identifier of the application (through the use of the [`#label`](pathname:///api/0.3/Marten/Apps/Config.html#label(label%3AString|Symbol)-class-method) class method): this identifier must be unique across all the installed applications of a project and is used to generate things like model table names or migration classes.

Here is an example `app.cr` file content for a hypothetic "blog" app:

```crystal
require "./handlers/**"
require "./models/**"
require "./schemas/**"

module Blog
  class App < Marten::App
    label "blog"
  end
end
```

:::info
_Where_ the `app.cr` file is located is important: the directory where this file is defined is also the directory where key folders like `models`, `migrations`, `templates`, etc, must be present. This is necessary to ensure that these files and abstractions are associated with the considered app.
:::

Another very important file is the `cli.cr` one: this file is there to define all the CLI-related requirements and will usually be required directly by your project's `manage.cr` file. _A minima_ the `cli.cr` file should require model migrations, but it could also require the management commands provided by the application. For example:

```crystal
require "./cli/**"
require "./migrations/**"
```
