---
title: Tutorial
description: Learn how to use Marten by creating a simple web application.
---

This guide will walk you though the creation of a simple weblog application, which will help you learn the basics of the Marten web framework. It is designed for beginners who want to get started by creating a Marten web project, so no prior experience with the framework is required.

This guide also assumes that [Crystal and the Marten CLI are properly installed already](./installation.md). You can verify that the Marten CLI is properly installed by running the following command:

```bash
marten -v
```

This should output the version of your Marten installation.

## What is Marten?

Marten is a web application framework written in the Crystal programming language. It is designed to make developping web applications easy and fun; and it does so by making some assumptions regarding what are the common needs developpers may encounter when building web applications.

## Creating a project

Creating a project is the first thing to do in order to start working on a Marten web application. This creation process can be done through the use of the `marten` command, and it will ensure that the basic structure of a Marten project is properly generated.

This can be achieved from the command line, where you can run the following command to create your first Marten project:

```bash
marten init project myblog
```

The above command will create a `myblog` directory inside your current directory. This new folder should have the following content:

```
myblog/
├── config
│   ├── settings
│   │   ├── base.cr
│   │   ├── development.cr
│   │   ├── production.cr
│   │   └── test.cr
│   └── routes.cr
├── spec
│   └── spec_helper.cr
├── src
│   ├── migrations
│   ├── models
│   ├── schemas
│   ├── views
│   ├── cli.cr
│   ├── project.cr
│   └── server.cr
├── manage.cr
└── shard.yml
```

These files and folders are described below:

| Path | Description |
| ----------- | ----------- |
| config/ | Contains the configuration of the project. This includes environment-specific Marten configuration settings and the routes of the web application. |
| spec/ | Contains the project specs, allowing to test your application. | 
| src/ | Contains the source code of the application. By default this folder will include a `project.cr` file (where all dependencies - including Marten itself - are required), a `server.cr` file (which starts the Marten web server), and empty `migrations`, `models`, `schemas`, and `views` folders. |
| manage.cr | This file define a CLI that lets you interact with your Marten project in order to perform various actions (eg. running database migrations, collecting assets, etc). |
| shard.yml | The standard [shard.yml](https://crystal-lang.org/reference/the_shards_command/index.html) file, that lists the dependencies that are required to build your application. |

Now that the project structure is created, you can change into the `myblog` directory (if you haven't already) in order to install the project dependencies by running the following command:

```bash
shards install
```

:::info
Marten projects are organized around the concept of "apps". A Marten app is set of abstractions (usually defined under a unique folder) that contributes specific behaviours to a project. For example apps can provide [models](../models) or [views](../views). They allow to separate a project into a set of logical and reusable components. Another interesting benefit of apps is that they can be extracted and distributed as external shards. This pattern allows third-party libraries to easily contribute models, migrations, views, or templates to other projects. The use of apps is activated by simply adding app classes to the `installed_apps` setting.

By default, when creating a new project through the use of the `init` command, no explicit app will be created nor installed. This is because each Marten project comes with a default "main" app that corresponds to your standard `src` folder. Models, or other classes defined in this folder are associated with the main app by default, unless they are part of another explicitly defined application.

As projects grow in size and scope, it is generally encouraged to start thinking in terms of apps and how to split models, views, or features accross multiple apps depending on their intended responsibilities. Please refer to [Applications](../development/applications) to learn more about applications and how to structure your projects using them.
:::

## Running the development server

Now that you have a fully functional web project, you can start a development server by using the following command:

```bash
marten serve
```

This will start a Marten development server. To verify that it's working as expected, you can open a browser and navigate to [http://localhost:8000](http://localhost:8000). When doing so, you should be greated by the Marten "welcome" page:

![Marten welcome page](/img/getting-started/tutorial/marten_welcome_page.png)

:::info
Your project development server will automatically be available on the internal IP at port 8000. The server port and IP can be changed easily by modifying the `config/settings/development.cr` file:

```crystal
Marten.configure :development do |config|
  config.debug = true
  config.host = "localhost"
  config.port = 3000
end
```
:::

Once started, the development server will watch your project source files and will automatically recompile them when they are updated; it will also take care of restarting your project server. As such you don't have to manually restart the server when making changes to your application source files.

## Writing a first view

Let's start by creating a first view for your project. To do so, create a `src/views/home_view.cr`
file with the following content:

```crystal title="src/views/home_view.cr"
class HomeView < Marten::View
  def get
    respond("Hello World!")
  end
end
```

Views are classes that process a web request in order to produce a web response. This response can be a rendered HTML content or a redirection for example.

In the above example, the `HomeView` view explicitly processes a `GET` HTTP request and returns a very simple `200 OK` response containing a short text. But in order to access this view via a browser, it is necessary to map it to a URL route. To do so, you can edit the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeView, name: "home"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Views::Defaults::Development::ServeAsset, name: "asset"
  end
end
```

The `config/routes.cr` file was automatically created earlier when you initialized the project structure. By using the `#path` method you wired the `HomeView` into the routes configuration. 

The `#path` method accepts three arguments:

* the first argument is the route pattern, which is a string like `/foo/bar`. When Marten needs to resolve a route, it starts at the beginning of the routes array and compares each of the configured routes until it finds a matching one
* the second argment is the view class associated with the specified route. When a request URL is matched to a specific route, Marten executes the view that is associated with it
* the last argument is the route name. This is an identifier that can later be used in your codebase to generate the full URL for a specific route, and optionally inject parameters in it

## Creating the Article model
