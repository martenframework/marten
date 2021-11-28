# Tutorial

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
| src/ | Contains the source code of the application. By default this folder will include a `project.cr` file (where all dependencies - including Marten itself - are required) and a `server.cr` file (which starts the Marten web server). |
| manage.cr | This file define a CLI that lets you interact with your Marten project in order to perform various actions (eg. running database migrations, collecting assets, etc). |
| shard.yml | The standard [shard.yml](https://crystal-lang.org/reference/the_shards_command/index.html) file, that lists the dependencies that are required to build your application. |

Now that the project structure is created, you can change into the `myblog` directory (if you haven't already) in order to install the project dependencies by running the following command:

```bash
shards install
```

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

## Creating the blog application
