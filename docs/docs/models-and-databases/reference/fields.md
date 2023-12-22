---
title: Model fields
description: Model fields reference.
---

This page provides a reference for all the available field options and field types that can be used when defining models.

## Common field options

The following field options can be used for all the available field types when declaring model fields using the `field` macro.

### `blank`

The `blank` argument allows to define whether a field is allowed to receive blank values from a validation perspective. The fields with `blank: false` that receive blank values will make their associated model record validation fail. The default value for this argument is `false`.

### `db_column`

The `db_column` argument can be used to specify the name of the column corresponding to the field at the database level. Unless specified, the database column name will correspond to the field name.

### `default`

The `default` argument allows to define a default value for a given field. The default value for this argument is `nil`.

### `index`

The `index` argument can be used to specify that a database index must be created for the corresponding column. The default value for this argument is `false`.

### `primary_key`

The `primary_key` argument can be used to specify that a field corresponds to the primary key of the considered model table. The default value for this argument is `false`.

### `null`

The `null` argument allows to define whether a field is allowed to store `NULL` values in the database. The default value for this argument is `false`.

### `unique`

The `unique` argument allows to define that values for a specific field must be unique throughout the associated table. The default value for this argument is `false`.

## Field types

### `big_int`

A `big_int` field allows persisting 64-bit integers. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `auto`

The `auto` argument auto-increment for the considered database column. Defaults to `false`.

This argument will be used mainly when defining integer IDs that automatically increment:

```crystal
class MyModel < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  # ...
end
```

### `bool`

A `bool` field allows persisting booleans.

### `date`

A `date` field allows persisting date values, which map to `Time` objects in Crystal. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `auto_now`

The `auto_now` argument allows ensuring that the corresponding field value is automatically set to the current time every time a record is saved. This provides a convenient way to define `updated_at` fields. Defaults to `false`.

#### `auto_now_add`

The `auto_now_add` argument allows ensuring that the corresponding field value is automatically set to the current time every time a record is created. This provides a convenient way to define `created_at` fields. Defaults to `false`.

### `date_time`

A `date_time` field allows persisting date-time values, which map to `Time` objects in Crystal. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `auto_now`

The `auto_now` argument allows ensuring that the corresponding field value is automatically set to the current time every time a record is saved. This provides a convenient way to define `updated_at` fields. Defaults to `false`.

#### `auto_now_add`

The `auto_now_add` argument allows ensuring that the corresponding field value is automatically set to the current time every time a record is created. This provides a convenient way to define `created_at` fields. Defaults to `false`.

### `duration`

