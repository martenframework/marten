---
title: Routing
description: Learn how to map handlers to routes.
sidebar_label: Routing
---

Marten gives you the ability to design your URLs the way you want, by allowing you to easily map routes to specific [handlers](./introduction.md), and by letting you generate paths and URLs from your application code.

## The basics

In order to access a handler via a browser, it is necessary to map it to a URL route. To do so, route "maps" can be used to define mappings between route paths and existing handler classes. These route maps can be as long or as short as needed, but it is generally a good idea to create sub routes maps that are included in the main routes map.

The main routes map usually lives in the `config/routes.cr` file. For example, the content of such a file could look like this:

```crystal
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/articles", ArticlesHandler, name: "articles"
  path "/articles/<pk:int>", ArticleDetailHandler, name: "article_detail"
end
```

As you can see, routes are defined by calling a `#path` method that requires three arguments:

* the first argument is the route pattern, which is a string like `/foo/bar` and which can contain additional [parameters](#specifying-route-parameters)
* the second argument is the handler class associated with the specified route
* the last argument is the route name, which is an identifier that can later be used in your codebase to generate the full URL for a specific route, and optionally inject parameters in it (see [Reverse URL resolutions](#reverse-url-resolutions))

:::tip
It is possible to map multiple routes to the same handler class if necessary. This can be useful if you need to provide route aliases for some handlers for example.
:::

These routes are evaluated and constructed at runtime, which means that you can define conditional routes if you need to. For example, a "debug" handler (only available in a development environment) could be added to the above routes map with the following addition:

```crystal
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/articles", ArticlesHandler, name: "articles"
  path "/articles/<pk:int>", ArticleDetailHandler, name: "article_detail"

  // highlight-next-line
  if Marten.env.development?
    // highlight-next-line
    path "/debug", DebugHandler, name: "debug"
  // highlight-next-line
  end
end
```

When a URL is requested, Marten runs through all the defined routes to identify a matching one. The handler associated with this route will be initialized from the route parameters (if there are any) and the handler object will be used to respond to the considered request.

It should be noted that if no route is matched for a specific URL, Marten will automatically return a 404 Not Found response, by leveraging a configurable [error handler](./error-handlers.md).

## Specifying route parameters

As highlighted in the previous examples, route parameters can be defined using angle brackets. Each route parameter must define a mandatory name and an optional type using the following syntaxes:

* `<name>`
* `<name:type>`

When no type is specified for a parameter, any string excluding the forward slash character (**`/`**) will be matched.

The following route parameter types are available:

| Type | Description |
| ----------- | ----------- |
| `str` or `string` | Matches any non-empty string (excluding the forward slash character **`/`**). This is the default parameter type used for untyped parameters (eg. `<myparam>`). |
| `int` | Matches zero or any positive integer. These parameter values are always deserialized as `UInt64` objects. |
| `path` | Matches any non-empty strings including forward slash characters (**`/`**). For example `foo/bar/xyz` could be matched by this parameter type. |
| `slug` | Matches any string containing only ASCII letters, numbers, hyphen, and underscore characters. For example `my-first-project-01` could be matched by this parameter type. |
| `uuid` | Matches a valid UUID string. These parameter values are always deserialized as `UUID` objects. |

It should be noted that it is possible to register custom route parameter implementations if needed. See [Create custom route parameters](./how-to/create-custom-route-parameters.md) to learn more about this capability.

## Defining included routes

The main routes map (which usually lives in the `config/routes.cr` file) does not have to be a "flat" definition of all the available routes. Indeed, you can define "sub" routes maps if you need to and "include" these in your main routes map.

This capability can be extremely useful to "include" a set of routes from an installed application (a third-party library or one of your in-project applications). This also allows better organizing route namespaces and bundling a set of related routes under a similar prefix.

For example, a main routes map and an article routes map could be defined as follows:

```crystal
ARTICLE_ROUTES = Marten::Routing::Map.draw do
  path "", ArticlesHandler, name: "list"
  path "/create", ArticleCreateHandler, name: "create"
  path "/<pk:int>", ArticleDetailHandler, name: "detail"
  path "/<pk:int>/update", ArticleUpdateHandler, name: "update"
  path "/<pk:int>/delete", ArticleDeleteHandler, name: "delete"
end

Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/articles", ARTICLE_ROUTES, name: "articles"
end
```

In the above example, the following URLs would be generated by Marten in addition to the root URL:

| URL | Handler | Name |
| --- | ---- | ---- |
| `/articles` | `ArticlesHandler` | `articles:list` |
| `/articles/create` | `ArticleCreateHandler` | `articles:create` |
| `/articles/<pk:int>` | `ArticleDetailHandler` | `articles:detail` |
| `/articles/<pk:int>/update` | `ArticleUpdateHandler` | `articles:update` |
| `/articles/<pk:int>/delete` | `ArticleDeleteHandler` | `articles:delete` |

As you can see, both the URLs and the route names end up being prefixed respectively with the path and the name specified in the including route.

:::info
The `name` parameter for included routes is optional, i.e. `path "/articles", ARTICLE_ROUTES` is also valid. Please note that this will increase the possibility of a name collision and it is, therefore, advisable to prefix the individual paths of the included route, e.g. `article_list`, `article_create`, etc.

```crystal
ARTICLE_ROUTES = Marten::Routing::Map.draw do
  path "/", ArticlesHandler, name: "article_list"
  path "/create", ArticlesCreateHandler, name: "article_create"
end

Marten.routes.draw do
  path "/articles", ARTICLE_ROUTES
end
```

This example will generate the following URLs:

| URL | Handler | Name |
| --- | ------- | ---- |
| `/articles` | `ArticlesHandler` | `articles_list` |
| `/articles/create` | `ArticlesCreateHandler` | `articles_create` |

It is also possible to add a namespace to the included route at the map level:

```crystal
ARTICLE_ROUTES = Marten::Routing::Map.draw(:article) do
  path "/", ArticlesHandler, name: "list"
end

Marten.routes.draw do
  path "/articles", ARTICLE_ROUTES # Note: providing the name parameter overrides the namespace
end
```

This example will generate the following URLs:

| URL | Handler | Name |
| --- | ------- | ---- |
| `/articles` | `ArticlesHandler` | `articles:list` |
:::

Note that the sub-routes map does not have to live in the `config/routes.cr` file: it can technically live anywhere in your codebase. The ideal way to define the routes map of a specific application would be to put it in a `routes.cr` file in the application's directory.

When Marten encounters a path that leads to another sub-routes map, it chops off the part of the URL that was matched up to that point and then forwards the remaining to the sub-routes map in order to see if it is matched by one of the underlying routes.

## Reverse URL resolutions

When working with web applications, a frequent need is to generate URLs in their final forms. To do so, you will want to avoid hard-coding URLs and instead leverage the ability to generate them from their associated names: this is what we call a reverse URL resolution.

"Reversing" a URL is as simple as calling the [`Marten::Routing::Map#reverse`](pathname:///api/dev/Marten/Routing/Map.html#reverse(name%3AString|Symbol%2Cparams%3AHash(String|Symbol%2CParameter%3A%3ATypes))-instance-method) method from the main routes map, which is accessible through the use of the [`Marten#routes`](pathname:///api/dev/Marten.html#routes-class-method) method:

```crystal
Marten.routes.reverse("home") # will return "/"
```

In order to reverse a URL from within a handler class, you can simply leverage the [`Marten::Handlers::Base#reverse`](pathname:///api/dev/Marten/Handlers/Base.html#reverse(*args%2C**options)-instance-method) handler method:

```crystal
class MyHandler < Marten::Handler
  def post
    redirect(reverse("home"))
  end
end
```

As highlighted previously, some routes require one or more parameters and in order to reverse these URLs you can simply specify these parameters as arguments when calling `#reverse`:

```crystal
Marten.routes.reverse("article_detail", pk: 42) # will return "/articles/42"
```

Finally, it should be noted that the namespaces that are created when defining [included routes](#defining-included-routes) also apply when reversing the corresponding URLs. For example, the name allowing to reverse the URL associated with the `ArticleUpdateHandler` in the previous snippet would be `articles:update`:

```crystal
Marten.routes.reverse("articles:update", pk: 42) # will return "/articles/42/update"
```
