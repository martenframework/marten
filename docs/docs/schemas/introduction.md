---
title: Introduction to schemas
description: Learn how to define schemas and use them in handlers.
sidebar_label: Introduction
---

Schemas are classes that define how input data should be serialized/deserialized, and validated. Schemas are usually used when processing web requests containing form data or pre-defined payloads.

## Basic schema definition and usage

### The schema class

A schema class describes an _expected_ set of data. It describes the logical structure of this data, what are its expected characteristics, and what are the rules to use in order to identify whether it is valid or not. Schemas classes must inherit from the [`Marten::Schema`](pathname:///api/dev/Marten/Schema.html) base class and they must define "fields" through the use of a `field` macro. These fields allow to define what data is expected by the schema, and how it is validated.

For example, the following snippet defines a simple `ArticleSchema` schema:

```crystal
class ArticleSchema < Marten::Schema
  field :title, :string, max_size: 128
  field :content, :string
  field :published_at, :date_time, required: false
end
```

In the above example, `title`, `content`, and `published_at` are fields of the `ArticleSchema` schema. This schema is very simple, but it already defines a set of validation rules that could be used to validate any data set the schema is applied to:

* the `title` field is required, it must be a string that do not exceed 128 characters
* the `content` field is required and must be a string as well
* the `published_at` field is a date time that is _not_ required

### Using schemas

Schemas can theoretically be used to process any kind of data, including a request's data. This makes them ideal when it comes to processing form inputs data or JSON payloads for example.

When used as part of [handlers](../handlers-and-http/introduction.md), and especially when processing HTML forms, schemas will usually be initialized and used to render a form when `GET` requests are submitted to the considered handler. Processing the actual form data will usually be done in the same handler when `POST` requests are submitted.

For example, the handler in the following snippets displays a schema when a `GET` request is processed, and it validates the incoming data using the schema when the request is a `POST`:

```crystal
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

Let's break it down a bit more:

* when the incoming request is a `GET`, the handler will simply render the `article_create.html` template, and initialize the schema (instance of `ArticleSchema`) with any data currently present in the request object (which is returned by the `#request` method). This schema object is made available to the template context
* when the incoming request is a `POST`, it will initialize the schema and try to see if it is valid considering the incoming data (using the [`#valid?`](pathname:///api/dev/Marten/Core/Validation.html#valid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) method). If it's valid, then a new `Article` record will be created using the schema's validated data ([`#validated_data`](pathname:///api/dev/Marten/Schema.html#validated_data%3AHash(String%2CBool|Float64|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Time|Time%3A%3ASpan|UUID|Nil)-instance-method)), and the user will be redirect to a home page. Otherwise, the `article_create.html` template will be rendered again with the invalid schema in the associated context

It should be noted that templates can easily interact with schema objects in order to introspect them and render a corresponding HTML form. In the above example, the schema could be used as follows to render an equivalent form in the `article_create.html` template:

```html
<form method="post" action="" novalidate>
  <input type="hidden" name="csrftoken" value="{% csrf_token %}" />

  <fieldset>
    <div><label>Title</label></div>
    <input type="text" name="{{ schema.title.id }}" value="{{ schema.title.value }}"/>
    {% for error in schema.title.errors %}<p><small>{{ error.message }}</small></p>{% endfor %}
  </fieldset>

  <fieldset>
    <div><label>Content</label></div>
    <textarea name="{{ schema.content.id }}" value="{{ schema.content.value }}">{{ schema.content.value }}</textarea>
    {% for error in schema.content.errors %}<p><small>{{ error.message }}</small></p>{% endfor %}
  </fieldset>

  <fieldset>
    <div><label>Published at</label></div>
    <input type="text" name="{{ schema.published_at.id }}" value="{{ schema.published_at.value }}"/>
    {% for error in schema.published_at.errors %}<p><small>{{ error.message }}</small></p>{% endfor %}
  </fieldset>

  <fieldset>
    <button>Submit</button>
  </fieldset>
</form>
```

:::tip
Some [generic handlers](../handlers-and-http/generic-handlers.md) allow to conveniently process schemas in handlers. This is the case for the [`Marten::Handlers::Schema`](../handlers-and-http/reference/generic-handlers.md#processing-a-schema), the [`Marten::Handlers::RecordCreate`](../handlers-and-http/reference/generic-handlers.md#creating-a-record), and the [`Marten::Handlers::RecordUpdate`](../handlers-and-http/reference/generic-handlers.md#updating-a-record) generic handlers for example.
:::

Note that schemas can be used for other things than processing form data. For example, they can also be used to process JSON payloads as part of API endpoints:

```crystal
class API::ArticleCreateHandler < Marten::Handler
  def post
    schema = ArticleCreateHandler.new(request.data)
    
    if schema.valid?
      article = Article.new(schema.validated_data)
      article.save!

      created = true
    else
      created = false
    end

    json({created: created})
  end
end
```

:::info
The `#data` method of an HTTP request object returns a hash-like object containing the request data: this object is automatically initialized from any form data or JSON data contained in the request body.
:::

## Schema fields

Schema classes must define _fields_. Fields allow to specify the expected attributes of a schema and they indicate how to validate incoming data sets. They are defined through the use of the `field` macro.

For example:

```crystal
class ArticleSchema < Marten::Schema
  field :title, :string, max_size: 128
  field :content, :string
  field :published_at, :date_time, required: false
end
```

### Field ID and field type

Pretty much like model fields, every field in a schema class must contain two mandatory positional arguments: a field identifier and a field type.

The field identifier is used by Marten to determine the name of the corresponding key in any data set objects that should be validated by the schema.

The field type determines a few other things:

* the type of the expected value in the validated data set
* how the field is serialized and deserialized
* how field values are actually validated

Marten provides numerous built-in schema field types that cover common web development needs. The complete list of supported fields is covered in the [schema fields reference](./reference/fields.md).

:::note
It is possible to write custom schema fields and to use them in your schema definitions. See [How to create custom schema fields](./how-to/create-custom-schema-fields.md) for more details regarding this capability.
:::

### Common field options

In addition to their identifiers and types, fields can take keyword arguments that allow to further configure their behaviours and how they are validated. These keyword arguments are optional and they are shared across all the available fields.

#### `required`

The `required` argument allows to define whether a field is mandatory or not. The default value for this argument is `true`.

The presence of mandatory fields is automatically enforced by schemas: if a mandatory field is missing in a data set, then a corresponding error will be generated by the schema.

## Validations

One of the key characteristics of schemas is that they allow you to validate any incoming data and request parameters. As mentioned previously, the rules that are used to perform this validation can be inherited from the fields in your schema, depending on the options you used (for example fields using `required: true` will make the associated data validation fail if the field value is not present). They can also be explicitly specified in your schema class, which is useful if you need to implement custom validation logics.

For example:

```crystal
class SignUpSchema < Marten::Schema
  field :email, :string, max_size: 254
  field :password1, :string, max_size: 128, strip: false
  field :password2, :string, max_size: 128, strip: false

  validate :validate_password

  def validate_password
    return unless validated_data["password1"]? && validated_data["password2"]?

    if validated_data["password1"] != validated_data["password2"]
      errors.add("The two password fields do not match")
    end
  end
end
```

Schema validations are always triggered by the use of the [`#valid?`](pathname:///api/dev/Marten/Core/Validation.html#valid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) or [`#invalid?`](pathname:///api/dev/Marten/Core/Validation.html#invalid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) methods: these methods return `true` or `false` depending on whether the data is valid or invalid.

Please head over to the [Schema validations](./validations.md) guide in order to learn more about schema validations and how to customize it.

## Accessing validated data

After performing [schema validations](#validations) (ie. after calling [`#valid?`](pathname:///api/dev/Marten/Core/Validation.html#valid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) or [`#invalid?`](pathname:///api/dev/Marten/Core/Validation.html#invalid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) on a schema object), accessing the validated data is often necessary. For instance, you may need to persist the validated data as part of a model record. To achieve this, you can make use of the [`#validated_data`](pathname:///api/dev/Marten/Schema.html#validated_data%3AHash(String%2CBool|Float64|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Time|Time%3A%3ASpan|UUID|Nil)-instance-method) method, which is accessible in all schema instances.

This method provides access to a hash that contains the deserialized and validated field values of the schema. For instance, let's consider the example of the `ArticleSchema` schema [mentioned earlier](#the-schema-class):

```crystal
schema = ArticleSchema.new(Marten::Schema::DataHash{"title" => "Test article", "content" => "Test content"})
schema.valid? # => true

schema.validated_data["title"]   # => "Test article"
schema.validated_data["content"] # => "Test content"
```

It is important to note that accessing values using [`#validated_data`](pathname:///api/dev/Marten/Schema.html#validated_data%3AHash(String%2CBool|Float64|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Time|Time%3A%3ASpan|UUID|Nil)-instance-method) as shown in the above example is not type-safe. The [`#validated_data`](pathname:///api/dev/Marten/Schema.html#validated_data%3AHash(String%2CBool|Float64|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Time|Time%3A%3ASpan|UUID|Nil)-instance-method) hash can return any supported schema field values, and as a result, you may need to utilize the [`#as`](https://crystal-lang.org/reference/syntax_and_semantics/as.html) pseudo-method to handle the fetched validated data appropriately, depending on how and where you intend to use it.

To palliate this, Marten automatically defines type-safe methods that you can utilize to access your validated schema field values:

* `#<field>` returns a nillable version of the `<field>` field value
* `#<field>!` returns a non-nillable version of the `<field>` field value
* `#<field>?` returns a boolean indicating if the `<field>` field has a value

For example:

```crystal
schema = ArticleSchema.new(Marten::Schema::DataHash{"title" => "Test article"})
schema.valid? # => true

schema.title    # => "Test article"
schema.title!   # => "Test article"
schema.title?   # => true

schema.content  # => nil
schema.content! # => raises NilAssertionError
schema.content? # => false
```

## Callbacks

It is possible to define callbacks in your schema in order to bind methods and logics to specific events in the life cycle of your schema objects. Presently, schemas support callbacks related to validation only: `before_validation` and `after_validation`

`before_validation` callbacks are called before running validation rules for a given schema while `after_validation` callbacks are executed after. They can be used to alter the validated data once the validation is done for example.

```crystal
class ArticleSchema < Marten::Schema
  field :title, :string, max_size: 128
  field :content, :string
  field :published_at, :date_time, required: false

  before_validation :run_pre_validation_logic
  after_validation :run_post_validation_logic

  private def run_pre_validation_logic
    # Do something before the validation
  end

  private def run_post_validation_logic
    # Do something after the validation
  end
end
```

The use of methods like [`#valid?`](pathname:///api/dev/Marten/Core/Validation.html#valid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) or [`#invalid?`](pathname:///api/dev/Marten/Core/Validation.html#invalid%3F(context%3ANil|String|Symbol%3Dnil)-instance-method) will trigger validation callbacks. See [Schema validations](./validations.md) for more details.
