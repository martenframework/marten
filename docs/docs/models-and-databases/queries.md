---
title: Querying model records
description: Learn how to query model records.
sidebar_label: Queries
---

Once [models are properly defined](./introduction.md), it is possible to leverage the querying API in order to interact with model records. This API lets you build what is commonly referred to as "query sets": that is, representations of records collections that can be read, filtered, updated, or deleted.

This documents covers the main features of the [query set API](./reference/query-set.md). Most of the examples used to illustrate these features will refer to the following models:

```crystal
class City < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255
end

class Author < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :first_name, :string, max_size: 255
  field :last_name, :string, max_size: 255
  field :hometown, :foreign_key, to: City, blank: true, null: true
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
  field :author, :many_to_one, to: Author
end
```

## Creating new records

New model records can be created through the use of the `#new` and `#create` methods. The `#new` method will simply initialize a new model record that is not persisted in the database. The `#create` method will initialize the new model record using the specified attributes and then persist it to the database.

For example, it is possible to create a new `Author` model record by specifying their `first_name` and `last_name` attribute values through the use of the `create` method like this:

```crystal
Author.create(first_name: "John", last_name: "Doe")
```

The same `Author` record could be initialized (but not saved!) through the use of the `new` method as follows:

```crystal
Author.new(first_name: "John", last_name: "Doe")
```

In the previous example the model instance will not be persisted to the database automatically. In order to explicitly save it to the database it is possible to use the `#save` method:

```crystal
author = Author.new(first_name: "John", last_name: "Doe") # not persisted yet!
author.save                                               # the author is now persisted to the database!
```

Finally, it should be noted that both `#create` and `#new` support an optional block that will receive the initialized model record. This allows to initialize attributes or to call additional methods on the record being initialized:

```crystal
Author.create do |author|
  author.first_name = "John"
  author.last_name = "Doe"
end
```

:::caution
Model records will be validated before being saved to the database. If this validation fails, both the `#create` and `#save` methods will silently fail: `#create` will return the invalid model instance while `#save` will return `false`. The `#create` and `#save` methods also have bang counterparts (`#create!` and `#save!`) that will explicitly raise a validation error (`Marten::DB::Errors::InvalidRecord`) in case of an invalid record.

Please refer to [Validations](./validations.md) in order to learn more about model validations.
:::

## Basic querying capabilities

In order to interact with a collection of model records, it is necessary to construct a "query set". A query set represents a collection of model records in the database. It can have filters, be paginated, etc. Unless a specific "write" operation is performed on such query sets, they will usually be mapped to a standard `SELECT` statement where filters are converted to `WHERE` clauses.

Query sets can be forged from a specific model by using methods such `#all`, `#filter`, or `#exclude` (those are described below). One of the key characteristics of query sets is that they are **lazily evaluated**: defining a query set will usually not involve any database operation. Additionally, most methods provided by query sets also return new query set objects. Query sets are only translated to SQL queries hitting the underlying database when records need to be extracted or manipulated by the considered codebase.

For example, filters can be chained on a query set without it being evaluated. The query set is only evaluated when the actual records need to be displayed or when it becomes necessary to interact with them:

```crystal
qset = Article.filter(title__startswith: "Top") # the query set is not evaluated
qset = qset.filter(author__first_name: "John")  # the query set is not evaluated
puts qset                                       # the query set is evaluated
```

In the above example, the two filters are simply chained without these resulting in database hits. The query set is only evaluated when the actual records need to be printed.

Query sets are **iterable**: they provide the ability to iterate over the resulting records (which will also force the query set to be evaluated when this happens):

```crystal
qset = Article.filter(title__startswith: "Top") # the query set is not evaluated
qset.each { |article| puts article }            # the query set is evaluated
```

### Querying all records

Retrieving all the records of a specific model can be achieved through the use of the `#all` method:

```crystal
Author.all
```

"All records" does not necessarily mean all the records in the considered table. For example, `#all` can be chained to an existing query set that was filtered (which is usually unnecessary since this does not alter the resulting records):

```crystal
Author.filter(first_name: "John").all
```

### Filtering specific records

