---
title: Create custom model fields
description: How to create custom model fields.
---

Marten gives you the ability to create your own custom model field implementations, which can involve custom validation logics, errors, and custom behaviors. You can choose to leverage these custom fields as part of your project's model definitions, and you can even distribute them to let other projects use them.

## Model fields: scope and responsibilities

Model fields have the following responsibilities:

* they define the type and properties of the underlying column at the database level
* they define the necessary Crystal bindings at the model class level: this means that they can contribute custom methods or instance variables to the models making use of them (eg. getters, setters, etc)
* they define how field values are validated and/or sanitized

Creating a custom model field does not necessarily mean that all of these responsibilities need to be taken care of as part of the custom field implementation. It really depends on whether you want to:

* leverage an existing built-in model field (eg. integer, string, etc)
* or create a new model field from scratch.

## Registering new model fields

Regardless of the approach you take in order to define new model field classes ([subclassing built-in fields](#subclassing-existing-model-fields), or [creating new ones from scratch](#creating-new-model-fields-from-scratch)), these classes must be registered to the Marten's global fields registry in order to make them available for use when defining models.

To do so, you will have to call the [`Marten::DB::Field#register`](pathname:///api/0.4/Marten/DB/Field.html#register(id%2Cfield_klass)-macro) method with the identifier of the field you wish to use, and the actual field class. For example:

```crystal
Marten::DB::Field.register(:foo, FooField)
```

The identifier you pass to `#register` can be a symbol or a string. This is the identifier that is then made available to model classes in order to define their fields:

```crystal
class MyModel < Marten::DB::Model
  field :id, :big_int, primary_key: true, auto: true
  // highlight-next-line
  field :test, :foo, blank: true, null: true
end
```

The call to `#register` can be made from anywhere in your codebase, but obviously, you will want to ensure that it is done before requiring your model classes: indeed, Marten will make the compilation of your project fail if it can't find the field type you are trying to use as part of a model definition.

## Subclassing existing model fields

The easiest way to introduce a model field is probably to subclass one of the [built-in model fields](../reference/fields.md) provided by Marten. This can make a lot of sense if the "type" of the field you are trying to implement is already supported by Marten.

For example, implementing a custom "email" field could be done by subclassing the existing [`Marten::DB::Field::String`](pathname:///api/0.4/Marten/DB/Field/String.html) class. Indeed, an "email" field is essentially a string with a pre-defined maximum size and some additional validation logic:

```crystal
class EmailField < Marten::DB::Field::String
  def initialize(
    @id : ::String,
    @max_size : ::Int32 = 254,
    @primary_key = false,
    @default : ::String? = nil,
    @blank = false,
    @null = false,
    @unique = false,
    @index = false,
    @db_column = nil
  )
  end

  def validate(record, value)
    return if !value.is_a?(::String)

    # Leverage string's built-in validations (max size).
    super

    if !EmailValidator.valid?(value)
      record.errors.add(id, "Provide a valid email address")
    end
  end

  macro check_definition(field_id, kwargs)
    # No-op max_size automatic checks...
  end
end
```

Everything that is described in the following section about [creating model fields from scratch](#creating-new-model-fields-from-scratch) also applies to the case of subclassing existing model fields: the same methods can be overridden if necessary, but leveraging an existing class can save you some work.

## Creating new model fields from scratch

Creating new model fields from scratch involves subclassing the [`Marten::DB::Field::Base`](pathname:///api/0.4/Marten/DB/Field/Base.html) abstract class. Because of this, the new field class is required to implement a set of mandatory methods. These mandatory methods, and some other ones that are optional (but interesting in terms of capabilities), are described in the following sections.

### Mandatory methods

#### `default`

The `#default` method is responsible for returning the field's default value, if any. Not all fields support default values; if this does not apply to your field use case, you can simply "no-op" this method:

```crystal
def default
  # no-op
end
```

On the other hand, if your field can be initialized with a `default` argument (and if it defines a `@default` instance variable), another possibility is to define a `#default` getter:

```crystal
getter default
```

#### `from_db`

The `#from_db` method is responsible for converting the passed raw DB value to the right field value. Indeed, the value that is read from the database will usually need to be converted to another format. For example, a `uuid` field might need to convert a `String` value to a proper `UUID` object:

```crystal
def from_db(value) : ::UUID?
  case value
  when Nil
    value.as?(Nil)
  when ::String
    ::UUID.new(value.as(::String))
  when ::UUID
    value.as(::UUID)
  else
    raise_unexpected_field_value(value)
  end
end
```

It should be noted that you will usually want to handle the case of `nil` values as part of this method since fields can be configured as nullable via the [`null: true`](../reference/fields.md#null) option. 

If the value can't be processed properly by your field class, then it may be necessary to raise an exception. To do that you can leverage the `#raise_unexpected_field_value` method, which will raise a `Marten::DB::Errors::UnexpectedFieldValue` exception.

#### `from_db_result_set`

The `#from_db_result_set` method is responsible for extracting the field value from a DB result set and returning the right object corresponding to this value. This method will usually be called when retrieving your field's value from the database (when using the Marten ORM). The method takes a standard `DB::ResultSet` object as argument and it is expected that you use `#read` to retrieve the intended column value. See the [Crystal reference documentation](https://crystal-lang.org/reference/1.5/database/index.html#reading-query-results) for more details around these objects and methods.

For example:

```crystal
def from_db_result_set(result_set : ::DB::ResultSet) : ::UUID?
  from_db(result_set.read(Nil | ::String | ::UUID))
end
```

The `#from_db_result_set` method is supposed to return the read value into the right "representation", that is the final object representing the field value that users will interact with when manipulating model records (for example a `UUID` object created from a string). As such, you will usually want to call [`#from_db`](#fromdb) once you get the value from the database result set in order to return the final value.

#### `to_column`

Most model fields will contribute a corresponding column at the database level; these columns are read by Marten in order to generate migrations from model definitions. The column returned by the `#to_column` method should be an instance of a subclass of [`Marten::DB::Management::Column::Base`](pathname:///api/0.4/Marten/DB/Management/Column/Base.html).

For example, an "email" field could return a string column as part of its `#to_column` method:

```crystal
def to_column : Marten::DB::Management::Column::Base?
  Marten::DB::Management::Column::String.new(
    name: db_column!,
    max_size: max_size,
    primary_key: primary_key?,
    null: null?,
    unique: unique?,
    index: index?,
    default: to_db(default)
  )
end
```

If for some reason your custom field does not contribute any columns to the database model, it is possible to simply "no-op" the `#to_column` method by returning `nil` instead.

#### `to_db`

The `#to_db` method converts a field value from the "Crystal" representation to the database representation. As such, this method performs the reverse operation of the [`#from_db`](#fromdb) method.

For example, this method could return the string representation of a `UUID` object:

```crystal
def to_db(value) : ::DB::Any
  case value
  when Nil
    nil
  when ::UUID
    value.hexstring
  else
    raise_unexpected_field_value(value)
  end
end
```

Again, if the value can't be processed properly by the field class, it may be necessary to raise an exception. To do that you can leverage the `#raise_unexpected_field_value` method, which will raise a `Marten::DB::Errors::UnexpectedFieldValue` exception.

### Other useful methods

#### `initialize`

The default `#initialize` method that is provided by the [`Marten::DB::Field::Base`](pathname:///api/0.4/Marten/DB/Field/Base.html) is fairly simply and looks like this:

```crystal
def initialize(
  @id : ::String,
  @primary_key = false,
  @blank = false,
  @null = false,
  @unique = false,
  @index = false,
  @db_column = nil
)
end
```

Depending on your field requirements, you might want to override this method completely in order to support additional parameters (such as default values, max sizes, validation-related options, etc).

#### `validate`

The `#validate` method does nothing by default and can be overridden on a per-field class basis in order to implement custom validation logic. This method takes the model record being validated and the field value as arguments, which allows you to easily run validation checks and to add [validation errors](../validations.md) to the model record.

For example:

```crystal
def validate(record, value)
  return if !value.is_a?(::String)

  if !EmailValidator.valid?(value)
    record.errors.add(id, "Provide a valid email address")
  end
end
```

### An example

Let's consider the use case of the "email" field highlighted in [Subclassing existing model fields](#subclassing-existing-model-fields). The exact same field could be implemented from scratch with the following snippet:

```crystal
class EmailField < Marten::DB::Field::Base
  getter default
  getter max_size

  def initialize(
    @id : ::String,
    @max_size : ::Int32 = 254,
    @primary_key = false,
    @default : ::String? = nil,
    @blank = false,
    @null = false,
    @unique = false,
    @index = false,
    @db_column = nil
  )
  end

  def from_db(value) : ::String?
    case value
    when Nil | ::String
      value.as?(Nil | ::String)
    else
      raise_unexpected_field_value(value)
    end
  end

  def from_db_result_set(result_set : ::DB::ResultSet) : ::String?
    result_set.read(::String?)
  end

  def to_column : Marten::DB::Management::Column::Base?
    Marten::DB::Management::Column::String.new(
      name: db_column!,
      max_size: max_size,
      primary_key: primary_key?,
      null: null?,
      unique: unique?,
      index: index?,
      default: to_db(default)
    )
  end

  def to_db(value) : ::DB::Any
    case value
    when Nil
      nil
    when ::String
      value
    when Symbol
      value.to_s
    else
      raise_unexpected_field_value(value)
    end
  end

  def validate(record, value)
    return if !value.is_a?(::String)

    if value.size > @max_size
      record.errors.add(id, "The maximum allowed length is #{@max_size} characters")
    end

    if !EmailValidator.valid?(value)
      record.errors.add(id, "Provide a valid email address")
    end
  end
end
```
