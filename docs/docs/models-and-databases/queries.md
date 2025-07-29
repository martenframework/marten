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
  field :population, :int, null: true, blank: true
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
  field :subtitle, :string, max_size: 255, blank: true, null: true
  field :content, :text
  field :author, :many_to_one, to: Author, related: :articles
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

By default, filters involving multiple parameters like in the above examples always produce SQL queries whose parameters are "AND"ed together. More complex queries (eg. using AND, OR, XOR, or NOT conditions) can be achieved through the use of the `q` DSL (which is described in [Complex filters with `q` expressions](#complex-filters-with-q-expressions)), as outlined by the following examples:

```crystal
# Get Author records with either "Bob" or "Alice" as first name
Author.filter { q(first_name: "Bob") | q(first_name: "Alice") }

# Get Author records whose first names are not "John"
Author.filter { -q(first_name: "Alice") }
```

Marten also has the option to filter query sets using [raw SQL predicates](./raw-sql#filtering-with-raw-sql-predicates). This is useful when you want to leverage the flexibility of SQL for specific conditions, but still want Marten to handle the column selection and query building for the rest of the query. To use raw SQL predicates, can specify a string containing the predicate with optional parameters to the `#filter` query set method:

```crystal
Author.filter("first_name = :first_name", first_name: "John")
Author.filter("first_name = ?", "John")
Author.filter { q("first_name = :first_name", first_name: "John") }
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

A record can also be retrieved with a raw SQL predicate. For example:

```crystal
Author.get("id=?", 42)
Author.get("id=:id", id: 42)
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
* `^` in order to perform a logical "XOR"
* `-` in order to perform a logical negation

For example, the following snippet will return all the `Article` records whose title starts with "Top" or "10":

```crystal
Article.filter { q(title__startswith: "Top") | q(title__startswith: "10") }
```

Using this approach, it is possible to produce complex conditions by combining `q()` expressions with the `&`, `|`, `^`, and `-` operators. Parentheses can also be used to group statements:

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

It is also possible to explicitly define that a specific query set must "join" a set of relations. This can result in nice performance improvements since this can help reduce the number of SQL queries performed for a given codebase. This is achieved through the use of the [`#join`](./reference/query-set.md#join) method:

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

Finally, it is worth mentioning that many relations can be specified to [`#join`](./reference/query-set.md#join). For example:

```crystal
Article.join(:author__hometown, :edited_by)
```

:::info
Please note that the [`#join`](./reference/query-set.md#join) query set method can only be used on [many-to-one](./relationships.md#many-to-one-relationships) relationships, [one-to-one](./relationships.md#one-to-one-relationships) relationships, and reverse one-to-one relations. For multi-valued relations, please consider [pre-fetching records](#pre-fetching-relations).
:::

### Pre-fetching relations

While [pre-selecting relations with joins](#pre-selecting-relations-with-joins) can result in performance improvements (and help in reducing the number of SQL queries) by performing joins at the SQL level, is also possible to _pre-fetch relations_ using the [`#prefetch`](./reference/query-set.md#prefetch) method.

Both methods serve a common purpose, aiming to alleviate N+1 issues commonly encountered when accessing related objects. However, their strategies diverge in approach:

* When using [`#join`](./reference/query-set.md#join), the specified relationships are followed and each record returned by the considered query set has the corresponding related objects already selected and populated. The performance improvements are achieved by reducing the number of SQL queries since related records are retrieved by creating an SQL join and by including their fields in the main SELECT statement. Because of this, [`#join`](./reference/query-set.md#join) can only be used on single-valued relationships: [many-to-one](./relationships.md#many-to-one-relationships) relationships, [one-to-one](./relationships.md#one-to-one-relationships) relationships, and reverse one-to-one relations.
* When using [`#prefetch`](./reference/query-set.md#prefetch), the records corresponding to the specified relationships will be prefetched in single batches and each record returned by the original query set will have the corresponding related objects already selected and populated. As such, [`#prefetch`](./reference/query-set.md#prefetch) can be used with any kind of relationship: [many-to-one](./relationships.md#many-to-one-relationships) relationships, [one-to-one](./relationships.md#one-to-one-relationships) relationships, [many-to-many](./relationships.md#many-to-many-relationships) relationships, and all types of reverse relations.

For example, assuming that a `Post` model defines a `tags` many-to-many field:

```crystal
posts_1 = Post.all.to_a
# hits the database to retrieve the related "tags" (many-to-many relation)
puts posts_1[0].tags.to_a

posts_2 = Post.all.prefetch(:tags).to_a
# doesn't hit the database since the related "tags" relation was already prefetched
puts posts_2[0].tags.to_a
```

The double underscores notations can also be used when pre-fetching relations. In this situation, the records targeted by the original query set will be decorated with the prefetched records, and those records will be decorated with the following prefetched records. For example:

```crystal
# The associated Book and BookGenres records will be pre-fetched and fully initialized
# at the Author and Book records levels.
Author.prefetch(:books__genres)
```

Finally, it is worth mentioning that multiple relations can be specified to [`#prefetch`](./reference/query-set.md#prefetch). For example:

```crystal
Author.prefetch(:books__genres, :publisher)
```

### Pagination

Marten provides a pagination mechanism that you can leverage in order to easily iterate over records that are split across several pages of data. This works as follows: each query set object lets you generate a "paginator" (instance of [`Marten::DB::Query::Paginator`](pathname:///api/dev/Marten/DB/Query/Paginator.html)) from a given page size (the number of records you would like on each page). You can then use this paginator in order to request specific pages, which gives you access to the corresponding records and to some additional pagination metadata.

For example:

```crystal
query_set = Article.filter(published: true)

paginator = query_set.paginator(10)
paginator.page_size   # => 10
paginator.pages_count # => 6
paginator.total_count # => 60

# Retrieve the first page and iterate over the underlying records
page = paginator.page(1)
page.each { |article| puts article }
page.number               # 1
page.previous_page?       # => false
page.previous_page_number # => nil
page.next_page?           # => true
page.next_page_number     # => 2
page.total_count          # => 60
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

## Scopes

Scopes allow for the pre-definition of specific filtered query sets, which can be easily applied to model classes and model query sets. When defining such scopes, all the query set capabilities that were covered previously (such as [filtering records](#filtering-specific-records), [excluding records](#excluding-specific-records), etc) can be leveraged.

### Defining scopes

Scopes can be defined through the use of the [`#scope`](pathname:///api/dev/Marten/DB/Model/Querying.html#scope(name%2C%26block)-macro) macro. This macro expects a scope name (string literal or symbol) as first argument and requires a block where the query set filtering logic is defined.

For example:

```crystal
class Post < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :is_published, :bool, default: false
  field :created_at, :date_time

  // highlight-next-line
  scope :published { filter(is_published: true) }
  // highlight-next-line
  scope :unpublished { filter(is_published: false) }
  // highlight-next-line
  scope :recent { filter(created_at__gt: 1.year.ago) }
end
```

Considering the above model definition, it is possible to get published posts by using the following method call:

```crystal
Post.published # => Post::QuerySet [...]>
```

Similarly, retrieving all published posts from a query set object can be accomplished by calling the `#published` method on the query set object:

```crystal
query_set = Post.all
query_set.published # => Post::QuerySet [...]>
```

Because of this capability, it is important to note that scopes can technically be chained. For example, the following snippet will return all the published posts that were created less than one year ago:

```crystal
Post.published.recent # => Post::QuerySet [...]>
```

### Defining scopes with arguments

If needed, you can define scopes that require arguments. To accomplish this, simply include the required arguments within the scope block.

For example:

```crystal
class Post < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :author, :many_to_one, to: Author

  // highlight-next-line
  scope :by_author_id { |author_id| filter(author_id: author_id) }
end
```

Scopes that require arguments can be used in the same way as argument-free scopes; they can be called on model classes or model query sets:

```crystal
Post.by_author_id(42)      # => Post::QuerySet [...]>

query_set = Post.all
query_set.by_author_id(42) # => Post::QuerySet [...]>
```

### Defining default scopes

By default, querying all model records returns unfiltered query sets. However, you can define a default scope to automatically apply a specific filter to all queries for that model. This ensures that certain criteria are consistently enforced without the need to explicitly include a specific filter in every query.

Default scopes can be defined through the use of the [`#default_scope`](pathname:///api/dev/Marten/DB/Model/Querying.html#default_scope-macro) macro. This macro requires a block where the query set filtering logic is defined.

For example:

```crystal
class Post < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :is_published, :bool, default: false
  field :created_at, :date_time

  // highlight-next-line
  default_scope { filter(is_published: true) }
end
```

### Disabling scoping

It is worth mentioning that unscoped model records are always accessible through the use of the [`#unscoped`](pathname:///api/dev/Marten/DB/Model/Querying/ClassMethods.html#unscoped-instance-method) class method. This is especially useful if your model defines a default scope and you need to override it for certain queries.

For example:

```crystal
class Post < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :is_published, :bool, default: false
  field :created_at, :date_time

  // highlight-next-line
  default_scope { filter(is_published: true) }
end
```

Considering, the above model definition, you can retrieve all the `Post` records by bypassing the default scope with:

```crystal
Post.unscoped # => Post::QuerySet [...]>
```

## Aggregations

The previous sections have covered the ways to filter and order model records. However, there are times when you need to retrieve calculated values that summarize or aggregate collections of objects. This section describes how to generate and return aggregate values using Marten's query API.

When considering aggregations, we can usually consider two main use cases:

* Returning a single calculated value from a given query set.
* Annotating a query set with additional aggregated data that can be filtered on and that is made available for each record in the query set.

### Returning a single aggregated value

#### Counting objects

The most basic aggregation is counting the number of objects in a query set. This can be done by using the [`#count`](./reference/query-set.md#count) method.

For example:

```crystal
Article.all.count                              # returns the number of article records
Article.all.count(:subtitle)                   # returns the number of articles where the subtitle is not null
Article.filter(title__startswith: "Top").count # returns the number of articles whose title start with "Top"
```

#### Summing values

The [`#sum`](./reference/query-set.md#sum) method returns the sum of the values of a given model field.

For example:

```crystal
City.all.sum(:population) # returns the sum of the population values of all cities
```

#### Calculating averages

The [`#average`](./reference/query-set.md#average) method returns the average of the values of a given model field.

For example:

```crystal
City.all.average(:population) # returns the average of the population values of all cities
```

#### Calculating minimum and maximum values

The [`#minimum`](./reference/query-set.md#minimum) and [`#maximum`](./reference/query-set.md#maximum) methods return the minimum and maximum values of a given model field across a query set, respectively.

For example:

```crystal
City.all.minimum(:population) # returns the minimum population value of all cities
City.all.maximum(:population) # returns the maximum population value of all cities
```

### Annotating query sets with aggregated data

The previous sections have covered the ways to retrieve a single aggregated value from a given query set. However, sometimes you will need to "retain" the aggregated values for each record in the query set (possibly for further filtering or for making use of the aggregated values when dealing with individual records). This can be achieved by using the [`#annotate`](./reference/query-set.md#annotate) method.

This method requires the use of a block that will be used to define the aggregated value for each record in the query set. For example:

```crystal
query_set = Author.all.annotate { count(:articles) }
```

All the types of aggregation methods covered previously can be used within the block. For example:

| Aggregation method | Description |
|---------------------|-------------|
| `count` | Counts the number of records |
| `sum` | Returns the sum of the values of a given field |
| `average` | Returns the average of the values of a given field |
| `minimum` | Returns the minimum value of a given field |
| `maximum` | Returns the maximum value of a given field |

For example:

```crystal
Author.all.annotate { count(:articles) }
Author.all.annotate { sum(:articles__score) }
Author.all.annotate { average(:articles__score) }
Author.all.annotate { minimum(:articles__score) }
Author.all.annotate { maximum(:articles__score) }
```

#### Accessing annotated values

Once an annotated query set has been retrieved, it is possible to access the annotated values for each record by using the [`#annotations`](pathname:///api/dev/Marten/DB/Model.html#annotations%3AHash(String%2CBool|File|Float32|Float64|Int32|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3ADB%3A%3AField%3A%3AFile%3A%3AFile|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Symbol|Time|Time%3A%3ASpan|UUID|Nil)-instance-method) method. This method returns a hash where the keys are the names of the annotated fields and the values are the annotated values.

For example:

```crystal
annotated_query_set = Author.all.annotate { count(:articles) }
annotated_query_set.each do |author|
  puts author.annotations["articles_count"]
end
```

It is worth mentioning that the annotation names are generated by concatenating the field or relation name with the annotation type. For example, the annotation name for the `count` annotation on the `articles` reverse relation is `articles_count`, unless [an alias name is specified](#specifying-an-alias-name-for-an-annotation).

#### Specifying multiple annotations

It is also possible to specify multiple annotations at once when using the [`#annotate`](./reference/query-set.md#annotate) method. This can be achieved by calling the method multiple times or by defining the block over multiple lines.

For example, the following two query sets are equivalent:

```crystal
query_set_1 = Author.all
  .annotate { count(:articles) }
  .annotate { sum(:articles__score) }

query_set_2 = Article.all.annotate do
  count(:articles)
  sum(:articles__score)
end
```

#### Specifying an alias name for an annotation

It is also possible to specify an alias name for an annotation by using the [`#as`](./reference/query-set.md#as) method. This can be achieved by calling the annotation method with the alias name specified with the `alias_name` argument or by calling the `#alias` method on the annotation object itself.

For example, the following two query sets are equivalent:

```crystal
query_set_1 = Author.all.annotate { count(:articles, alias_name: :my_ann) }
query_set_2 = Author.all.annotate { count(:articles).alias(:my_ann) }
```

In the previous examples, the annotation value will be available under the `my_ann` key instead of the default `articles_count` one when [accessing the annotated values](#accessing-annotated-values).

#### Computing distinct annotations

It is also possible to compute distinct annotations by specifying the `distinct: true` argument to the annotation method or by calling the `#distinct` method on the annotation object itself.

For example, the following two query sets are equivalent:

```crystal
query_set_1 = Author.all.annotate { sum(:articles__score, distinct: true) }
query_set_2 = Author.all.annotate { sum(:articles__score).distinct }
```

In the previous examples, the annotation value will be computed by summing the distinct values of the `score` field.

#### Ordering by annotated values

It is possible to order the records of a query set by an annotated value by using the [`#order`](./reference/query-set.md#order) method. To do so, you can simply specify the aliases of the annotated values you want to order by.

For example:

```crystal
Author.all.annotate { count(:articles) }.order(:articles_count)
Author.all.annotate { count(:articles) }.order("-articles_count")
```

#### Filtering on annotated values

To filter on annotated values, you can use the [`#filter`](./reference/query-set.md#filter) method and use the aliases of the annotated values you want to filter on.

For example:

```crystal
Author.all.annotate { count(:articles) }.filter(articles_count__gt: 10)
Author
  .filter(first_name: "John")
  .annotate { count(:articles) }
  .filter(articles_count__gt: 10)
```

:::warning
Filtering on annotated values is an experimental feature. All database backends supported by Marten allow filtering on annotated values as long as those filters are applied separately from filters targeting other fields.

If you want to combine filters in a single `#filter` call that targets both annotated values and other fields, you should note that this is only supported by the PostgreSQL and SQLite backends at the moment.
:::
