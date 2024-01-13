---
title: Schema fields
description: Schema fields reference.
---

This page provides a reference for all the available field options and field types that can be used when defining schemas.

## Common field options

The following field options can be used for all the available field types when declaring schema fields using the `field` macro.

### `required`

The `required` argument can be used to specify whether a schema field is required or not required. The default value for this argument is `true`.

## Field types

### `bool`

A `bool` field allows validating boolean values.

### `date_time`

A `date_time` field allows validating date time values. Fields using this type are converted to `Time` objects in Crystal.

### `date`

A `date` field allows validating date values. Fields using this type are converted to `Time` objects in Crystal.

### `duration`

A `duration` field allows validating duration values, which map to [`Time::Span`](https://crystal-lang.org/api/Time/Span.html) objects in Crystal. `duration` fields expect serialized values to be in the `DD.HH:MM:SS.nnnnnnnnn` format (with `n` corresponding to nanoseconds) or in the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#Durations) format (eg. `P3DT2H15M20S`, which corresponds to a `3.2:15:20` time span).

### `email`

An `email` field allows validating email address values. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument allows defining the maximum size allowed for the email address string. The default value for this argument is `254` (in accordance with RFCs 3696 and 5321).

#### `min_size`

The `min_size` argument allows defining the minimum size allowed for the email address string. The default value for this argument is `nil`, which means that the minimum size is not validated by default.

#### `strip`

The `strip` argument allows defining whether the string value should be stripped of leading and trailing whitespaces. The default is `true`.

### `file`

A `file` field allows validating uploaded files. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `allow_empty_files`

The `allow_empty_files` argument allows defining whether empty files are allowed or not when files are validated. The default value is `false`.

#### `max_name_size`

The `max_name_size` argument allows defining the maximum file name size allowed. The default value is `nil`, which means that uploaded file name sizes are not validated.

### `float`

A `float` field allows validating float values. Fields using this type are converted to `Float64` objects in Crystal. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_value`

The `max_value` argument allows defining the maximum value allowed. The default value for this argument is `nil`, which means that the maximum value is not validated by default.

#### `min_value`

The `min_value` argument allows defining the minimum value allowed. The default value for this argument is `nil`, which means that the minimum value is not validated by default.

### `int`

An `int` field allows validating integer values. Fields using this type are converted to `Int64` objects in Crystal. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_value`

The `max_value` argument allows defining the maximum value allowed. The default value for this argument is `nil`, which means that the maximum value is not validated by default.

#### `min_value`

The `min_value` argument allows defining the minimum value allowed. The default value for this argument is `nil`, which means that the minimum value is not validated by default.

### `json`

A `json` field allows validating JSON values, which are automatically parsed to [`JSON::Any`](https://crystal-lang.org/api/JSON/Any.html) objects. Additionally, it is also possible to leverage the [`serializable`](#serializable) option in order to specify a class that makes use of [`JSON::Serializable`](https://crystal-lang.org/api/JSON/Serializable.html). When doing so, the parsing of the JSON values will result in the initialization of the corresponding serializable objects:

```crystal
class MySerializable
  include JSON::Serializable

  property a : Int32 | Nil
  property b : String | Nil
end

class MySchema < Marten::Schema
  # Other fields...
  field :metadata, :json, serializable: MySerializable
end

schema = MySchema.new(Marten::Schema::DataHash{"metadata" => %{{"a": 42, "b": "foo"}}})
schema.valid?    # => true
schema.metadata! # => MySerializable object
```

#### `serializable`

The `serializable` arguments allows to specify that a class making use of [`JSON::Serializable`](https://crystal-lang.org/api/JSON/Serializable.html) should be used in order to parse the JSON values for the schema field at hand. When specifying a `serializable` class, the values returned for the considered schema fields will be instances of that class instead of [`JSON::Any`](https://crystal-lang.org/api/JSON/Any.html) objects.

### `slug`

A `slug` field allows validating slug values (ie. strings that can only include characters, numbers, dashes, and underscores). In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument allows defining the maximum size allowed for the slug string. The default value for this argument is `50`.

#### `min_size`

The `min_size` argument allows defining the minimum size allowed for the slug string. The default value for this argument is `nil`, which means that the minimum size is not validated by default.

#### `strip`

The `strip` argument allows defining whether the string value should be stripped of leading and trailing whitespaces. The default is `true`.

### `string`

A `string` field allows validating string values. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument allows defining the maximum size allowed for the string. The default value for this argument is `nil`, which means that the maximum size is not validated by default.

#### `min_size`

The `min_size` argument allows defining the minimum size allowed for the string. The default value for this argument is `nil`, which means that the minimum size is not validated by default.

#### `strip`

The `strip` argument allows defining whether the string value should be stripped of leading and trailing whitespaces. The default is `true`.

### `uuid`

A `uuid` field allows validating Universally Unique IDentifiers (UUID) values. Fields using this type are converted to `UUID` objects in Crystal.

### `url`

A `url` field allows validating URL address values. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument allows defining the maximum size allowed for the URL string. The default value for this argument is `200`.

#### `min_size`

The `min_size` argument allows defining the minimum size allowed for the URL string. The default value for this argument is `nil`, which means that the minimum size is not validated by default.

#### `strip`

The `strip` argument allows defining whether the string value should be stripped of leading and trailing whitespaces. The default is `true`.
