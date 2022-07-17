---
title: Generic views
description: Learn how to leverage generic views to perform common tasks.
sidebar_label: Generic views
---

Marten includes a set of generic views that can be leveraged to perform common tasks. These tasks are frequently encountered when working on web applications. For example: displaying a list of records extracted from the database, or deleting a record. Generic views take care of these common patterns so that developers don't end up reimplementing the wheel.

## Scope

Marten provides generic views allowing to perform the following actions:

* redirect to a specific URL
* render an existing [template](../templates)
* process a [schema](../schemas)
* list, display, create, update, or delete [model records](../models-and-databases)

A few of these generic views are described below (and all of them are listed in the [dedicated reference](./reference/generic-views)). Each of these view classes must be subclassed on a per project basis to define the required "attributes", and optionally to override methods to customize things like objects exposed in template contexts. By doing so you are essentially defining views that inherit these common patterns, without having to reimplement them.

Finally it should be noted that using generic views is totally optional. They provide a good starting point in order to implement frequently encountered use cases, but you can decide to design your own set of generic views to accommodate for your project needs if the built-in ones don't match your requirements.

## A few examples

### Performing a redirect

Having a view that performs a redirect can be easily achieved by subclassing the [`Marten::Views::Redirect`](pathname:///api/Marten/Views/Redirect.html) generic view. For example you could easily define a view that redirects to an `articles:list` route with the following snippet:

```crystal
class ArticlesRedirectView < Marten::Views::Redirect
  route_name "articles:list"
end
```

The above view will perform a reverse resolution of `articles:list` in order to get the corresponding URL and will return a 302 HTTP response (temporary redirect).

Subclasses of this generic view can also redirect to a plain URL and decide to return a permanent redirect (301) instead of a temporary one, for example:

```crystal
class TestRedirectView < Marten::Views::Redirect
  url "https://example.com"
  permanent true
end
```

Finally you can even implement your own logic in order to compute the redirection URL by overridding the `#redirect_url` method:

```crystal
class ArticleRedirectView < Marten::Views::Redirect
  def redirect_url
    article = Article.get(id: params["pk"])
    if article.published?
      reverse("articles:detail", pk: article.id)
    else
      reverse("articles:list")
    end
  end
end
```

### Rendering a template

One of the most frequent things you will want to do when writing views is to return HTML responses containing rendered [templates](../templates). To do so, you can obviously define a regular view and make use of the [`#render`](./introduction#render) helper. But, you may also want to leverage the [`Marten::Views::Template`](pathname:///api/Marten/Views/Template.html) generic view.

This generic views will return a 200 OK HTTP response containing a rendered HTML template. To make use of it, you can simply define a subclass of it and ensure that you call the `#template_name` class method in order to define the template that will be rendered:

```crystal
class HomeView < Marten::Views::Template
  template_name "app/home.html"
end
```

If you need to, it is possible to customize the context that is used to render the configured template. To do so, you can define a `#context` method that returns a hash or a named tuple with the values you want to make available to your template:

```crystal
class HomeView < Marten::Views::Template
  template_name "app/home.html"

  def context
    { "recent_articles" => Article.all.order("-published_at")[:5] }
  end
end
```

### Displaying a model record

It is possible to render a template that showcases a specific model record by leveraging the [`Marten::Views::RecordDetail`](pathname:///api/Marten/Views/RecordDetail.html) generic view.

For example, it would be possible to render an `articles/detail.html` template showcasing a specific `Article` model record with the following view:

```crystal
class ArticleDetailView < Marten::Views::RecordDetail
  model Article
  template_name "articles/detail.html"
end
```

By assuming that the route path associated with this view is something like `/articles/<pk:int>`, this view will automatically retrieve the right `Article` record by using the primary key provided in the `pk` route parameter. If the record does not exist, a `Marten::HTTP::Errors::NotFound` exceptions will be raised (which will lead to the default "not found" error page to be displayed to the user), and otherwise the configured template will be rendered (with the `Article` record exposed in the context under the `record` key).

For example, the template associated with this view could be something like:

```html
<ul>
  <li>Title: {{ record.title }}</li>
  <li>Created at: {{ record.created_at }}</li>
</ul>
```

### Processing a form

It is possible to use the [`Marten::Views::Schema`](pathname:///api/Marten/Views/Schema.html) generic view in order to process form data with a [schema](../schemas).

To do so, it is necessary:

* to specify the schema class to use to validate the incoming POST data through the use of the `#schema` class method
* to specify the template to render by using the `#template_name` class method: this template will likely generate an HTML form 
* to specify the route to redirect to when the schema is valid via the `#success_route_name` class method

For example:

```crystal
class MyFormView < Marten::Views::Schema
  schema MySchema
  template_name "app/my_form.html"
  success_route_name "home"

  def process_valid_schema
    # This method is called when the schema is valid.
    # You can decide to do something with the validated data...
    super
  end

  def process_invalid_schema
    # This method is called when the schema is invalid.
    super
  end
end
```

By default, such view will render the configured template when the incoming request is a GET or for POST requests if the data cannot be validated using the specified schema (in that case, the template is expected to use the invalid schema to display a form with the right errored inputs). The specified template can have access to the configured schema through the use of the `schema` object in the template context.

If the schema is valid, a temporary redirect is issued by using the URL corresponding to the `#success_route_name` value (although it should be noted that the way to generate this success URL can be overridden by defining a `#success_url` method). By default, the view does nothing when the processed schema is valid (except redirecting to the success URL). That's why it can be helpful to override the `#process_valid_schema` method to implement any logic that should be triggered after a successful schema validation.
