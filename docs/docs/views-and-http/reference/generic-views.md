---
title: Generic views
description: Generic views reference
---

This page provides a reference for all the available [generic views](../generic-views).

## Creating a record

**Class:** [`Marten::Views::RecordCreate`](pathname:///api/Marten/Views/RecordCreate.html)

View allowing to create a new model record by processing a schema.

This view can be used to process a form, validate its data through the use of a [schema](../../schemas), and create a record by using the validated data. It is expected that the view will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context in order to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the corresponding model record is created and the view returns an HTTP redirect to a configured success URL.

```crystal
class MyFormView < Marten::Views::RecordCreate
  model MyModel
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The model class used to create the new record can be configured through the use of the [`#model`](pathname:///api/Marten/Views/RecordCreate.html#model(model%3ADB%3A%3AModel.class%3F)-class-method) class method. The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/Marten/Views/Schema.html#schema(schema%3AMarten%3A%3ASchema.class%3F)-class-method) class method. Alternatively, the [`#schema_class`](pathname:///api/Marten/Views/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request view handling.

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/Marten/Views/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/Marten/Views/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/Marten/Views/Schema.html#success_url-instance-method) can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL to redirect to.

## Deleting a record

**Class:** [`Marten::Views::RecordDelete`](pathname:///api/Marten/Views/RecordDelete.html)

View allowing to delete a specific model record.

This view can be used to delete an existing model record by issuing a POST request. Optionally the view can be accessed with a GET request and a template can be displayed in this case; this allows to show a confirmation page to users before deleting the record:

```crystal
class ArticleDeleteView < Marten::Views::RecordDelete
  template_name "article_delete.html"
  success_route_name "article_delete_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render a deletion confirmation page while the [`#success_route_name`](pathname:///api/Marten/Views/RecordDelete.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the deletion is complete. Alternatively, the [`#sucess_url`](pathname:///api/Marten/Views/RecordDelete.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/Marten/Views/RecordDelete.html#success_url-instance-method) can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL to redirect to.

## Displaying a record

**Class:** [`Marten::Views::RecordDetail`](pathname:///api/Marten/Views/RecordDetail.html)

View allowing to display a specific model record.

This view can be used to retrieve a [model](../../models-and-databases/introduction) record, and to display it as part of a [rendered template](../../templates).

```crystal
class ArticleDetailView < Marten::Views::RecordDetail
  model Article
  template_name "articles/detail.html"
end
```

The model class used to retrieve the record can be configured through the use of the [`#model`](pathname:///api/Marten/Views/RecordDetail.html#model%3ADB%3A%3AModel.class%3F-class-method) class method. By default, a [`Marten::Views::RecordDetail`](pathname:///api/Marten/Views/RecordDetail.html) subclass will always retrieve model records by looking for a `pk` route parameter: this parameter is assumed to contain the value of the primary key field associated with the record that should be rendered. If you need to use a different route parameter name, you can also specify a different one through the use of the [`#lookup_param`](pathname:///api/Marten/Views/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method. Finally, the model field that is used to get the model record (defaulting to `pk`) can also be configured by leveraging the [`#lookup_param`](pathname:///api/Marten/Views/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method.

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render the considered model record. By default the model record is associated with a `record` key in the template context, but this can also be configured by using the [`record_context_name`](pathname:///api/Marten/Views/RecordDetail.html#record_context_name(name%3AString|Symbol)-class-method) class method.

## Listing records

**Class:** [`Marten::Views::RecordList`](pathname:///api/Marten/Views/RecordList.html)

View allowing to list model records.

This base view can be used to easily expose a list of model records:

```crystal
class MyView < Marten::Views::RecordList
  template_name = "my_template"
  model Post
end
```

The model class used to retrieve the records can be configured through the use of the [`#model`](pathname:///api/Marten/Views/RecordListing/ClassMethods.html#model(model%3ADB%3A%3AModel.class%3F)-instance-method) class method. The [order](../../models-and-databases/reference/query-set#order) of these model records can also be specified by leveraging the [`#ordering`](pathname:///api/Marten/Views/RecordListing/ClassMethods.html#page_number_param(param%3AString|Symbol)-instance-method) class method.

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render the list of model records. By default the list of model records is associated with a `records` key in the template context, but this can also be configured by using the [`list_context_name`](pathname:///api/Marten/Views/RecordList.html#list_context_name(name%3AString|Symbol)-class-method) class method.

Optionally, it is possible to configure that records should be [paginated](../../models-and-databases/reference/query-set#paginator) by specifying a page size through the use of the [`page_size`](pathname:///api/Marten/Views/RecordListing/ClassMethods.html#page_size(page_size%3AInt32%3F)-instance-method) class method:

```
class MyView < Marten::Views::RecordList
  template_name = "my_template"
  model Post
  page_size 12
end
```

When records are paginated, a [`Marten::DB::Query::Page`](pathname:///api/Marten/DB/Query/Page.html) object will be exposed in the template context (instead of the raw query set). It should be noted that the page number that should be displayed is determined by looking for a `page` GET parameter by default; this parameter name can be configured as well by calling the [`page_number_param`](pathname:///api/Marten/Views/RecordListing/ClassMethods.html#page_number_param(param%3AString|Symbol)-instance-method) class method.

## Updating a record

**Class:** [`Marten::Views::RecordUpdate`](pathname:///api/Marten/Views/RecordUpdate.html)

View allowing to update a model record by processing a schema.

This view can be used to process a form, validate its data through the use of a [schema](../../schemas), and update an existing record by using the validated data. It is expected that the view will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context in order to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the model record that was retrieved is updated and the view returns an HTTP redirect to a configured success URL.

```crystal
class MyFormView < Marten::Views::RecordUpdate
  model MyModel
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The model class used to update the new record can be configured through the use of the [`#model`](pathname:///api/Marten/Views/RecordRetrieving/ClassMethods.html#model(model%3ADB%3A%3AModel.class%3F)-instance-method) class method. By default, the record to update is retrieved by expecting a `pk` route parameter: this parameter is assumed to contain the value of the primary key field associated with the record that should be updated. If you need to use a different route parameter name, you can also specify a different one through the use of the [`#lookup_param`](pathname:///api/Marten/Views/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method. Finally, the model field that is used to get the model record (defaulting to `pk`) can also be configured by leveraging the [`#lookup_param`](pathname:///api/Marten/Views/RecordRetrieving/ClassMethods.html#lookup_param(lookup_param%3AString|Symbol)-instance-method) class method.

The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/Marten/Views/Schema.html#schema(schema%3AMarten%3A%3ASchema.class%3F)-class-method) class method. Alternatively, the [`#schema_class`](pathname:///api/Marten/Views/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request view handling.

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/Marten/Views/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/Marten/Views/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/Marten/Views/Schema.html#success_url-instance-method) can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL to redirect to.

## Performing a redirect

**Class:** [`Marten::Views::Redirect`](pathname:///api/Marten/Views/Redirect.html)

View allowing to conveniently return redirect responses.

This view can be used to generate a redirect response (temporary or permanent) to another location. To configure such location, you can either leverage the [`#route_name`](pathname:///api/Marten/Views/Redirect.html#route_name(route_name%3AString%3F)-class-method) class method (which expects a valid [route name](../routing#reverse-url-resolutions)) or the [`#url`](pathname:///api/Marten/Views/Redirect.html#url(url%3AString%3F)-class-method) class method. If you need to implement a custom redirection URL logic, you can also override the [`#redirect_url`](pathname:///api/Marten/Views/Redirect.html#redirect_url-instance-method) method.

```crystal
class TestRedirectView < Marten::Views::Redirect
  route_name "articles:list"
end
```

By default, the redirect returned by such view is a temporary one. In order to generate a permanent redirect response instead, it is possible to leverage the [`#permanent`](pathname:///api/Marten/Views/Redirect.html#permanent(permanent%3ABool)-class-method) class method.

It should also be noted that by default, incoming query string parameters **are not** forwarded to the redirection URL. If you wish to ensure that these parameters are forwarded, you can make use of the [`forward_query_string`](pathname:///api/Marten/Views/Redirect.html#forward_query_string(forward_query_string%3ABool)-class-method) class method.

## Processing a schema

**Class:** [`Marten::Views::Schema`](pathname:///api/Marten/Views/Schema.html)

View allowing to process a form through the use of a [schema](../../schemas).

This view can be used to process a form and validate its data through the use of a [schema](../../schemas). It is expected that the view will be accessed through a GET request first: when this happens the configured template is rendered and displayed, and the configured schema which is initialized can be accessed from the template context in order to render a form for example. When the form is submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the view returns an HTTP redirect to a configured success URL.

```crystal
class MyFormView < Marten::Views::Schema
  schema MyFormSchema
  template_name "my_form.html"
  success_route_name "my_form_success"
end
```

It should be noted that the redirect response issued will be a 302 (found).

The schema used to perform the validation can be defined through the use of the [`#schema`](pathname:///api/Marten/Views/Schema.html#schema(schema%3AMarten%3A%3ASchema.class%3F)-class-method) class method. Alternatively, the [`#schema_class`](pathname:///api/Marten/Views/Schema.html#schema_class-instance-method) method can also be overridden to dynamically define the schema class as part of the request view handling.

The [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method allows to define the name of the template to use to render the schema while the [`#success_route_name`](pathname:///api/Marten/Views/Schema.html#success_route_name(success_route_name%3AString%3F)-class-method) method can be used to specify the name of a route to redirect to once the schema has been validated. Alternatively, the [`#sucess_url`](pathname:///api/Marten/Views/Schema.html#success_url(success_url%3AString%3F)-class-method) class method can be used to provide a raw URL to redirect to. The [same method](pathname:///api/Marten/Views/Schema.html#success_url-instance-method) can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL to redirect to.

## Rendering a template

**Class:** [`Marten::Views::Template`](pathname:///api/Marten/Views/Template.html)

View allowing to respond to `GET` request with the content of a rendered HTML [template](../../templates).

This view can be used to render a specific template, and returns the resulting content in the response. The template being rendered can be specified by leveraging the [`#template_name`](pathname:///api/Marten/Views/Rendering/ClassMethods.html#template_name(template_name%3AString%3F)-instance-method) class method.

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
