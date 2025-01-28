---
title: Localized routes
description: Learn how to define localized routes.
---

Marten enables route internationalization through two mechanisms: automatically adding locale prefixes to your routes and activating the appropriate locale based on the prefix, and translating the routes themselves to provide a seamless multilingual experience. These mechanisms can be used independently or in combination.

## Requirements

The features described below require the correct locale to be automatically activated for each user when processing incoming requests. To achieve this, you must either use the [I18n middleware](../handlers-and-http/reference/middlewares.md#i18n-middleware) or implement your [own middleware](../handlers-and-http/middlewares.md#how-middlewares-work) that activates the appropriate locale based on a custom logic (eg. based on specific domains).

## Prefixing routes with locales

Prefixing routes with locales allows to activate specific locales based on the accessed route paths when the [I18n middleware](../handlers-and-http/reference/middlewares.md#i18n-middleware) is used.

Defining localized routes involves wrapping route path definitions by a call to the [`#localized`](pathname:///api/dev/Marten/Routing/Map.html#localized(prefix_default_locale%3Dtrue%2C%26)%3ANil-instance-method) method. When such routes are defined, the current locale will be automatically prepended to the path of the localized routes and the routes map will be able to resolve paths in a locale-aware manner.

For example:

```crystal
ARTICLE_ROUTES = Marten::Routing::Map.draw do
  path "", ArticlesHandler, name: "list"
  path "/create", ArticleCreateHandler, name: "create"
  path "/<pk:int>", ArticleDetailHandler, name: "detail"
  path "/<pk:int>/update", ArticleUpdateHandler, name: "update"
  path "/<pk:int>/delete", ArticleDeleteHandler, name: "delete"
end

Marten.routes.draw do
  localized do
    path "/landing", LandingPageHandler, name: "landing"
    path "/articles", ARTICLE_ROUTES, name: "articles"
  end
end
```

After defining these routes, Marten automatically appends the locale prefix to the paths of all routes included within the [`#localized`](pathname:///api/dev/Marten/Routing/Map.html#localized(prefix_default_locale%3Dtrue%2C%26)%3ANil-instance-method) method block.

```crystal
I18n.activate("en")
Marten.routes.reverse("landing")         # => "/en/landing"
Marten.routes.reverse("articles:create") # => "/en/articles/create"
```

:::tip
You can choose not to prefix routes for the [default locale](../development/reference/settings.md#default_locale). To achieve this, set the `prefix_default_locale` argument to `false` when defining the `#localized` block:

```crystal
Marten.routes.draw do
  localized(prefix_default_locale: false) do
    path "/landing", LandingPageHandler, name: "landing"
    path "/articles", ARTICLE_ROUTES, name: "articles"
  end
end
```
:::

:::warning
The `#localized` method can only be used within your root routes map, defined in your project's `config/routes.cr` file. Additionally, only one `#localized` block is allowed per project. Violating these requirements will result in a `Marten::Routing::Errors::InvalidRouteMap` exception being raised.
:::

## Translating route paths

You can translate the paths of your routes, whether or not they are prefixed with locales. To do this, it is possible to use the `#t` method instead of defining route paths as regular strings. This method takes a single argument: the translation key that should be used to dynamically determine the path of the considered route.

For example, let's consider the following [translation file](./introduction.md#defining-translations):

```yaml
en:
  routes:
    landing: "/landing"
    articles:
      list: ""
      create: "/create"
      detail: "/<pk:int>"
      update: "/<pk:int>/update"
      delete: "/<pk:int>/delete"
fr:
  routes:
    landing: "/accueil"
    articles:
      prefix: "/articles"
      list: ""
      create: "/creer"
      detail: "/<pk:int>"
      update: "/<pk:int>/mettre-a-jour"
      delete: "/<pk:int>/supprimer"
```

Considering these translations, we could define the following routes map:

```crystal
ARTICLE_ROUTES = Marten::Routing::Map.draw do
  path t("routes.articles.list"), ArticlesHandler, name: "list"
  path t("routes.articles.create"), ArticleCreateHandler, name: "create"
  path t("routes.articles.detail"), ArticleDetailHandler, name: "detail"
  path t("routes.articles.update"), ArticleUpdateHandler, name: "update"
  path t("routes.articles.delete"), ArticleDeleteHandler, name: "delete"
end

Marten.routes.draw do
  path t("routes.landing"), LandingPageHandler, name: "landing"
  path t("routes.articles.prefix"), ARTICLE_ROUTES, name: "articles"
end
```

After defining these routes, Marten will automatically resolve them using the right translations based on the current locale:

```crystal
I18n.activate("en")
Marten.routes.reverse("landing")         # => "/landing"
Marten.routes.reverse("articles:create") # => "/articles/create"

I18n.activate("fr")
Marten.routes.reverse("landing")         # => "/accueil"
Marten.routes.reverse("articles:create") # => "/articles/creer"
```

:::warning
To avoid potential collisions between translated and non-translated route paths, it is generally best to translate route paths while also [incorporating locale prefixes](#prefixing-routes-with-locales). This ensures a clear distinction between different locales and minimizes the risk of conflicts.
:::