Filtering records is achieved through the use of the `#filter` method. The `#filter` method requires one or many predicate keyword arguments (in the format described in [Field predicates](#field-predicates)). For example:

```crystal
Author.filter(first_name: "John")
```

The above query set will return `Author` records whose first name is "John".

It’s possible to filter records using multiple filters. For example, the following queries are equivalent:

```crystal
Author.filter(first_name: "John").filter(last_name: "Doe")
Author.filter(first_name: "John", last_name: "Doe")
```

By default, filters involving multiple parameters like in the above examples always produce SQL queries whose parameters are "AND"ed together. More complex queries (eg. using OR, NOT conditions) can be achieved through the use of the `q` DSL (which is described in [Complex filters with `q` expressions](#complex-filters-with-q-expressions)), as outlined by the following examples:

```crystal
# Get Author records with either "Bob" or "Alice" as first name
Author.filter { q(first_name: "Bob") | q(first_name: "Alice") }
 
# Get Author records whose first names are not "John"
Author.filter { -q(first_name: "Alice") }
```

### Excluding specific records

Excluding records is achieved through the use of the `#exclude` method. This method provides exactly the same API as the [`#filter`](#filtering-specific-records) method outlined previously. It requires one or many predicate keyword arguments (in the format described in [Field predicates](#field-predicates)). For example:

```crystal
Author.exclude(first_name: "John")

Author.exclude(first_name: "John").exclude(last_name: "Doe")
Author.exclude(first_name: "John", last_name: "Doe")

Author.exclude { q(first_name: "Bob") | q(first_name: "Alice") }
```

### Retrieving a specific record

Retrieving a specific record is achieved through the use of the `#get` method, which requires one or many predicate keyword arguments (in the format described in [Field predicates](#field-predicates)). For example:

```crystal
Author.get(id: 1)
Author.get(first_name: "John")
```

If the record is not found, `nil` will be returned. It should be noted that a bang version of this method also exists: `#get!`. This alternative method raises a `Marten::DB::Errors::RecordNotFound` error if the record is not found. Regardless of the method used, if multiple records are found for the passed predicates, a `Marten::DB::Errors::MultipleRecordsFound` error is raised.

It is also possible to chain a `#get` call on a query set that was already filtered:

```crystal
Author.filter(first_name: "John").get(id: 42)
```

### Retrieving the first or last record

The `#first` and `#last` methods can be used to retrieve the first or last record for a given query set.

```crystal
Author.filter(first_name: "John").first
Author.filter(first_name: "John").last
```

If the considered query set is empty, the returned value will be `nil`. It should be noted that these methods have a bang equivalent (`#first!` and `#last!`) that both raise a `NilAssertionError` if the query set is empty.

### Field predicates

Field predicates allow to define filters that are applied to a given query set. They map to `WHERE` clauses in the produced SQL queries.

For example:

```crystal
Article.filter(title__icontains: "top")
```

Will translate to a SQL query like the following one (using PostgreSQL's syntax):

```sql
SELECT * FROM articles WHERE title LIKE UPPER("top")
```

Field predicates always contain a mandatory field name (`title` in the previous example) and an optional predicate type (`icontains` in the previous example). The field name and the predicate type are always separated by a double underscore notation (`__`). This notation (`<field_name>__<predicate_type>`) is used as the keyword argument name while the argument value is used to define the value to use to perform the filtering.

:::tip
The field name can correspond to any of the fields defined in the model being filtered. For `many_to_one` or `one_to_one` fields, it's possible to append a `_id` at the end of the field name to explicitly filter on the raw ID of the related record:

```crystal
Article.all.filter(author_id: 42)
```
:::

Marten support numerous predicate types, which are all documented in the [field predicates reference](./reference/query-set.md#field-predicates). The ones that you'll encounter most frequently are outlined below:

#### `exact`

The `exact` field predicate can be used for "exact" matches: only records whose field values exactly match the specified value will be returned. This is the default predicate type, and it's not necessary to specify it when filtering model records.

As such, the two following examples are equivalent:

```crystal
Author.filter(first_name: "John")
Author.filter(first_name__exact: "John")
```

#### `iexact`

This field predicate can be used for case insensitive matches.

For example, the following filter would return `Article` records whose titles are `Test`, `TEST` or `test`:

```crystal
Article.filter(title__iexact: "test")
```

#### `contains`

This field predicate can be used to filter strings that should contain a specific value. For example:

```crystal
Article.filter(title__contains: "top")
```

A case insensitive equivalent (`icontains`) is also available.

## Advanced querying capabilities

### Complex filters with `q` expressions

As mentioned previously, field predicates expressed as keyword arguments will use an AND operator in the produced `WHERE` clauses. In order to produce conditions using other operators, it is necessary to use `q` expressions.

In order to produce such expressions, methods like `#filter`, `#exclude`, or `#get` can receive a block allowing to define complex conditions. Inside of this block, a `#q` method can be used in order to define conditions nodes that can be combined together using the following operators:

* `&` in order to perform a logical "AND"
* `|` in order to perform a logical "OR"
* `-` in order to perform a logical negation

For example, the following snippet will return all the `Article` records whose title starts with "Top" or "10":

```crystal
Article.filter { q(title__startswith: "Top") | q(title__startswith: "10") }
```

Using this approach, it is possible to produce complex conditions by combining `q()` expressions with the `&`, `|`, and `-` operators. Parentheses can also be used to group statements:

```crystal
Article.filter { 
  (q(title__startswith: "Top") | q(title__startswith: "10")) & -q(author__first_name: "John")
}
```

Finally it should be noted that you can define many field predicates _inside_ `q()` expressions. When doing so, the field predicates will be "AND"ed together:

```crystal
Article.filter { 
  q(title__startswith: "Top") & -q(author__first_name: "John", author__last_name: "Doe")
}
```

### Filtering relations

The double underscores notation described previously (`__`) can also be used to filter based on related model fields. For example, in the considered models definitions, we have an `Article` model which defines a relation (`many_to_one` field) to the `Author` model through the `author` field. The `Author` model itself also defines a relation to a `City` record through the `hometown` field.

Given this data model, we could easily retrieve `Article` records whose author's first name is "John" with the following query set:

```crystal
Article.filter(author__first_name: "John")
```

We could even retrieve all the `Article` records whose author are located in "Montréal" with the following query set:

```crystal
Article.filter(author__hometown__name: "Montreal")
```

And obviously, the above query sets could also be used along with more specific field predicate types. For example:

```crystal
Author.filter(author__hometown__name__startswith: "New")
```

When doing “deep filtering” like this, related model tables are automatically "joined" at the SQL level to perform the query (inner joins or left outer joins are used depending on the nullability of the filtered fields).

It is worth noting that this filtering capability also works for [many-to-many relationships](./relationships.md#many-to-many-relationships) and reverse relations. For example, assuming that the `Article` model defines a `tags` [many-to-many](./reference/fields.md#many_to_many) field towards a hypothetical `Tag` model, the following query would be possible:

```crystal
Article.filter(tags__label: "crystal")
```

### Pre-selecting relations with joins

It is also possible to explicitly define that a specific query set must "join" a set of relations. This can result in nice performance improvements since this can help reduce the number of SQL queries performed for a given codebase. This is achieved through the use of the `#join` method:

```crystal
author_1 = Author.filter(first_name: "John")
puts author_1.hometown # DB hit to retrieve the associated City record
 
author_2 = Author.join(:hometown).filter(first_name: "John")
puts author_2.hometown # No additional DB hit
```

The double underscores notations can also be used in the context of joins. For example:

```crystal
# The associated Author and City records will be selected and fully initialized 
# with the selected Article record.
Article.join(:author__hometown).get(id: 42)
```

:::info
Please note that the [`#join`](./reference/query-set.md#join) query set method can only be used on [many-to-one](./relationships.md#many-to-one-relationships) relationships, [one-to-one](./relationships.md#one-to-one-relationships) relationships, and reverse one-to-one relations.
:::

### Pagination

Marten provides a pagination mechanism that you can leverage in order to easily iterate over records that are split across several pages of data. This works as follows: each query set object lets you generate a "paginator" (instance of [`Marten::DB::Query::Paginator`](pathname:///api/dev/Marten/DB/Query/Paginator.html)) from a given page size (the number of records you would like on each page). You can then use this paginator in order to request specific pages, which gives you access to the corresponding records and to some additional pagination metadata.

For example:

```crystal
query_set = Article.filter(published: true)

paginator = query_set.paginator(10)
paginator.page_size   # => 10
paginator.pages_count # => 6

# Retrieve the first page and iterate over the underlying records
page = paginator.page(1)
page.each { |article| puts article }
page.number               # 1
page.previous_page?       # => false
page.previous_page_number # => nil
page.next_page?           # => true
page.next_page_number     # => 2
```

As you can see, paginator objects let you request specific pages by providing a page number (1-indexed!) to the [`#page`](pathname:///api/dev/Marten/DB/Query/Paginator.html#page(number%3AInt)-instance-method) method. Such pages are instances of [`Marten::DB::Query::Page`](pathname:///api/dev/Marten/DB/Query/Page.html) and give you the ability to easily iterate over the corresponding records. They also give you the ability to retrieve some pagination-related information (eg. about the previous and next pages by leveraging the [`#previous_page?`](pathname:///api/dev/Marten/DB/Query/Page.html#previous_page%3F-instance-method), [`#previous_page_number`](pathname:///api/dev/Marten/DB/Query/Page.html#previous_page_number-instance-method), [`#next_page?`](pathname:///api/dev/Marten/DB/Query/Page.html#next_page%3F-instance-method), and [`#next_page_number`](pathname:///api/dev/Marten/DB/Query/Page.html#next_page_number-instance-method) methods).

## Updating records

Once a model record has been retrieved from the database, it is possible to update it by modifying its attributes and calling the `#save` method (already mentioned previously):

```crystal
article = Article.get(id: 42)
article.title = "Updated!"
article.save
```

It is also possible to update records through the use of query sets. To do so, the `#update` method can be chained to a pre-defined query set in order to update all the resulting records:

```crystal
Article.filter(title: "My article").update(title: "Updated!")
```

When calling the `#update` method like in the previous example, the update is done at the SQL level (using a regular `UPDATE` SQL statement) and the method returns the number of impacted records. As such it's important to remember that records updated like this won't be instantiated or validated before the update, and that no callbacks will be executed for them.

## Deleting records

Single model records that have been retrieved from the database can be deleted by using the `#delete` method:

```crystal
article = Article.get(id: 42)
article.delete
```

Marten also provide the ability to delete the records that are targetted by a specific query set through the use of the `#delete` method, like in the following example:

```crystal
Article.filter(title: "My article").delete
```

By default, related objects that are associated with the deleted records will also be deleted by following the deletion strategy defined in each relation field (`on_delete` option, see the [reference](./reference/fields.md#on_delete) for more details). The method always returns the number of deleted records.