A `duration` field allows persisting duration values, which map to [`Time::Span`](https://crystal-lang.org/api/Time/Span.html) objects in Crystal. `duration` fields are persisted as big integer values (number of nanoseconds) at the database level.

### `email`

An `email` field allows to persist _valid_ email addresses. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument is optional and defaults to 254 characters (in accordance with RFCs 3696 and 5321). It allows to specify the maximum size of the persisted email addresses. This maximum size is used for the corresponding column definition and when it comes to validate field values.

### `file`

A `file` field allows persisting the reference to an uploaded file.

:::info
`file` fields can't be configured as primary keys.
:::

#### `storage`

This optional argument can be used to configure the storage that will be used to persist the actual files. It defaults to the media files storage (configured via the `media_files.storage` setting), but can be overridden on a per-field basis if needed:

```crystal
my_storage = Marten::Core::Storage::FileSystem.new(root: "files", base_url: "/files/")

class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, storage: my_storage
end
```

Please refer to [Managing files](../../files/managing-files.md) for more details on how to manage uploaded files and the associated storages.

#### `upload_to`

This optional argument can be used to configure where the uploaded files are persisted in the storage. It defaults to an empty string and can be set to either a string or a proc.

If set to a string, it allows to define in which directory of the underlying storage files will be persisted:

```crystal
class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, upload_to: "foo/bar"
end
```

If set to a proc, it allows to customize the logic allowing to generate the resulting path _and_ filename:

```crystal
class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, upload_to: ->(filename : String) { File.join("files/uploads", filename) }
end
```

### `float`

A `float` field allows persisting floating point numbers (`Float64` objects).

### `int`

An `int` field allows persisting 32-bit integers. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `auto`

The `auto` argument auto-increment for the considered database column. Defaults to `false`.

This argument will be used mainly when defining integer IDs that automatically increment:

```crystal
class MyModel < Marten::Model
  field :id, :int, primary_key: true, auto: true
  # ...
end
```

### `json`

A `json` field allows persisting JSON values to the database.

JSON values are automatically parsed from the underlying database column and exposed as a [`JSON::Any`](https://crystal-lang.org/api/JSON/Any.html) object (or `nil` if no values are available) by default in Crystal:

```crystal
class MyModel < Marten::Model
  # Other fields...
  field :metadata, :json
end

MyModel.last!.metadata # => JSON::Any object
```

Additionally, it is also possible to specify a [`serializable`](#serializable) option in order to specify a class that makes use of [`JSON::Serializable`](https://crystal-lang.org/api/JSON/Serializable.html). When doing so, the parsing of the JSON values will result in the initialization of the corresponding serializable objects:

```crystal
class MySerializable
  include JSON::Serializable

  property a : Int32 | Nil
  property b : String | Nil
end

class MyModel < Marten::Model
  # Other fields...
  field :metadata, :json, serializable: MySerializable
end

MyModel.last!.metadata # => MySerializable object
```

:::info
It should be noted that `json` fields are mapped to:

* `jsonb` columns in PostgreSQL databases
* `text` columns in MySQL databases
* `text` columns in SQLite databases
:::

#### `serializable`

The `serializable` arguments allows to specify that a class making use of [`JSON::Serializable`](https://crystal-lang.org/api/JSON/Serializable.html) should be used in order to parse the JSON values for the model field at hand. When specifying a `serializable` class, the values returned for the considered model fields will be instances of that class instead of [`JSON::Any`](https://crystal-lang.org/api/JSON/Any.html) objects.

### `slug`

A `slug` field allows to persist _valid_ slug values (ie. strings that can only include characters, numbers, dashes, and underscores). In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument is optional and defaults to 50 characters. It allows to specify the maximum size of the persisted email addresses. This maximum size is used for the corresponding column definition and when it comes to validate field values.

:::info
As slug fields are usually used to query records, they are indexed by default. You can use the [`index`](#index) option (`index: false`) to disable auto-indexing.
:::

### `string`

A `string` field allows to persist small or medium string values. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument **is required** and allows to specify the maximum size of the persisted string. This maximum size is used for the corresponding column definition and when it comes to validate field values.

#### `min_size`

The `min_size` argument allows defining the minimum size allowed for the persisted string. The default value for this argument is `nil`, which means that the minimum size is not validated by default.

### `text`

A `text` field allows to persist large text values. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument allows to specify the maximum size of the persisted string. This maximum size is used when it comes to validate field values. Defaults to `nil`.

### `url`

A `url` field allows persisting _valid_ URL addresses. In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `max_size`

The `max_size` argument is optional and defaults to 200 characters. It allows to specify the maximum size of the persisted URLs. This maximum size is used for the corresponding column definition and when it comes to validate field values.

### `uuid`

A `uuid` field allows persisting Universally Unique IDentifiers (`UUID` objects).

## Relationship field types

### `many_to_many`

A `many_to_many` field allows to define a many-to-many relationship. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

For example, an `Article` model could have a many-to-many field towards a `Tag` model. In such case, an `Article` record could have many associated `Tag` records, and every `Tag` records could be associated to many `Article` records as well:

```crystal
class Tag < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :tags, :many_to_many, to: Tag
end
```

In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `to`

The `to` argument **is required** and allows to specify the model class that is related to the model where the `many_to_many` field is defined.

#### `related`

The `related` argument allows defining the name of the reverse (or backward) relation on the targetted model. If we consider the previous example, it could be possible to define an `articles` backward relation in order to let `Tag` records expose their related `Article` records:

```crystal
class Tag < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :tags, :many_to_many, to: Tag, related: :articles
end
```

When the `related` argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that all the `Article` records using a specific `Tag` record could be accessed through the use of the `Tag#articles` method in the previous snippet.

The default value is `nil`, which means that no reverse relation is defined on the targetted model by default.

### `many_to_one`

A `many_to_one` field allows defining a many-to-one relationship. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

For example, an `Article` model could have a many-to-one field towards an `Author` model. In such case, an `Article` record would only have one associated `Author` record, but every `Author` record could be associated to many `Article` records:

```crystal
class Author < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :author, :many_to_one, to: Author
end
```

In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `to`

The `to` argument **is required** and allows to specify the model class that is related to the model where the `many_to_one` field is defined.

#### `related`

The `related` argument allows defining the name of the reverse (or backward) relation on the targetted model. If we consider the previous example, it could be possible to define an `articles` backward relation in order to let `Author` records expose their related `Article` records:

```crystal
class Author < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :author, :many_to_one, to: Author, related: :articles
end
```

When the `related` argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that all the `Article` records associated with a specific `Author` record could be accessed through the use of the `Author#articles` method in the previous snippet.

The default value is `nil`, which means that no reverse relation is defined on the targetted model by default.

#### `on_delete`

The `on_delete` argument allows to specify the deletion strategy to adopt when a related record (one that is targeted by the `many_to_one` field) is deleted. The following strategies can be specified (as symbols):

* `:do_nothing`: is the default strategy. With this strategy, Marten won't do anything to ensure that records referencing the record being deleted are deleted or updated. If the database enforces referential integrity (which will be the case for foreign key fields), this means that deleting a record could result in database errors.
* `:cascade`: this strategy can be used to perform cascade deletions. When deleting a record, Marten will try to first destroy the other records that reference the object being deleted.
* `:protect`: this strategy allows to explicitly prevent the deletion of records if they are referenced by other records. This means that attempting to delete a "protected" record will result in a `Marten::DB::Errors::ProtectedRecord` error.
* `:set_null`: this strategy will set the reference column to `null` when the related record is deleted.

### `one_to_one`

A `one_to_one` field allows defining a one-to-one relationship. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

For example, a `User` model could have a one-to-one field towards a `Profile` model. In such case, the `User` model could only have one associated `Profile` record, and the reverse would be true as well (a `Profile` record could only have one associated `User` record). In fact, a one-to-one field is really similar to a many-to-one field, but with an additional unicity constraint:

```crystal
class Profile < Marten::Model
  # ...
end

class User < Marten::Model
  # ...
  field :profile, :one_to_one, to: Profile
end
```

In addition to the [common field options](#common-field-options), such fields support the following arguments:

#### `to`

The `to` argument **is required** and allows to specify the model class that is related to the model where the `one_to_one` field is defined.

#### `related`

The `related` argument allows defining the name of the reverse (or backward) relation on the targetted model. If we consider the previous example, it could be possible to define a `user` backward relation in order to let `Profile` records expose their related `User` record:

```crystal
class Profile < Marten::Model
  # ...
end

class User < Marten::Model
  # ...
  field :profile, :one_to_one, to: Profile, related: :user
end
```

When the `related` argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that the `User` record associated with a specific `Profile` record could be accessed through the use of the `Profile#user` method in the previous snippet.

The default value is `nil`, which means that no reverse relation is defined on the targetted model by default.

#### `on_delete`

Same as [the similar option for the `#many_to_one` field](#on_delete).
