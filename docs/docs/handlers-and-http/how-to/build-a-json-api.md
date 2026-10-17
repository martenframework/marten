---
title: Build a JSON API
sidebar_label: Build a JSON API
description: How to build a JSON API.
---

This guide covers how to add JSON endpoints for the `Article` model introduced in the [tutorial](../../getting-started/tutorial.md). These endpoints make it possible to list, retrieve, create, update, and delete articles by leveraging regular [handlers](../introduction.md), [schemas](../../schemas/introduction.md), and the [`#json`](../introduction.md#json) helper.

It should be noted that generic handlers such as [`Marten::Handlers::RecordCreate`](../reference/generic-handlers.md#creating-a-record) render a template and redirect once a schema is valid. The endpoints below return JSON responses, which is why they inherit from [`Marten::Handler`](../introduction.md#writing-handlers) directly. The schema validates the incoming payload, and the handler decides which fields are included in the response.

## Requirements

The examples below assume that you already created the `Article` model and the `ArticleSchema` schema from the tutorial:

```crystal title="src/models/article.cr"
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
end
```

```crystal title="src/schemas/article_schema.cr"
class ArticleSchema < Marten::Schema
  field :title, :string, max_size: 255
  field :content, :string
end
```

Handlers defined under `src/handlers/` are automatically required by projects that were generated through the [`new`](../../development/reference/management-commands.md#new) management command (`require "./handlers/**"` in `src/project.cr`).

Finally, it should be noted that one route maps to one handler. As such, the HTTP methods that share a URL are implemented as methods of the same handler class. Listing and creating articles share `GET` and `POST` on `/api/articles`, while retrieving, updating, and deleting an article share `GET`, `PUT`, and `DELETE` on `/api/articles/<pk>`.

## Listing and creating articles

In order to list existing articles and to create new ones, let's create a `src/handlers/api/articles_handler.cr` file with the following content:

```crystal title="src/handlers/api/articles_handler.cr"
class API::ArticlesHandler < Marten::Handler
  def get
    articles = Article.all.map { |article| article_json(article) }

    json({articles: articles})
  end

  def post
    schema = ArticleSchema.new(request.data)

    if schema.valid?
      article = Article.new(schema.validated_data)
      article.save!

      json(article_json(article), status: 201)
    else
      json({errors: schema.errors}, status: 422)
    end
  end

  private def article_json(article : Article)
    {id: article.id, title: article.title, content: article.content}
  end
end
```

This handler is able to handle both GET and POST requests:

* when the incoming request is a GET, it loads every `Article` record and returns a JSON object containing the `id`, `title`, and `content` of each article
* when the incoming request is a POST, it initializes an `ArticleSchema` schema with the data currently present in the request object (which is returned by the [`#data`](pathname:///api/dev/Marten/HTTP/Request.html#data%3AParams%3A%3AData-instance-method) method). This data is automatically initialized from a JSON object when the `Content-Type` of the request is `application/json`. If the schema is valid, a new `Article` record is created using the schema's validated data and returned with a `201` status code. Otherwise, the schema errors are returned with a `422` status code

For example, submitting a payload without a title produces a response like the following one:

```json
{
  "errors": [
    {"field": "title", "type": "required", "message": "This field is required."}
  ]
}
```

It should be noted that the `field` attribute is `null` when the error is global. Model validation errors use the same representation, which means that `article.errors` can be passed to `#json` in the same way. Please refer to [Serializing errors as JSON](../../schemas/validations.md#serializing-errors-as-json) to learn more about this.

## Retrieving, updating, and deleting an article

Let's now add the ability to retrieve, update, and delete a specific article. In this light, let's create a `src/handlers/api/article_handler.cr` file with the following content:

```crystal title="src/handlers/api/article_handler.cr"
class API::ArticleHandler < Marten::Handler
  @article : Article?

  def get
    json(article_json(article))
  end

  def put
    schema = ArticleSchema.new(request.data)

    if schema.valid?
      article.update!(schema.validated_data)
      json(article_json(article))
    else
      json({errors: schema.errors}, status: 422)
    end
  end

  def delete
    article.delete
    head :no_content
  end

  private def article
    @article ||= Article.get!(id: params["pk"])
  rescue Marten::DB::Errors::RecordNotFound
    raise Marten::HTTP::Errors::NotFound.new("Article not found")
  end

  private def article_json(article : Article)
    {id: article.id, title: article.title, content: article.content}
  end
end
```

This handler is able to handle GET, PUT, and DELETE requests:

* when the incoming request is a GET, it retrieves the `Article` record identified by the `pk` route parameter and returns it as JSON
* when the incoming request is a PUT, it validates the incoming JSON payload with the same `ArticleSchema` schema. If the schema is valid, the record is updated using the schema's validated data. Otherwise, the schema errors are returned with a `422` status code
* when the incoming request is a DELETE, it deletes the record and returns an empty response with a `204` status code by leveraging the [`#head`](../introduction.md#head) helper

In the above snippet, the `#article` method fetches the `Article` record by using the `pk` parameter value. If no record matches this primary key, a `Marten::DB::Errors::RecordNotFound` exception is rescued and a 404 Not Found response is returned. This is the same approach as the one used in the tutorial.

## Mapping the handlers to routes

We can now map these handlers to proper routes. We can do this by editing the `config/routes.cr` file as follows:

```crystal title="config/routes.cr"
Marten.routes.draw do
  path "/", HomeHandler, name: "home"
  path "/article/create", ArticleCreateHandler, name: "article_create"
  path "/article/<pk:int>", ArticleDetailHandler, name: "article_detail"
  path "/article/<pk:int>/update", ArticleUpdateHandler, name: "article_update"
  path "/article/<pk:int>/delete", ArticleDeleteHandler, name: "article_delete"
  // highlight-next-line
  path "/api/articles", API::ArticlesHandler, name: "api_articles"
  // highlight-next-line
  path "/api/articles/<pk:int>", API::ArticleHandler, name: "api_article"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

## Cross-Site Request Forgery protection

The CSRF protection is enabled for these handlers, which is the default. A browser that submits an unsafe request (`POST`, `PUT`, or `DELETE`) and that sends the session cookie must include the CSRF token in the `X-CSRF-Token` header. Please refer to [Using the CSRF protection with AJAX](../../security/csrf.md#using-the-csrf-protection-with-ajax) to learn more about how to retrieve this token and how to forward it.

A client that does not rely on the session cookie (for example another server) can disable the CSRF protection on a per-handler basis. This can be achieved through the use of the [`#protect_from_forgery`](pathname:///api/dev/Marten/Handlers/RequestForgeryProtection/ClassMethods.html#protect_from_forgery(protect%3ABool)%3ANil-instance-method) class method:

```crystal
class API::ArticlesHandler < Marten::Handler
  protect_from_forgery false

  # [...]
end
```

The same setting must be applied to `API::ArticleHandler` as well.

## Trying the endpoints

You can now interact with these endpoints. For example, in order to list the available articles, you can run the following command:

```shell
curl http://localhost:8000/api/articles
```

In order to create a new article, you can run the following command:

```shell
curl http://localhost:8000/api/articles \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'X-CSRF-Token: <token>' \
  --data '{"title":"Hello","content":"First article"}'
```

:::info
The `Content-Type` header must be set to `application/json`. Otherwise the request body is not made available through the `#data` method.
:::

The above request returns a `201` response like the following one:

```json
{"id": 1, "title": "Hello", "content": "First article"}
```

Retrieving, updating, and deleting this article can be achieved by running the following commands:

```shell
curl http://localhost:8000/api/articles/1

curl http://localhost:8000/api/articles/1 \
  --request PUT \
  --header 'Content-Type: application/json' \
  --header 'X-CSRF-Token: <token>' \
  --data '{"title":"Hello","content":"Updated article"}'

curl http://localhost:8000/api/articles/1 \
  --request DELETE \
  --header 'X-CSRF-Token: <token>'
```

:::tip
The `X-CSRF-Token` header can be omitted when the considered handlers explicitly disable the CSRF protection.
:::
