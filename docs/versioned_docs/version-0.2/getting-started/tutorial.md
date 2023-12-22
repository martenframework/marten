---
title: Tutorial
description: Learn how to use Marten by creating a simple web application.
---

This guide will walk you through the creation of a simple weblog application, which will help you learn the basics of the Marten web framework. It is designed for beginners who want to get started by creating a Marten web project, so no prior experience with the framework is required.

## Requirements

This guide assumes that [Crystal and the Marten CLI are properly installed already](./installation.md). You can verify that the Marten CLI is properly installed by running the following command:

```bash
marten -v
```

This should output the version of your Marten installation.

## What is Marten?

Marten is a web application framework written in the Crystal programming language. It is designed to make developing web applications easy and fun; and it does so by making some assumptions regarding the common needs that developers may encounter when building web applications.

## Creating a project

Creating a project is the first thing to do in order to start working on a Marten web application. This creation process can be done through the use of the `marten` command, and it will ensure that the basic structure of a Marten project is properly generated.

This can be achieved from the command line, where you can run the following command to create your first Marten project:

```bash
marten new project myblog
```

The above command will create a `myblog` directory inside your current directory. This new folder should have the following content:

```
myblog/
├── config
│   ├── initializers
│   ├── settings
│   │   ├── base.cr
│   │   ├── development.cr
│   │   ├── production.cr
│   │   └── test.cr
│   └── routes.cr
├── spec
│   └── spec_helper.cr
├── src
│   ├── assets
│   ├── handlers
│   ├── migrations
│   ├── models
│   ├── schemas
│   ├── templates
│   ├── cli.cr
│   ├── project.cr
│   └── server.cr
├── manage.cr
└── shard.yml
```

These files and folders are described below:

