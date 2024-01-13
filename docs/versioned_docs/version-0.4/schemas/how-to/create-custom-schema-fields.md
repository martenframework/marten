---
title: Create custom schema fields
description: How to create custom schema fields.
---

Marten gives you the ability to create your own custom schema field implementations. Those can involve custom validations, behaviors, and errors. You can leverage these custom fields as part of your project's schema definitions, and you can even distribute them to let other projects use them.

## Schema fields: scope and responsibilities

Schema fields have the following responsibilities:

* they define how field values are deserialized and serialized
* they define how these values are validated

When creating a custom schema field, there are usually two approaches that you can consider depending on the amount of customization that you want to implement. You can either:

* leverage an existing built-in schema field (eg. integer, string, etc) and add custom behaviors and validations to it
* or create a new schema field from scratch

## Registering new schema fields

Regardless of the approach you take in order to define new schema field classes ([subclassing built-in fields](#subclassing-existing-schema-fields), or [creating new ones from scratch](#creating-new-schema-fields-from-scratch)), these classes must be registered to the Marten's global fields registry in order to make them available for use when defining schemas.

To do so, you will have to call the [`Marten::Schema::Field#register`](pathname:///api/0.4/Marten/Schema/Field.html#register(id%2Cfield_klass)-macro) method with the identifier of the field you wish to use, and the actual field class. For example:

```crystal
Marten::Schema::Field.register(:foo, FooField)
```

The identifier you pass to `#register` can be a symbol or a string. This is the identifier that is then made available to schema classes in order to define their fields:

```crystal
class MySchema < Marten::Schema
  field :title, :string
  // highlight-next-line
  field :test, :foo
end
```

The call to `#register` can be made from anywhere in your codebase, but obviously, you will want to ensure that it is done before requiring your schema classes: indeed, Marten will make the compilation of your project fail if it can't find the field type you are trying to use as part of a schema definition.

## Subclassing existing schema fields

This is probably the easiest way to create a custom field: if the field you want to create can be derived from one of the [built-in schema fields](../reference/fields.md) (usually those correspond to primitive types), then you can easily subclass the corresponding class and customize it so that it suits your needs.

For example, implementing a custom "email" field could be done by subclassing the existing [`Marten::Schema::Field::String`](pathname:///api/0.4/Marten/Schema/Field/String.html) class. Indeed, an "email" field is essentially a string with a pre-defined maximum size and some additional validation logic:

```crystal
class EmailField < Marten::Schema::Field::String
  def initialize(
    @id : ::String,
    @required : ::Bool = true,
    @max_size : ::Int32? = 254,
    @min_size : ::Int32? = nil
  )
    @strip = true
  end

  def validate(schema, value)
    return if !value.is_a?(::String)

    # Leverage string's built-in validations (max size, min size).
    super

    if !EmailValidator.valid?(value)
      schema.errors.add(id, "Provide a valid email address")
    end
  end
end
```

In the above snippet, the `EmailField` class simply overrides the `#validate` method so that it implements validation rules that are specific to the use case of email addresses (while also ensuring that regular string validations are executed as well).

Everything that is described in the following section about [creating schema fields from scratch](#creating-new-schema-fields-from-scratch) also applies to the case of subclassing existing schema fields: the same methods can be overridden if necessary, but leveraging an existing class can save you some work.

## Creating new schema fields from scratch

Creating new schema fields from scratch involves subclassing the [`Marten::Schema::Field::Base`](pathname:///api/0.4/Marten/Schema/Field/Base.html) abstract class. Because of this, the new field class is required to implement a set of mandatory methods. These mandatory methods, and some other ones that are optional (but interesting in terms of capabilities), are described in the following sections.

### Mandatory methods

#### `deserialize`

The `#deserialize` method is responsible for deserializing a schema field value. Indeed, the raw value of a schema field usually comes from a request's data and needs to be converted to another format. For example, a `uuid` field might need to convert a `String` value to a proper `UUID` object:

```crystal
def deserialize(value) : ::UUID?
  return if empty_value?(value)

  case value
  when Nil
    value
  when ::String
    value.empty? ? nil : ::UUID.new(value)
  when JSON::Any
    deserialize(value.raw)
  else
    raise_unexpected_field_value(value)
  end
rescue ArgumentError
  raise_unexpected_field_value(value)
end
```

Fields can be configured as required or not ([`required`](../reference/fields.md#required) option), this means that you will usually want to handle the case of `nil` values as part of this methods and return `nil` if the incoming value is `nil`. It should also be noted that incoming values can be any JSON data (`JSON::Any`), which means that you need to handle this case properly as well.

If the value can't be processed properly by your field class, then it may be necessary to raise an exception. To do that you can leverage the `#raise_unexpected_field_value` method, which will raise a `Marten::Schema::Errors::UnexpectedFieldValue` exception.

#### `serialize`

The `#serialize` method is responsible for serializing a field value, which is essentially the reverse of the [`#deserialize`](#deserialize) method. As such, this method must convert a field value from the "Crystal" representation to the "raw" schema representation.

For example, this method could return the string representation of a `UUID` object:

```crystal
def serialize(value) : ::String?
  value.try(&.to_s)
end
```

Again, if the value can't be processed properly by the field class, it may be necessary to raise an exception. To do that you can leverage the `#raise_unexpected_field_value` method, which will raise a `Marten::Schema::Errors::UnexpectedFieldValue` exception.

### Other useful methods

#### `initialize`

The default `#initialize` method that is provided by the [`Marten::Schema::Field::Base`](pathname:///api/0.4/Marten/Schema/Field/Base.html) is fairly simply and looks like this:

```crystal
def initialize(
  @id : ::String,
  @required : ::Bool = true
)
end
```

Depending on your field requirements, you might want to override this method completely in order to support additional parameters (such as default validation-related options for example).

#### `validate`

The `#validate` method does nothing by default and can be overridden on a per-field class basis in order to implement custom validation logic. This method takes the schema object being validated and the field value as arguments, which allows you to easily run validation checks and to add [validation errors](../validations.md) to the schema object.

For example:

```crystal
def validate(schema, value)
  return if !value.is_a?(::String)

  if !EmailValidator.valid?(value)
    schema.errors.add(id, "Provide a valid email address")
  end
end
```

### An example

Let's consider the use case of the "email" field highlighted in [Subclassing existing schema fields](#subclassing-existing-schema-fields). The exact same field could be implemented from scratch with the following snippet:

```crystal
class EmailField < Marten::Schema::Field::Base
  getter max_size
  getter min_size

  def initialize(
    @id : ::String,
    @required : ::Bool = true,
    @max_size : ::Int32? = 254,
    @min_size : ::Int32? = nil,
    @strip : ::Bool = true
  )
  end

  def deserialize(value) : ::String?
    strip? ? value.to_s.strip : value.to_s
  end

  def serialize(value) : ::String?
    value.try(&.to_s)
  end

  def strip?
    @strip
  end

  def validate(schema, value)
    return if !value.is_a?(::String)

    if !min_size.nil? && value.size < min_size.not_nil!
      schema.errors.add(id, "The minimum allowed length is #{min_size} characters")
    end

    if !max_size.nil? && value.size > max_size.not_nil!
      schema.errors.add(id, "The maximum allowed length is #{max_size} characters")
    end

    if !EmailValidator.valid?(value)
      record.errors.add(id, "Provide a valid email address")
    end
  end
end
```
