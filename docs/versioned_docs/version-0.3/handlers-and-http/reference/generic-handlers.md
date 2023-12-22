---
title: Generic handlers
description: Generic handlers reference
---

This page provides a reference for all the available [generic handlers](../generic-handlers.md).

## Creating a record

**Class:** [`Marten::Handlers::RecordCreate`](pathname:///api/0.3/Marten/Handlers/RecordCreate.html)

Handler allowing to create a new model record by processing a schema.

This handler can be used to process a form, validate its data through the use of a [schema](../../schemas.mdx), and create a record by using the validated data. It is expected that the handler will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context in order to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the corresponding model record is created and the handler returns an HTTP redirect to a configured success URL.

```crystal
class MyFormHandler < Marten::Handlers::RecordCreate
  model MyModel
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The model class used to create the new record can be configured through the use of the [`#model`](pathname:///api/0.3/Marten/Handlers/RecordCreate.html#model(model_klass)-macro) macro. The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema(schema_klass)-macro) macro. Alternatively, the [`#schema_class`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request handler handling.

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url-instance-method) can also be overridden at the instance level to rely on a custom logic to generate the success URL to redirect to.

## Deleting a record

**Class:** [`Marten::Handlers::RecordDelete`](pathname:///api/0.3/Marten/Handlers/RecordDelete.html)

Handler allowing to delete a specific model record.

This handler can be used to delete an existing model record by issuing a POST request. Optionally the handler can be accessed with a GET request and a template can be displayed in this case; this allows to display a confirmation page to users before deleting the record:

```crystal
class ArticleDeleteHandler < Marten::Handlers::RecordDelete
  model MyModel
  template_name "article_delete.html"
  success_route_name "article_delete_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render a deletion confirmation page while the [`#success_route_name`](pathname:///api/0.3/Marten/Handlers/RecordDelete.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the deletion is complete. Alternatively, the [`#sucess_url`](pathname:///api/0.3/Marten/Handlers/RecordDelete.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/0.3/Marten/Handlers/RecordDelete.html#success_url-instance-method) can also be overridden at the instance level to rely on a custom logic to generate the success URL to redirect to.

## Displaying a record

**Class:** [`Marten::Handlers::RecordDetail`](pathname:///api/0.3/Marten/Handlers/RecordDetail.html)

Handler allowing to display a specific model record.

This handler can be used to retrieve a [model](../../models-and-databases/introduction.md) record, and to display it as part of a [rendered template](../../templates.mdx).

```crystal
class ArticleDetailHandler < Marten::Handlers::RecordDetail
  model Article
  template_name "articles/detail.html"
end
```

The model class used to retrieve the record can be configured through the use of the [`#model`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving.html#model(model_klass)-macro) macro. By default, a [`Marten::Handlers::RecordDetail`](pathname:///api/0.3/Marten/Handlers/RecordDetail.html) subclass will always retrieve model records by looking for a `pk` route parameter: this parameter is assumed to contain the value of the primary key field associated with the record that should be rendered. If you need to use a different route parameter name, you can also specify a different one through the use of the [`#lookup_param`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method. Finally, the model field that is used to get the model record (defaulting to `pk`) can also be configured by leveraging the [`#lookup_param`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method.

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render the considered model record. By default, the model record is associated with a `record` key in the template context, but this can also be configured by using the [`record_context_name`](pathname:///api/0.3/Marten/Handlers/RecordDetail.html#record_context_name(name%3AString|Symbol)-class-method) class method.

## Listing records

**Class:** [`Marten::Handlers::RecordList`](pathname:///api/0.3/Marten/Handlers/RecordList.html)

Handler allowing to list model records.

This base handler can be used to easily expose a list of model records:

```crystal
class MyHandler < Marten::Handlers::RecordList
  template_name "my_template"
  model Post
end
```

The model class used to retrieve the records can be configured through the use of the [`#model`](pathname:///api/0.3/Marten/Handlers/RecordListing.html#model(model_klass)-macro) macro. The [order](../../models-and-databases/reference/query-set.md#order) of these model records can also be specified by leveraging the [`#ordering`](pathname:///api/0.3/Marten/Handlers/RecordListing/ClassMethods.html#page_number_param(param%3AString|Symbol)-instance-method) class method.

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render the list of model records. By default, the list of model records is associated with a `records` key in the template context, but this can also be configured by using the [`list_context_name`](pathname:///api/0.3/Marten/Handlers/RecordList.html#list_context_name(name%3AString|Symbol)-class-method) class method.

Optionally, it is possible to configure that records should be [paginated](../../models-and-databases/reference/query-set.md#paginator) by specifying a page size through the use of the [`page_size`](pathname:///api/0.3/Marten/Handlers/RecordListing/ClassMethods.html#page_size(page_size%3AInt32%3F)-instance-method) class method:

```crystal
class MyHandler < Marten::Handlers::RecordList
  template_name "my_template"
  model Post
  page_size 12
end
```

When records are paginated, a [`Marten::DB::Query::Page`](pathname:///api/0.3/Marten/DB/Query/Page.html) object will be exposed in the template context (instead of the raw query set). It should be noted that the page number that should be displayed is determined by looking for a `page` GET parameter by default; this parameter name can be configured as well by calling the [`page_number_param`](pathname:///api/0.3/Marten/Handlers/RecordListing/ClassMethods.html#page_number_param(param%3AString|Symbol)-instance-method) class method.

:::tip How to customize the query set?
By default, handlers that inherit from [`Marten::Handlers::RecordList`](pathname:///api/0.3/Marten/Handlers/RecordList.html) will use a query set targetting _all_ the records of the specified model. It should be noted that you can customize this behavior easily by leveraging the [`#queryset`](pathname:///api/0.3/Marten/Handlers/RecordListing.html#queryset(queryset)-macro) macro instead of the [`#model`](pathname:///api/0.3/Marten/Handlers/RecordListing.html#model(model_klass)-macro) macro. For example:

```crystal
class MyHandler < Marten::Handlers::RecordList
  template_name "my_template"
  queryset Article.filter(user: request.user)
end
```

Alternatively, it is also possible to override the [`#queryset`](pathname:///api/0.3/Marten/Handlers/RecordListing.html#queryset-instance-method) method and apply additional filters to the default query set:

```crystal
class MyHandler < Marten::Handlers::RecordList
  template_name "my_template"
  model Article

  def queryset
    super.filter(user: request.user)
  end
end
```
:::

## Updating a record

**Class:** [`Marten::Handlers::RecordUpdate`](pathname:///api/0.3/Marten/Handlers/RecordUpdate.html)

Handler allowing to update a model record by processing a schema.

This handler can be used to process a form, validate its data through the use of a [schema](../../schemas.mdx), and update an existing record by using the validated data. It is expected that the handler will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the model record that was retrieved is updated and the handler returns an HTTP redirect to a configured success URL.

```crystal
class MyFormHandler < Marten::Handlers::RecordUpdate
  model MyModel
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The model class used to update the new record can be configured through the use of the [`#model`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving.html#model(model_klass)-macro) macro. By default, the record to update is retrieved by expecting a `pk` route parameter: this parameter is assumed to contain the value of the primary key field associated with the record that should be updated. If you need to use a different route parameter name, you can also specify a different one through the use of the [`#lookup_param`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method. Finally, the model field that is used to get the model record (defaulting to `pk`) can also be configured by leveraging the [`#lookup_param`](pathname:///api/0.3/Marten/Handlers/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method.

The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema(schema_klass)-macro) macro. Alternatively, the [`#schema_class`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request handler handling.

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url-instance-method) can also be overridden at the instance level to rely on a custom logic to generate the success URL to redirect to.

## Performing a redirect

**Class:** [`Marten::Handlers::Redirect`](pathname:///api/0.3/Marten/Handlers/Redirect.html)

Handler allowing to conveniently return redirect responses.

This handler can be used to generate a redirect response (temporary or permanent) to another location. To configure such a location, you can either leverage the [`#route_name`](pathname:///api/0.3/Marten/Handlers/Redirect.html#route_name(route_name%3AString%3F)-class-method) class method (which expects a valid [route name](../routing.md#reverse-url-resolutions)) or the [`#url`](pathname:///api/0.3/Marten/Handlers/Redirect.html#url(url%3AString%3F)-class-method) class method. If you need to implement a custom redirection URL logic, you can also override the [`#redirect_url`](pathname:///api/0.3/Marten/Handlers/Redirect.html#redirect_url-instance-method) method.

```crystal
class TestRedirectHandler < Marten::Handlers::Redirect
  route_name "articles:list"
end
```

By default, the redirect returned by this handler is a temporary one. In order to generate a permanent redirect response instead, it is possible to leverage the [`#permanent`](pathname:///api/0.3/Marten/Handlers/Redirect.html#permanent(permanent%3ABool)-class-method) class method.

It should also be noted that by default, incoming query string parameters **are not** forwarded to the redirection URL. If you wish to ensure that these parameters are forwarded, you can make use of the [`forward_query_string`](pathname:///api/0.3/Marten/Handlers/Redirect.html#forward_query_string(forward_query_string%3ABool)-class-method) class method.

## Processing a schema

**Class:** [`Marten::Handlers::Schema`](pathname:///api/0.3/Marten/Handlers/Schema.html)

Handler allowing to process a form through the use of a [schema](../../schemas.mdx).

This handler can be used to process a form and validate its data through the use of a [schema](../../schemas.mdx). It is expected that the handler will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the handler returns an HTTP redirect to a configured success URL.

```crystal
class MyFormHandler < Marten::Handlers::Schema
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema(schema_klass)-macro) macro. Alternatively, the [`#schema_class`](pathname:///api/0.3/Marten/Handlers/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request handler handling.

The [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows defining the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/0.3/Marten/Handlers/Schema.html#success_url-instance-method) can also be overridden at the instance level to rely on a custom logic to generate the success URL to redirect to.

## Rendering a template

**Class:** [`Marten::Handlers::Template`](pathname:///api/0.3/Marten/Handlers/Template.html)

Handler allowing to respond to `GET` request with the content of a rendered HTML [template](../../templates.mdx).

This handler can be used to render a specific template and returns the resulting content in the response. The template being rendered can be specified by leveraging the [`#template_name`](pathname:///api/0.3/Marten/Handlers/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method.

```crystal
class HomeHandler < Marten::Handlers::Template
  template_name "app/home.html"
end
```

If you need to, it is possible to customize the context that is used to render the configured template. To do so, you can define a `#context` method that returns a hash or a named tuple with the values you want to make available to your template:

```crystal
class HomeHandler < Marten::Handlers::Template
  template_name "app/home.html"

  def context
    { "recent_articles" => Article.all.order("-published_at")[:5] }
  end
end
```