| Path | Description |
| ----------- | ----------- |
| config/ | Contains the configuration of the project. This includes environment-specific Marten configuration settings, initializers, and web application routes. |
| spec/ | Contains the project specs, allowing you to test your application. | 
| src/ | Contains the source code of the application. By default this folder will include a `project.cr` file (where all dependencies - including Marten itself - are required), a `server.cr` file (which starts the Marten web server), a `cli.cr` file (where migrations and CLI-related abstractions are required), and `assets`, `handlers`, `migrations`, `models`, `schemas`, and `templates` folders. |
| .gitignore | Regular `.gitignore` file which tells git the files and directories that should be ignored. |
| manage.cr | This file defines a CLI that lets you interact with your Marten project in order to perform various actions (e.g. running database migrations, collecting assets, etc). |
| shard.yml | The standard [shard.yml](https://crystal-lang.org/reference/the_shards_command/index.html) file, that lists the dependencies that are required to build your application. |

Now that the project structure is created, you can change into the `myblog` directory (if you haven't already) in order to install the project dependencies by running the following command:

```bash
shards install
```

:::info
Marten projects are organized around the concept of "apps". A Marten app is a set of abstractions (usually defined under a unique folder) that contributes specific behaviours to a project. For example, apps can provide [models](../models-and-databases.mdx) or [handlers](../handlers-and-http.mdx). They allow to separate a project into a set of logical and reusable components. Another interesting benefit of apps is that they can be extracted and distributed as external shards. This pattern allows third-party libraries to easily contribute models, migrations, handlers, or templates to other projects. The use of apps is activated by simply adding app classes to the [`installed_apps`](../development/reference/settings.md#installed_apps) setting.

By default, when creating a new project through the use of the [`new`](../development/reference/management-commands.md#new) command, no explicit app will be created nor installed. This is because each Marten project comes with a default "main" app that corresponds to your standard `src` folder. Models, migrations, or other classes defined in this folder are associated with the main app by default, unless they are part of another explicitly defined application.

As projects grow in size and scope, it is generally encouraged to start thinking in terms of apps and how to split models, handlers, or features across multiple apps depending on their intended responsibilities. Please refer to [Applications](../development/applications.md) to learn more about applications and how to structure your projects using them.
:::

## Running the development server

Now that you have a fully functional web project, you can start a development server by using the following command:

```bash
marten serve
```

This will start a Marten development server. To verify that it's working as expected, you can open a browser and navigate to [http://localhost:8000](http://localhost:8000). When doing so, you should be greeted by the Marten "welcome" page:

![Marten welcome page](../static/img/getting-started/tutorial/marten_welcome_page.png)

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

Once started, the development server will watch your project source files and will automatically recompile them when they are updated; it will also take care of restarting your project server. As such, you don't have to manually restart the server when making changes to your application source files.

## Writing a first handler

Let's start by creating the first handler for your project. To do so, create a `src/handlers/home_handler.cr` file with the following content:

```crystal title="src/handlers/home_handler.cr"
class HomeHandler < Marten::Handler
  def get
    respond("Hello World!")
  end
end
```

Handlers are classes that process a web request in order to produce a web response. This response can be rendered HTML content or a redirection for example.

In the above example, the `HomeHandler` handler explicitly processes a `GET` HTTP request and returns a very simple `200 OK` response containing a short text. But in order to access this handler via a browser, it is necessary to map it to a URL route. To do so, you can edit the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  // highlight-next-line
  path "/", HomeHandler, name: "home"
  // highlight-next-line

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

The `config/routes.cr` file was automatically created earlier when you initialized the project structure. By using the `#path` method you wired the `HomeHandler` into the routes configuration. 

The `#path` method accepts three arguments:

* the first argument is the route pattern, which is a string like `/foo/bar`. When Marten needs to resolve a route, it starts at the beginning of the routes array and compares each of the configured routes until it finds a matching one
* the second argument is the handler class associated with the specified route. When a request URL is matched to a specific route, Marten executes the handler that is associated with it
* the last argument is the route name. This is an identifier that can later be used in your codebase to generate the full URL for a specific route, and optionally inject parameters in it

Now if you go to [http://localhost:8000](http://localhost:8000), you will get the `Hello World!` response that is generated by the handler you just wrote.

:::tip
Multiple routes can map to the same handler class if necessary.
:::

:::info
Please refer to [Routing](../handlers-and-http/routing.md) to learn more about Marten's routing mechanism.
:::

## Creating the Article model

[Models](../models-and-databases/introduction.md) are classes that define what data can be persisted and manipulated by a Marten application. They explicitly specify fields and rules that map to database tables and columns. Model records can be queried and interacted with through a mechanism called [Query sets](../models-and-databases/queries.md).

Let's define an `Article` model, which is the linchpin of any weblog application. To do set, let's create a `src/models/article.cr` file with the following content:

```crystal title="src/models/article.cr"
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
end
```

As you can see, Marten models are defined as subclasses of the `Marten::Model` base class, and they explicitly define "fields" through the use of a `field` macro.

In its current state, our `Article` model contains the following three fields:

* `id` is a big integer that will hold the unique identifier of an article (primary key of the underlying table record)
* `title` is a string column (`VARCHAR(255)`) that will hold the title of an article
* `content` is a text column (`TEXT`) that will hold the textual content of an article

## Generating and running migrations

Our `Article` model above is defined but is not "applied" at the database level yet. In order to create the corresponding table and columns, we will need to generate a [migration](../models-and-databases/migrations.md) for it.

Marten provides a migrations mechanism that is designed to be automatic: this means that migrations will be automatically derived from your model definitions. This allows to ensure that the definition of your model and its fields (and underlying columns) is done in one place only, which helps keep your project DRY.

In order to generate the migration file for the model we created previously, all we need to do is to run the following Marten command:

```shell
marten genmigrations
```

This will output something along those lines:

```shell
Generating migrations for app 'main':
  › Creating [src/migrations/202208072015231_create_main_article_table.cr]... DONE
      ○ Create main_article table
```

The `genmigrations` command is a way to tell Marten to introspect your project in order to identify whether you added, removed, or modified models. The changes identified by this command are persisted in migration files (living under `migrations/` folders in each Marten application), that you can run later on in order to apply them at the database level.

Now that we have generated a migration file for our `Article` model, we can apply it at the database level by running the following command:

```shell
marten migrate
```

Which will output the following content:

```shell
Running migrations:
  › Applying main_202208072015231_create_main_article_table... DONE
```

The `migrate` command will identify all the migration files that weren't applied to your database yet, and will run them one by one. By doing so, Marten will ensure that the changes you made to your model definitions are applied at the database level, in the corresponding tables.

:::info
Please refer to [Migrations](../models-and-databases/migrations.md) to learn more about migrations.
:::

:::note
For new projects, Marten uses a SQLite database by default. In our case, if we look at the `config/settings/base.cr` file, we can see that the current database configuration looks something like this:

```crystal
config.database do |db|
  db.backend = :sqlite
  db.name = Path["myblog.db"].expand
end
```

An SQLite database is a good choice in order to try Marten and experiment with it (since SQLite is already pre-installed on most systems). That being said, if you need to use another database backend (for example, PostgreSQL or MySQL), feel free to have a look at the [databases configuration reference](../development/reference/settings.md#database-settings).
:::

## Interacting with model records

Now that our `Article` model table has been created at the database level, let's try to make use of the Marten ORM to create and query article records.

To do so, we can launch the [Crystal playground](https://crystal-lang.org/reference/master/using_the_compiler/index.html#crystal-play) as follows:

```shell
crystal play
```

You should be able to navigate to [http://localhost:8080](http://localhost:8080) and see a Crystal editor. Once you are there, replace the content of the live editor with the following:

```crystal
require "./src/project"
Marten.setup
```

These lines basically require your project dependencies and ensure that Marten is properly set up. You should keep those in the editor when playing with the following examples. Each of the following snippets is assumed to be copied/pasted below the previous one. The output of these examples is highlighted next to the `# =>` comment line.

Let's start by initializing a new `Article` object:

```crystal
article = Article.new(title: "My article", content: "This is my article.")
# => #<Article:0x102c4dbe0 id: nil, title: "My article", content: "This is my article.">
```

As you can see, by using `#new`, we are initializing a new `Article` object by specifying its field values (`title` and `content`). It should be noted that so far, the object is only _initialized_ and is not saved to the database yet (this is why `id` is set to `nil` in the above snippet). In order to persist the new object at the database level, you can make use of the `#save` method:

```crystal
article.save
# => true
```

The output of the `#save` method is a boolean indicating the result of the object validation: in our case, `true` means that the `Article` object was successfully validated and that the corresponding record was created at the database level.

Now if we inspect the `article` object again, we should observe that an `id` has been set for the record at hand:

```crystal
article
# => #<Article:0x104ee1c30 id: 1, title: "My article", content: "This is my article.">
```

If we want to fetch this record from the database again, we can use the [`#get`](../models-and-databases/reference/query-set.md#get) method and specify the identifier value of the record we want to retrieve. For example:

```crystal
article = Article.get(id: 1)
# => #<Article:0x104c699b0 id: 1, title: "My article", content: "This is my article.">
```

Now we can try to retrieve all the `Article` records that we currently have in the database. This is done by calling the `#all` method on the `Article` model:

```crystal
Article.all
# => <Marten::DB::Query::Set(Article) [#<Article:0x1039296e0 id: 1, title: "My article", content: "This is my article.">]>
```

This method returns a `Marten::DB::Query::Set` object, which is commonly referred to as a "query set". A query set is a representation of records collections from the database that can be filtered, and iterated over.

:::info
Please refer to [Queries](../models-and-databases/queries.md) to learn more about Marten's querying capabilities.
:::

## Showing a list of articles

Let's revisit our initial implementation of the `HomeHandler` handler we defined [earlier](#writing-a-first-handler).

Since we are building a weblog application, it would make sense to display a list of all our `Article` objects on the index page. To do so, let's update the existing `src/handlers/home_handler.cr` file with the following content:

```crystal title="src/handlers/home_handler.cr"
class HomeHandler < Marten::Handler
  def get
    render("home.html", context: { articles: Article.all })
  end
end
```

The `#render` method that is used above allows to return an HTTP response whose content is generated by rendering a specific [template](../templates.mdx). The template can be rendered by specifying a context hash or a named tuple. In our case the template context contains an `articles` key that maps to a query set of all the `Article` records.

Now if you start the Marten development server again and then try to access the home page ([http://localhost:8000](http://localhost:8000)), you should get an error stating that the `home.html` template does not exist. This is normal: we need to create it.

Templates provide a convenient way for defining the presentation logic of a web application. They allow to write HTML content that is rendered dynamically by using variables that you specify in a "template context". This rendering process can involve model records or any other variables you define.

Let's define the expected template for our home handler by creating a `src/templates/home.html` file with the following content:

```html title="src/templates/home.html"
{% extend "base.html" %}

{% block content %}
  <h1>My blog</h1>
  <h2>Articles:</h2>
  <ul>
  {% for article in articles %}
    <li>{{ article.title }}</li>
  {% endfor %}
  </ul>
{% endblock %}
```

As you can see, Marten's templating system relies on variables that are surrounded by **`{{`** and **`}}`**. Each variable can involve lookups in order to access specific object attributes. In the above example `{{ article.title }}` means that the `title` attribute of the `article` variable should be outputted.

Method-calling is done by using statements (also called "template tags") delimited by **`{%`** and **`%}`**. Such statements can involve for loops, if conditions, etc. In the above example we are using a for loop to iterate over the `Article` records in the `articles` query set that is "passed" to the template context in our `HomeHandler` handler.

:::info
Please refer to [Templates](../templates/introduction.md) to learn more about Marten's templating system.
:::

:::info
What about the `extend` and `block` tags in the previous snippet? These tags allow to "extend" a "base" template that usually contains the layout of an application (`base.html` in the above snippet) and to explicitly define the contents of the "blocks" that are expected by this base template. New marten projects are created with a simple `base.html` template that defines a very basic HTML document, whose body is filled with the content of a `content` block. This is why templates in this tutorial extend a `base.html` and override the content of the `content` block.

You can learn more about these capabilities in [Template inheritance](../templates/introduction.md#template-inheritance).
:::

If you go back to the home page ([http://localhost:8000](http://localhost:8000)), you should be able to see a list of article titles corresponding to all the `Article` records you created previously.

We have now pieced together the main components of the Marten web framework (Models, Handlers, Templates). When accessing the home page of our application, the following steps are taken care of by the framework:

1. the browser issues a GET request to `http://localhost:8000` 
2. the Marten web application that is currently running receives the request
3. the Marten routing system maps the path of the incoming request to the `HomeHandler` handler
4. the handler is initialized and executed, which involves fetching all the `Article` records
5. the handler renders the `home.html` template and returns a `200 OK` response containing the rendered content
6. the Marten server sends the response with the HTML content back to the browser

## Showing a single article

We presently have a handler that lists all the existing `Article` records, but it would be nice to be able to actually see the content of each article individually.

To do so, let's create a new `src/handlers/article_detail_handler.cr` handler file with the following content:

```crystal title="src/handlers/article_detail_handler.cr"
class ArticleDetailHandler < Marten::Handler
  def get
    render("article_detail.html", context: { article: Article.get!(id: params["pk"]) })
  rescue Marten::DB::Errors::RecordNotFound
    raise Marten::HTTP::Errors::NotFound.new("Article not found")
  end
end
```

Like in the previous example, we will be relying on the `#render` method to render a template and return the corresponding HTTP response. But this time we will be retrieving a specific record whose parameter will be specified in a `pk` route parameter.

:::note
You will note that we are making use of the `#get!` method to retrieve the model record in the above example. This method behaves similarly to the `#get` method we saw earlier, but it will raise a "record not found" exception if no record can be found for the specified parameters. In that case we can "rescue" this error in order to raise an "Not Found" HTTP exception that will result in a 404 response to be returned.
:::

Let's now map this handler to a new route by adding the following line to the `config/routes.cr` file:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  // highlight-next-line
  path "/article/<pk:int>", ArticleDetailHandler, name: "article_detail"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

As you can see above, the new route we mapped to the `ArticleDetailHandler` handler requires a `pk` - _primary key_ - integer (`int`) parameter. Route parameters are defined using angle brackets, and the name of the parameter and its type are separated by a `:` character (`<name:type>` format).

Obviously, we also need to define the `article_detail.html` template. To do so, let's create a `src/templates/article_detail.html` with the following content:

```html title="src/templates/article_detail.html"
{% extend "base.html" %}

{% block content %}
  <h1>{{ article.title }}</h1>
  <p>{{ article.content }}</p>
{% endblock %}
```

Now if you try to access [http://localhost:8000/article/1](http://localhost:8000/article/1), you will be able to see the content of the `Article` record with ID 1.

There is something missing though: the home page does not link to the "detail" page of each article. To remediate this, we can modify the `src/templates/home.html` template file as follows:

```html title="src/templates/home.html"
{% extend "base.html" %}

{% block content %}
  <h1>My blog</h1>
  <h2>Articles:</h2>
  <ul>
  {% for article in articles %}
  // highlight-next-line
    <li>
  // highlight-next-line
      {{ article.title }}
  // highlight-next-line
      &dash; <a href="{% url 'article_detail' pk: article.id %}">View</a>
  // highlight-next-line
    </li>
  {% endfor %}
  </ul>
{% endblock %}
```

The `url` tag used in the above snippet allows to perform a reverse URL resolution. This allows to generate the final URL associated with a specific route name (the `article_detail` route name we defined earlier in this case). This reverse resolution can involve parameters if the considered route require ones.

:::info
Please refer to [Routing](../handlers-and-http/routing.md) to learn more about Marten's routing system.
:::

## Creating a new article

So far we only implemented support for "read" operations: we made it possible to list all the available articles in the home page, and we added the ability to see the content of a specific article in the "detail" page. The next step will be to make it possible to create new articles in order to populate our weblog.

To do so, let's start by creating a new `src/schemas/article_schema.cr` schema file with the following content:

```crystal title="src/schemas/article_schema.cr"
class ArticleSchema < Marten::Schema
  field :title, :string, max_size: 255
  field :content, :string
end
```

We just defined a "schema". Schemas are classes that define how input data should be serialized / deserialized, and validated. Schemas are usually used when processing web requests containing form data or pre-defined payloads. Like models, they contain a set of pre-defined fields that indicate what parameters are expected, what are their types, and how they should be validated.

Let's see how we can use this schema in a handler. In this light, let's create a new `src/handlers/article_create_handler.cr` file:

```crystal title="src/handlers/article_create_handler.cr"
class ArticleCreateHandler < Marten::Handler
  @schema : ArticleSchema?

  def get
    render("article_create.html", context: { schema: schema })
  end

  def post
    if schema.valid?
      article = Article.new(schema.validated_data)
      article.save!

      redirect(reverse("home"))
    else
      render("article_create.html", context: { schema: schema })
    end
  end

  private def schema
    @schema ||= ArticleSchema.new(request.data)
  end
end
```

This handler is able to handle both GET and POST requests:

* when the incoming request is a GET, it will simply render the `article_create.html` template, and initialize the schema (instance of `ArticleSchema`) with any data currently present in the request object (which is returned by the `#request` method). This schema object is made available to the template context
* when the incoming request is a POST, it will initialize the schema and try to see if it is valid considering the incoming data. If it's valid, then the new `Article` record will be created using the schema's validated data, and the user will be redirect to the home page. Otherwise, the `article_create.html` template will be rendered again with the invalid schema in the associated context

In the above snippet, we make use of `#redirect` in order to indicate that we want to return a 302 Found HTTP response, and we generate the redirection URL by performing a reverse resolution of the `home` route we introduced earlier by using the `#reverse` method (which is similar to the `url` template tag we encountered in the previous section).

We can now create the `article_create.html` template file with the following content:

```html title="src/templates/article_create.html"
{% extend "base.html" %}

{% block content %}
  <h1>Create a new article</h1>
  <form method="post" action="" novalidate>
    <input type="hidden" name="csrftoken" value="{% csrf_token %}" />

    <div><label>Title</label></div>
    <input type="text" name="{{ schema.title.id }}" value="{{ schema.title.value }}"/>
    {% for error in schema.title.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

    <div><label>Content</label></div>
    <textarea name="{{ schema.content.id }}" value="{{ schema.content.value }}">{{ schema.content.value }}</textarea>
    {% for error in schema.content.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

    <div><button>Submit</button></div>
  </form>
{% endblock %}
```

As you can see, the above snippet defines a form that includes two fields: one for the `title` schema field and the other one for the `content` schema field. Each schema field can be errored depending on the result of a validation, and this is why specific field errors are (optionally) displayed as well.

:::tip What about the hidden CSRF token input?
The `csrftoken` input in the above example is mandatory because every unsafe request (eg. POST) is automatically protected by a CSRF (Cross-Site Request Forgeries) check. Please refer to [Cross-Site Request Forgery protection](../security/csrf.md) to learn more about this.
:::

Finally, we need to map the `ArticleCreateHandler` handler to a proper route. We can do this by editing the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  // highlight-next-line
  path "/article/create", ArticleCreateHandler, name: "article_create"
  path "/article/<pk:int>", ArticleDetailHandler, name: "article_detail"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

Now if you open your browser at [http://localhost:8000/article/create](http://localhost:8000/article/create), you should be able to see a very rough form allowing to create a new `Article` record and to redirect to it.

Obviously, we still need to a link somewhere in our application to be able to easily access the article creation form. In this light, we can modify the `home.html` template file as follows:

```html title="src/templates/home.html"
{% extend "base.html" %}

{% block content %}
  <h1>My blog</h1>
  // highlight-next-line
  <a href="{% url 'article_create' %}">Create new article</a>
  <h2>Articles:</h2>
  <ul>
  {% for article in articles %}
    <li>
      {{ article.title }}
      &dash; <a href="{% url 'article_detail' pk: article.id %}">View</a>
    </li>
  {% endfor %}
  </ul>
{% endblock %}
```

:::info
Please refer to [Schemas](../schemas/introduction.md) to learn more about schemas.
:::

## Updating an article

Now that we are able to create new `Article` records, let's add the ability to update existing records. To do so, we will implement a handler that works similarly to the `ArticleCreateHandler` handler we defined earlier: it should be able to process GET requests in order to display an "update" form, and it should validate the incoming data (and update the right record) when POST requests are submitted through an HTML form.

In this light, let's define the `src/handlers/article_update_handler.cr` file with the following content:

```crystal title="src/handlers/article_update_handler.cr"
class ArticleUpdateHandler < Marten::Handler
  @article : Article?
  @schema : ArticleSchema?

  def get
    render("article_update.html", context: { article: article, schema: schema })
  end

  def post
    if schema.valid?
      article.update!(schema.validated_data)
      redirect(reverse("home"))
    else
      render("article_update.html", context: { article: article, schema: schema })
    end
  end

  private def article
    @article ||= Article.get!(id: params["pk"])
  rescue Marten::DB::Errors::RecordNotFound
    raise Marten::HTTP::Errors::NotFound.new("Article not found")
  end

  private def initial_schema_data
    Marten::Schema::DataHash{ "title" => article.title, "content" => article.content }
  end

  private def schema
    @schema ||= ArticleSchema.new(request.data, initial: initial_schema_data)
  end
end
```

Here the `#get` and `#post` method implementations look similar to what was introduced for the `ArticleCreateHandler` handler. The main difference is that a specific `Article` record needs to be retrieved. Moreover the `ArticleSchema` schema is initialized with some "initial data" (`Marten::Schema::DataHash` hash-like object) that corresponds to the current `title` and `content` field values of the considered record. When a valid schema is processed, instead of creating a new record, we simply update the considered one through the use of the `#update!` method.

We can now create the `article_update.html` template file with the following content:

```html title="src/templates/article_update.html"
{% extend "base.html" %}

{% block content %}
  <h1>Update article "{{ article.title }}"</h1>
  <form method="post" action="" novalidate>
    <input type="hidden" name="csrftoken" value="{% csrf_token %}" />

    <div><label>Title</label></div>
    <input type="text" name="{{ schema.title.id }}" value="{{ schema.title.value }}"/>
    {% for error in schema.title.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

    <div><label>Content</label></div>
    <textarea name="{{ schema.content.id }}" value="{{ schema.content.value }}">{{ schema.content.value }}</textarea>
    {% for error in schema.content.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

    <div><button>Submit</button></div>
  </form>
{% endblock %}
```

As you can see, this looks very similar to what we did previously with the `article_create.html` template file.

Let's now map the `ArticleUpdateHandler` handler to a proper route. We can do this by editing the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/article/create", ArticleCreateHandler, name: "article_create"
  path "/article/<pk:int>", ArticleDetailHandler, name: "article_detail"
  // highlight-next-line
  path "/article/<pk:int>/update", ArticleUpdateHandler, name: "article_update"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

Now if you open your browser at [http://localhost:8000/article/1/update](http://localhost:8000/article/1/update), you should be able to see a very rough form allowing to update the `Article` record with ID 1.

We can also add a link somewhere in the home page of the application to be able to easily access the update form for existing articles. In this light, we can modify the `home.html` template file as follows:

```html title="src/templates/home.html"
{% extend "base.html" %}

{% block content %}
  <h1>My blog</h1>
  <a href="{% url 'article_create' %}">Create new article</a>
  <h2>Articles:</h2>
  <ul>
  {% for article in articles %}
    <li>
      {{ article.title }}
      &dash; <a href="{% url 'article_detail' pk: article.id %}">View</a>
      // highlight-next-line
      &dash; <a href="{% url 'article_update' pk: article.id %}">Update</a>
    </li>
  {% endfor %}
  </ul>
{% endblock %}
```

## Deleting an article

Finally, the last missing feature we could add is the ability to delete an article. To do so, let's introduce a handler that works as follows: when processing a GET request the handler will ask the user to confirm that they want to indeed delete the considered `Article` record, and when processing a POST request the handler will actually delete the record and then redirect to the home page of the application.

In this light, let's define the `src/handlers/article_delete_handler.cr` file:

```crystal title="src/handlers/article_delete_handler.cr"
class ArticleDeleteHandler < Marten::Handler
  @article : Article?

  def get
    render("article_delete.html", context: { article: article })
  end

  def post
    article.delete
    redirect(reverse("home"))
  end

  private def article
    @article ||= Article.get!(id: params["pk"])
  rescue Marten::DB::Errors::RecordNotFound
    raise Marten::HTTP::Errors::NotFound.new("Article not found")
  end
end
```

In the above snippet, the `#get` method simply fetches the `Article` record by using the `pk` parameter value and renders the `article_delete.html` template (with the article in the associated context). The `#post` method fetches the `Article` record as well and deletes it before redirecting the user to the home page.

Let's now create the `article_delete.html` template file with the following content:

```html title="src/templates/article_delete.html"
{% extend "base.html" %}

{% block content %}
  <h1>Delete article "{{ article.title }}"</h1>
  <p>Are you sure?</p>
  <form method="post" action="">
    <input type="hidden" name="csrftoken" value="{% csrf_token %}" />
    <button>Yes, delete</button>
  </form>
{% endblock %}
```

This template simply asks the user for confirmation and displays a confirmation button embedded in a form to issue the POST request that will actually delete the record.

Let's now map the `ArticleDeleteHandler` handler to a proper route. We can do this by editing the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/article/create", ArticleCreateHandler, name: "article_create"
  path "/article/<pk:int>", ArticleDetailHandler, name: "article_detail"
  path "/article/<pk:int>/update", ArticleUpdateHandler, name: "article_update"
  // highlight-next-line
  path "/article/<pk:int>/delete", ArticleDeleteHandler, name: "article_delete"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

Now if you open your browser at [http://localhost:8000/article/1/delete](http://localhost:8000/article/1/delete), you should be able to see a the confirmation page allowing to delete the `Article` record with ID 1.

We can also add a link somewhere in the home page of the application to be able to easily access the delete confirmation page for existing articles. In this light, we can modify the `home.html` template file as follows:

```html title="src/templates/home.html"
{% extend "base.html" %}

{% block content %}
  <h1>My blog</h1>
  <a href="{% url 'article_create' %}">Create new article</a>
  <h2>Articles:</h2>
  <ul>
  {% for article in articles %}
    <li>
      {{ article.title }}
      &dash; <a href="{% url 'article_detail' pk: article.id %}">View</a>
      &dash; <a href="{% url 'article_update' pk: article.id %}">Update</a>
      // highlight-next-line
      &dash; <a href="{% url 'article_delete' pk: article.id %}">Delete</a>
    </li>
  {% endfor %}
  </ul>
{% endblock %}
```

## Refactoring: using template partials

The templates used for creating and updating an article look the same: they both make use of the same schema in order to create or update articles. It would be interesting to be able to reuse this form for both templates. This is where template "partials" cames in handy: these are template snippets that can be easily "included" into other templates to avoid duplications of code.

Let's create a `src/templates/partials/article_form.html` partial with the following content:

```html title="src/templates/partials/article_form.html"
<form method="post" action="" novalidate>
  <input type="hidden" name="csrftoken" value="{% csrf_token %}" />

  <div><label>Title</label></div>
  <input type="text" name="{{ schema.title.id }}" value="{{ schema.title.value }}"/>
  {% for error in schema.title.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

  <div><label>Content</label></div>
  <textarea name="{{ schema.content.id }}" value="{{ schema.content.value }}">{{ schema.content.value }}</textarea>
  {% for error in schema.content.errors %}<p class="input-error"><small>{{ error.message }}</small></p>{% endfor %}

  <div><button>Submit</button></div>
</form>
```

This partial template contains the exact same form that we used in the creation and update templates.

Let's now make use of this partial in the `src/templates/article_create.html` and `src/templates/article_update.html` templates:

```html title="src/templates/article_create.html"
{% extend "base.html" %}

{% block content %}
  <h1>Create a new article</h1>
  {% include "partials/article_form.html" %}
{% endblock %}
```

```html title="src/templates/article_update.html"
{% extend "base.html" %}

{% block content %}
  <h1>Update article "{{ article.title }}"</h1>
  {% include "partials/article_form.html" %}
{% endblock %}
```

As you can see, the creation and update templates are now much more simple.

## Refactoring: using generic handlers

The handlers we implemented previously map to common web development use cases: retrieving data from the database - from a specific URL paramater - and displaying it, listing multiple objects, creating or updating records, etc. These use cases are so frequently encountered that Marten provides a set of "generic handlers" that allow to easily implement them. These generic handlers take care of these common patterns so that developers don't end up reimplementing the wheel.

We could definitely leverage these generic handlers as part of our weblog application.

In this light, let's start with the `HomeHandler` class we implemented earlier: this handler essentially retrieves all the `Article` records and makes this list available to the `home.html` template. This pattern is enabled by the [`Marten::Handlers::RecordList`](pathname:///api/0.2/Marten/Handlers/RecordList.html) generic handler. In order to use it, let's modify the `src/handlers/home_handler.cr` file as follows:

```crystal title="src/handlers/home_handler.cr"
class HomeHandler < Marten::Handlers::RecordList
  model Article
  template_name "home.html"
  list_context_name "articles"
end
```

In the above snippet we use a few class methods in order to define how the handler should behave: `#model` allows to define the model class that should be used to retrieve the record, `#template_name` allows to define the name of the template to render, and `#list_context_name` allows to define the name of the record list variable in the template context.

Let's continue with the `ArticleDetailHandler` class: this handler retrieves a specific `Article` record from a `pk` route parameter, and "renders" it using a specific template. This pattern is enabled by the [`Marten::Handlers::RecordDetail`](pathname:///api/0.2/Marten/Handlers/RecordDetail.html) generic handler. In order to use it, let's modify the `src/handlers/article_detail_handler.cr` file as follows:

```crystal title="src/handlers/article_detail_handler.cr"
class ArticleDetailHandler < Marten::Handlers::RecordDetail
  model Article
  template_name "article_detail.html"
  record_context_name "article"
end
```

In order to configure how the handler should behave, we make use of a few class methods here as well: `#model` allows to define the model class of the record that should be retrieved, `#template_name` defines the template to render, and `#record_context_name` defines the name of the record variable in the template context.

Now let's look at the `ArticleCreateHandler` class: this class displays a form when processing GET requests, and it validates a schema that is used to create a specific record when processing POST requests. This exact pattern is enabled by the [`Marten::Handlers::RecordCreate`](pathname:///api/0.2/Marten/Handlers/RecordCreate.html) generic handler. In order to use it, we can modify the `src/handlers/article_create_handler.cr` file as follows:

```crystal title="src/handlers/article_create_handler.cr"
class ArticleCreateHandler < Marten::Handlers::RecordCreate
  model Article
  schema ArticleSchema
  template_name "article_create.html"
  success_route_name "home"
end
```

Here, `#model` allows to define the model class to use to create the new record, `#schema` is the schema class that should be used to validated the incoming data, `#template_name` defines the name of the template to render, and `#success_route_name` is the name of the route to redirect to after a successful record creation.

We can now look at the `ArticleUpdateHandler` class: this class retrieves a specific record and displays a form when processing GET requests, and it validates a schema whose data is used to update the record when processing POST requests. This pattern is enabled by the [`Marten::Handlers::RecordUpdate`](pathname:///api/0.2/Marten/Handlers/RecordUpdate.html) generic handler. Let's use it and let's modify the `src/handlers/article_update_handler.cr` file as follows:

```crystal title="src/handlers/article_update_handler.cr"
class ArticleUpdateHandler < Marten::Handlers::RecordUpdate
  model Article
  schema ArticleSchema
  template_name "article_update.html"
  success_route_name "home"
  record_context_name "article"
end
```

Here, `#model` allows to define the model class to use to retrieve and update the record, `#schema` is the schema class that should be used to validated the incoming data, `#template_name` defines the name of the template to render, `#success_route_name` is the name of the route to redirect to after a successful record update, and `#record_context_name` is the name of the record variable in the template context.

Finally, let's look at the `ArticleDeleteHandler` class: this handler renders a template when processing GET requests, and performs the deletion of the considered record when processing POST requests. This pattern is provided by the [`Marten::Handlers::RecordDelete`](pathname:///api/0.2/Marten/Handlers/RecordDelete.html) generic handler. In order to use it, let's modify the `src/handlers/article_delete_handler.cr` file as follows:

```crystal title="src/handlers/article_delete_handler.cr"
class ArticleDeleteHandler < Marten::Handlers::RecordDelete
  model Article
  template_name "article_delete.html"
  success_route_name "home"
  record_context_name "article"
end
```

In order to configure how the handler should behave, we make use of a few class methods here as well: `#model` allows to define the model class of the record that should be retrieved and deleted, `#template_name` defines the template to render, and `#success_route_name` defines the name of the route to redirect to once the record is deleted.

Now if you go to your application again at [http://localhost:8000](http://localhost:8000), you will notice that everything is working like it used to do before we introduced these changes (but with less code!).

:::info
Please refer to [Generic handlers](../handlers-and-http/generic-handlers.md) to learn more about generic handlers.
:::

## What's next?

As part of this tutorial, we covered the main features of the Marten web framework by implementing a very simple application: 

* we learned to define [models](../models-and-databases.mdx) in order to interact with the database
* we learned to create [handlers](../handlers-and-http.mdx) and to map URLs to these in order to process HTTP requests
* we learned to render [templates](../templates.mdx) in order to define the presentation logic of an application

Now that you've experimented with these core concepts of the framework, you should not hesitate to update the application we just created in order to experiment further and add new features to it.

The Marten documentation also contains plenty of additional guides allowing you to keep exploring and learning more about other areas of the framework. These may be useful depending on the specific needs of your application: [Testing](../development/testing.md), [Applications](../development/applications.md), [Security](../security.mdx), [Internationalization](../i18n.mdx), etc.
