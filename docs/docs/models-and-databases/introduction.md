---
title: Introduction to models
description: Learn how to define models and interact with model records.
sidebar_label: Introduction
---

Models define what data can be persisted and manipulated by a Marten application. They explicitly specify fields and rules that map to database tables and columns. As such, they correspond to the layer of the framework that is responsible for representing business data and logic.

## Basic model definition

Marten models must be defined as subclasses of the [`Marten::Model`](pathname:///api/dev/Marten/DB/Model.html) base class; they explicitly define "fields" through the use of the `field` macro. These classes and fields map to database tables and columns that can be queried through the use of an automatically-generated database access API (see [Queries](./queries.md) for more details).

For example, the following code snippet defines a simple `Article` model:

```crystal
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
end
```

In the above example, `id`, `title`, and `content` are fields of the `Article` model. Each of these fields map to a database column in a table whose name is automatically inferred from the model name (and its associated application). If it was to be manually created using plain SQL, the `Article` model would correspond to the following statement (using the PostgreSQL syntax):

```sql
CREATE TABLE myapp_articles (
  "id" bigserial NOT NULL PRIMARY KEY,
  "title" varchar(255) NOT NULL,
  "content" text NOT NULL
);
```

## Models and installed apps

A model's application needs to be explicitly added to the list of installed applications for the considered project. Indeed, Marten requires projects to explicitly declare the applications they are using in the `installed_apps` configuration option. Model tables and migrations will only be created/applied for model classes that are provided by _installed apps_.

For example, if the above `Article` model was associated with a `MyApp` application class, it would be possible to ensure that it is used by ensuring that the `installed_app` configuration option is as follows:

```crystal
Marten.configure do |config|
  config.installed_apps = [
    MyApp,
    # other apps...
  ]
end
```

## Model fields

Model classes must define _fields_. Fields allow to specify the attributes of a model and they map to actual database columns. They are defined through the use of the `field` macro.

For example:

```crystal
class Author < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :first_name, :string, max_size: 255
  field :last_name, :string, max_size: 255
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
  field :author, :many_to_one, to: Author
end
```

### Field ID and field type

Every field in a model class must contain two mandatory positional arguments: a field identifier and a field type.

The field identifier is used by Marten in order to determine the name of the corresponding database column. This identifier is also used to generate the Crystal bindings that allow you to interact with field values through getters and setters.

The field type determines a few other things:

* the type of the corresponding database column (for example `INTEGER`, `TEXT`, etc)
* the getter and setter methods that are generated for the field in the model class
* how field values are actually validated

Marten provides numerous built-in field types that cover common web development needs. The complete list of supported fields is covered in the [model fields reference](./reference/fields.md).

:::note
It is possible to write custom model fields and use them in your model definitions. See [How to create custom model fields](./how-to/create-custom-model-fields.md) for more details.
:::

### Common field options

In addition to their identifiers and types, fields can take keyword arguments that allow to further configure their behaviors and how they map to database columns. Most of the time those additional keyword arguments are optional, but they can be mandatory depending on the considered field type.

Some of these optional field arguments are shared across all the available fields. Below is a list of the ones you'll encounter most frequently.

#### `null`

The `null` argument allows defining whether a field is allowed to store `NULL` values in the database. The default value for this argument is `false`.

#### `blank`

The `blank` argument allows defining whether a field is allowed to receive blank values from a validation perspective. The fields with `blank: false` that receive blank values will make their associated model record validation fail. The default value for this argument is `false`.

#### `default`

The `default` argument allows defining a default value for a given field. The default value for this argument is `nil`.

#### `unique`

The `unique` argument allows defining that values for a specific field must be unique throughout the associated table. The default value for this argument is `false`.

### Mandatory primary key

All Marten models must define one (and only one) primary key field. This primary key field will usually be an `int` or a `big_int` field using the `primary_key: true` and `auto: true` arguments, like in the following example:

```crystal
class MyModel < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
end
```

It should be noted that the primary key can correspond to any other field type. For example, your primary key could correspond to an `uuid` field:

```crystal
class MyModel < Marten::Model
  field :id, :uuid, primary_key: true

  after_initialize :initialize_id

  def initialize_id
    @id ||= UUID.random
  end
end
```

### Relationships

Marten provides special fields allowing to define the three most common types of database relationships: many-to-many, many-to-one, and one-to-one.

#### Many-to-one relationships

Many-to-one relationships can be defined through the use of [`many_to_one`](./reference/fields.md#many_to_one) fields. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

For example, an `Article` model could have a many-to-one field towards an `Author` model. In such case, an `Article` record would only have one associated `Author` record, but every `Author` record could be associated with many `Article` records:

```crystal
class Author < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :author, :many_to_one, to: Author
end
```

:::tip
It is possible to define recursive relationships by leveraging the `self` keyword. For example, if you want to define a many-to-one relationship field that targets that same model, you can do so easily by using `self` as the value for the `to` argument:

```crystal
class TreeNode < Marten::Model
  # ...
  field :parent, :many_to_one, to: self
end
```
:::

:::info
Please refer to [Many-to-one relationships](./relationships.md#many-to-one-relationships) to learn more about this type of model relationship.
:::

#### One-to-one relationships

One-to-one relationships can be defined through the use of [`one_to_one`](./reference/fields.md#one_to_one) fields. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

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

:::info
Please refer to [One-to-one relationships](./relationships.md#one-to-one-relationships) to learn more about this type of model relationship.
:::

#### Many-to-many relationships

Many-to-many relationships can be defined through the use of [`many_to_many`](./reference/fields.md#many_to_many) fields. This special field type requires the use of a special `to` argument in order to specify the model class to which the current model is related.

For example, an `Article` model could have a many-to-many field towards a `Tag` model. In such case, an `Article` record could have many associated `Tag` records, and every `Tag` record could be associated with many `Article` records as well:

```crystal
class Tag < Marten::Model
  # ...
end

class Article < Marten::Model
  # ...
  field :tags, :many_to_many, to: Tag
end
```

:::info
Please refer to [Many-to-many relationships](./relationships.md#many-to-many-relationships) to learn more about this type of model relationship.
:::

### Timestamps

Marten lets you easily add automatic `created_at` / `updated_at` [`date_time`](./reference/fields.md#date_time) fields to your models by leveraging the [`#with_timestamp_fields`](pathname:///api/dev/Marten/DB/Model/Table.html#with_timestamp_fields-macro) macro:

```crystal
class Article < Marten::Model
  // highlight-next-line
  with_timestamp_fields

  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
end
```

The `created_at` field is populated with the current time when new records are created while the `updated_at` field is refreshed with the current time whenever records are updated.

Note that using [`#with_timestamp_fields`](pathname:///api/dev/Marten/DB/Model/Table.html#with_timestamp_fields-macro) is technically equivalent as defining two `created_at` and `updated_at` [`date_time`](./reference/fields.md#date_time) fields as follows:

```crystal
class Article < Marten::Model
  // highlight-next-line
  field :created_at, :date_time, auto_now_add: true
  // highlight-next-line
  field :updated_at, :date_time, auto_now: true

  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
end
```

## Multifields indexes and unique constraints

Single model fields can be indexed or associated with a unique constraint _individually_ by leveraging the [`index`](./reference/fields.md#index) and [`unique`](./reference/fields.md#unique) field options. That being said, it is sometimes necessary to configure multifields indexes or unique constraints.

### Multifields indexes

Multifields indexes can be configured in a model by leveraging the [`#db_index`](pathname:///api/dev/Marten/DB/Model/Table/ClassMethods.html#db_index(name%3AString|Symbol%2Cfield_names%3AArray(String)|Array(Symbol))%3ANil-instance-method) class method. This method requires an index name argument as well as an array of targeted field names.

For example:

```crystal
class Person < Marten::Model
  field :id, :int, primary_key: true, auto: true
  field :first_name, :string, max_size: 50
  field :last_name, :string, max_size: 50

  db_index :person_full_name_index, field_names: [:first_name, :last_name]
end
```

### Multifields unique constraints

Multifields unique constraints can be configured in a model by leveraging the [`#db_unique_constraint`](pathname:///api/dev/Marten/DB/Model/Table/ClassMethods.html#db_unique_constraint(name%3AString|Symbol%2Cfield_names%3AArray(String)|Array(Symbol))%3ANil-instance-method) class method. This method requires an index name argument as well as an array of targeted field names.

For example:

```crystal
class Booking < Marten::Model
  field :id, :int, primary_key: true, auto: true
  field :room, :string, max_size: 50
  field :date, :date, max_size: 50

  db_unique_constraint :booking_room_date_constraint, field_names: [:room, :date]
end
```

The above constraint ensures that each room can only be booked for each date.

## CRUD operations

CRUD stands for **C**reate, **R**ead, **U**pdate, and **D**elete. Marten provides a set of methods and tools allowing applications to read and manipulate data stored in model tables.

### Create

Model records can be created through the use of the `#new` and `#create` methods. The `#new` method will simply initialize a new model record that is not persisted in the database. The `#create` method will initialize the new model record using the specified attributes and persist it to the database.

For example, it would be possible to create a new `Article` model record by specifying its `title` and `content` attribute values through the use of the `#create` method as follows:

```crystal
Article.create(title: "My article", content: "Learn how to build web apps with Marten!")
```

The same `Article` record could be initialized (but not saved!) through the use of the `new` method as follows:

```crystal
Article.new(title: "My article", content: "Learn how to build web apps with Marten!")
```

It should be noted that field values can be assigned after a model instance has been initialized. For example, the previous example is equivalent to the following snippet:

```crystal
article = Article.new
article.title = "My article"
article.content = "Learn how to build web apps with Marten!"
```

A model instance that was initialized like in the previous example will not be persisted to the database automatically. In this situation, it is possible to ensure that the corresponding record is created in the database by using the `#save` method (`article.save`).

Finally it should be noted that both `#create` and `#new` support an optional block that will receive the initialized model record. This allows to initialize attributes or to call additional methods on the record being initialized:

```crystal
Article.create do |article|
  article.title = "My article"
  article.content = "Learn how to build web apps with Marten!"
end
```

### Read

Marten models provide a powerful API allowing to read and query records. This is achieved by constructing "query sets". A query set is a representation of records collections from the database that can be filtered.

For example, it is possible to return a collection of all the `Article` model records using:

```crystal
Article.all
```

It is possible to retrieve a specific record matching a set of filters (for example the value of an identifier) by using:

```crystal
Article.get(id: 42)
```

Finally the following snippet showcases how to filter `Article` records by title and to sort them by creation date in reverse chronological order:

```crystal
Article.filter(name: "My article").order("-created_at")
```

Please head over to the [Model queries](./queries.md) guide in order to learn more about model querying capabilities.

### Update

Once a model record has been retrieved from the database, it is possible to update it by modifying its attributes and calling the `#save` method:

```crystal
article = Article.get(id: 42)
article.title = "Updated!"
article.save
```

Marten also provide the ability to update the records that are targetted by a specific query set through the use of the `#update` method, like in the following example:

```crystal
Article.filter(title: "My article").update(title: "Updated!")
```

### Delete

Once a model record has been retrieved from the database, it is possible to delete it by using the `#delete` method:

```crystal
article = Article.get(id: 42)
article.delete
```

Marten also provide the ability to delete the records that are targetted by a specific query set through the use of the `#delete` method, like in the following example:

```crystal
Article.filter(title: "My article").delete
```

## Validations

Marten lets you specify how to validate model records before they are persisted to the database. These validation rules can be inherited from the fields in your model depending on the options you used (for example fields using `blank: false` will make the associated record validation fail if the field value is blank). They can also be explicitly specified in your model class, which is useful if you need to implement custom validation logics.

For example:

```crystal
class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255

  validate :validate_name

  private def validate_name
    errors.add(:name, "Name must not be less than 3 characters!") if name && name!.size < 3
  end
end
```

Most of the methods presented above that actually persist model records to the database (like `#create` or `#save`) run these validation rules. This means that they will automatically validate the considered records before propagating any changes to the database. It should be noted that in the event that a record is invalid, these methods will return `false` to indicate that the considered object is invalid (and they will return `true` if the object is valid). The `#create` and `#save` methods also have bang counterparts (`#create!` and `#save!`) that will explicitly raise a validation error in case of invalid records:

```crystal
article = Article.new
article.save
# => false
article.save!
# => Unhandled exception: Record is invalid (Marten::DB::Errors::InvalidRecord)
```

Please head over to the [Model validations](./validations.md) guide in order to learn more about model validations.

## Inheritance

Model classes can inherit from each other. This allows you to easily reuse the field definitions and table attributes of a parent model within a child model.

Presently, the Marten web framework allows [abstract model inheritance](#inheriting-from-abstract-models) (which is useful in order to reuse shared model fields and patterns over multiple child models without having a database table created for the parent model) and [multi-table inheritance](#multi-table-inheritance).

### Abstract model inheritance

You can define abstract model classes by leveraging [Crystal's abstract type mechanism](https://crystal-lang.org/reference/syntax_and_semantics/virtual_and_abstract_types.html). Doing so allows to easily reuse model field definitions, table properties, and custom logics within child models. In this situation, the parent's model does not contribute any table to the considered database.

For example:

```crystal
abstract class Person < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255
  field :email, :string, max_size: 255
end

class Student < Person
  field :grade, :string, max_size: 15
end
```

The `Student` model will have four model fields in total (`id`, `name`, `email`, and `grade`). Moreover, all the methods of the parent model fields will be available on the child model. It should be noted that in this case the `Person` model cannot be used like a regular model: for example, trying to query records will return an error since no table is actually associated with the abstract model. Since it is an [abstract type](https://crystal-lang.org/reference/syntax_and_semantics/virtual_and_abstract_types.html), the `Student` class can't be instantiated either.

### Multi table inheritance

Marten also supports another form of model inheritance, where each model in the hierarchy is a concrete model (i.e., a model that is not abstract). In this situation, each model can be used/queried individually and has its own associated database. The framework upholds "links" between each model that uses multi table inheritance and its parent models in order to ensure that the relational structure and inheritance hierarchy are accurately maintained.

For example, let's consider the following models:

```crystal
class Person < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :first_name, :string, max_size: 100
  field :last_name, :string, max_size: 100
end

class Employee < Person
  field :company_name, :string, max_size: 100
end
```

All the fields defined in the `Person` model will be accessible when interacting with records of the `Employee` model, despite the fact that the data itself is stored in distinct tables. This means that it will be possible to filter `Employee` records using fields defined in the `Person` model, and to interact with the corresponding attributes when manipulating the obtained model instances:

```crystal
employee = Employee.filter(first_name: "John").first!
employee.first_name # => "John"
```

Initializing or creating `Employee` records will also work as you would expect if all the fields were defined in the `Employee` model class:

```crystal
employee = Employee.create!(
  first_name: "John",
  last_name: "Doe",
  company_name: "Super org"
)
```

Additionaly, it's important to note that attempting to filter or retrieve `Person` records will return `Person` instances. When manipulating a parent model instance, it is possible to get a child model record by calling the `#<child_model>` method - with `child_model` being the downcased version of the child model name. For example:

```crystal
person = Person.filter(first_name: "John").first!
person.employee # => #<Employee:0x101590c40 person_ptr_id: 1, first_name: "John" ...>
```

You should note that if the `Person` record is not an employee, then calling `#employee` will return `nil`.

:::note
It's important to note that when retrieving and filtering model records that utilize multi-table inheritance (such as child model records), there will be added join operations within the underlying SQL queries. These joins are necessary to assemble the complete data from various related tables, potentially affecting the overall query performance.
:::

## Callbacks

It is possible to define callbacks in your model in order to bind methods and logics to specific events in the life cycle of your model records. For example, it is possible to define callbacks that run before a record gets created, or before it is destroyed.

Please head over to the [Model callbacks](./callbacks.md) guide in order to learn more about model callbacks.

## Migrations

When working with models, it is necessary to ensure that any changes made to model definitions are applied at the database level. This is achieved through the use of migrations. 

Marten provides a migrations mechanism that is designed to be automatic: this means that migrations will be automatically generated from your model definitions when you run a dedicated command (the `genmigrations` command). Please head over to [Model migrations](./migrations.md) in order to learn more about migrations generations and the associated workflows.
