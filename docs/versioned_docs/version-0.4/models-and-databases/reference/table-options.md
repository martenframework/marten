---
title: Table options
description: Table options reference.
---

This page provides a reference for all the table options that can be leveraged when defining models.

## Table name

Table names for models are automatically generated from the model name and the label of the associated application. That being said, it is possible to specifically override the name of a model table by leveraging the [`#db_table`](pathname:///api/0.4/Marten/DB/Model/Table/ClassMethods.html#db_table(db_table%3AString|Symbol)-instance-method) class method, which requires a table name string or symbol.

For example:

```crystal
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text

// highlight-next-line
  db_table :articles
end
```

## Table indexes

Multifields indexes can be configured in a model by leveraging the [`#db_index`](pathname:///api/0.4/Marten/DB/Model/Table/ClassMethods.html#db_index(name%3AString|Symbol%2Cfield_names%3AArray(String)|Array(Symbol))%3ANil-instance-method) class method. This method requires an index name argument as well as an array of targeted field names.

For example:

```crystal
class Person < Marten::Model
  field :id, :int, primary_key: true, auto: true
  field :first_name, :string, max_size: 50
  field :last_name, :string, max_size: 50

// highlight-next-line
  db_index :person_full_name_index, field_names: [:first_name, :last_name]
end
```

## Table unique constraints

Multifields unique constraints can be configured in a model by leveraging the [`#db_unique_constraint`](pathname:///api/0.4/Marten/DB/Model/Table/ClassMethods.html#db_unique_constraint(name%3AString|Symbol%2Cfield_names%3AArray(String)|Array(Symbol))%3ANil-instance-method) class method. This method requires an index name argument as well as an array of targeted field names.

For example:

```crystal
class Booking < Marten::Model
  field :id, :int, primary_key: true, auto: true
  field :room, :string, max_size: 50
  field :date, :date, max_size: 50

// highlight-next-line
  db_unique_constraint :booking_room_date_constraint, field_names: [:room, :date]
end
```
