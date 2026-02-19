---
title: Query set
description: Query set reference.
---

This page provides a reference for all the query set methods and available predicates that can be leveraged when filtering model records.

## Query set laziness

Query sets are **lazily evaluated**: defining a query set will usually not involve any database operations. Additionally, most methods provided by query sets also return new query set objects. Query sets are only translated to SQL queries hitting the underlying database when records need to be extracted or manipulated by the considered codebase.

For example:

```crystal
qset = Article.filter(title__startswith: "Top") # the query set is not evaluated
qset = qset.filter(author__first_name: "John")  # the query set is not evaluated
puts qset                                       # the query set is evaluated
```

In the above example the two filters are simply chained without these resulting in database hits. The query set is only evaluated when the actual records need to be printed.

Overall, query sets are evaluated in the following situations:

* when iterating over the underlying records (eg. when using `#each`)

  ```crystal
  Article.filter(title__startswith: "Top").each do |article|
    puts article
  end
  ```

* when retrieving the records for a specific range

  ```crystal
  Article.filter(title__startswith: "Top")[4..10]
  ```

* when printing the query set object (eg. using `puts`)

## Methods that return new query sets

Query sets provide a set of methods that allow to generate other (possibly filtered) query sets. Calling these methods won't result in the query set to be evaluated.

### `[](range)`

Returns the records corresponding to the passed range.

If no records match the passed range, an `IndexError` exception is raised. If the current query set was already evaluated (records were retrieved from the database), an array of records will be returned. Otherwise, another sliced query set will be returned:

```crystal
qset_1 = Article.all
qset_1.each { }
qset_1[2..6] # returns an array of Article records

qset_2 = Article.all
qset_2[2..6] # returns a "sliced" query set
```

### `[]?(range)`

Returns the records corresponding to the passed range.

`nil` is returned if no records match the passed range. If the current query set was already evaluated (records were retrieved from the database), an array of records will be returned. Otherwise, another sliced query set will be returned:

```crystal
qset_1 = Article.all
qset_1.each { }
qset_1[2..6]? # returns an array of Article records

qset_2 = Article.all
qset_2[2..6]? # returns a "sliced" query set
```

### `&` (AND)

Combines the current query set with another one using the **AND** operator.

This method returns a new query set that is the result of combining the current query set with another one using the AND SQL operator.

For example:

```crystal
query_set_1 = Post.all.filter(title: "Test")
query_set_2 = Post.all.filter(is_published: true)

combined_query_set = query_set_1 & query_set_2
```

### `|` (OR)

Combines the current query set with another one using the **OR** operator.

This method returns a new query set that is the result of combining the current query set with another one using the OR SQL operator.

For example:

```crystal
query_set_1 = Post.all.filter(title: "Test")
query_set_2 = Post.all.filter(is_published: true)

combined_query_set = query_set_1 | query_set_2
```

### `^` (XOR)

Combines the current query set with another one using the **XOR** operator.

This method returns a new query set that is the result of combining the current query set with another one using the XOR SQL operator.

For example:

```crystal
query_set_1 = Post.all.filter(title: "Test")
query_set_2 = Post.all.filter(is_published: true)

combined_query_set = query_set_1 ^ query_set_2
```

:::info
XOR is natively support on MariaDB and MySQL only. Other database backends (PostgreSQL and SQLite) will use `case ... when` statements in order to perform XOR operations at the SQL level.
:::

### `all`

Allows retrieving all the records of a specific model. `#all` can be used as a class method from any model class, or it can be used as an instance method from any query set object. In this last case, calling `#all` returns a copy of the current query set.

For example:

```crystal
qset = Article.all # returns a query set matching "all" the records of the Article model
qset2 = qset.all   # returns a copy of the initial query set
```

### `annotate`

Returns a new query set that will include the specified annotations.

This method returns a new query set with the specified annotations. The annotations are specified using a block where each annotation has to be wrapped using the `#annotate` method. For example:

```crystal
query_set = Book.all.annotate { count(:authors) }
other_query_set = Book.all.annotate do
  count(:authors, alias_name: :author_count)
  sum(:pages, alias_name: :total_pages)
end
```

Each of the specified annotations is then available for further use in the query set (in order to filter or order the records). The annotations are also available in retrieved model records via the [`#annotations`](pathname:///api/dev/Marten/DB/Model.html#annotations%3AHash(String%2CBool|File|Float32|Float64|Int32|Int64|JSON%3A%3AAny|JSON%3A%3ASerializable|Marten%3A%3ADB%3A%3AField%3A%3AFile%3A%3AFile|Marten%3A%3AHTTP%3A%3AUploadedFile|String|Symbol|Time|Time%3A%3ASpan|UUID|Nil)-instance-method) method, which returns a hash containing the annotations as keys and their values as values.

Those are the supported annotation types:

| Aggregation method | Description |
|---------------------|-------------|
| `count` | Counts the number of records |
| `sum` | Returns the sum of the values of a given field |
| `average` | Returns the average of the values of a given field |
| `minimum` | Returns the minimum value of a given field |
| `maximum` | Returns the maximum value of a given field |

Please refer to the [Annotating query sets with aggregated data](../queries.md#annotating-query-sets-with-aggregated-data) section to learn more about using annotations.

### `distinct`

Returns a new query set that will use `SELECT DISTINCT` or `SELECT DISTINCT ON` in its SQL query.

If you use this method without arguments, a `SELECT DISTINCT` statement will be used at the database level. If you pass field names as arguments, a `SELECT DISTINCT ON` statement will be used to eliminate any duplicated rows based on the specified fields:

```crystal
query_set_1 = Post.all.distinct
query_set_2 = Post.all.distinct(:title)
```

It should be noted that it is also possible to follow associations of direct related models too by using the [double underscores notation](../queries.md#filtering-relations) (`__`). For example the following query will select distinct records based on a joined "author" attribute:

```
query_set = Post.all.distinct(:author__name)
```

Finally, it should be noted that `#distinct` cannot be used on [sliced query sets](#range).

### `exclude`

Returns a query set whose records do not match the given set of filters.

The filters passed to this method method can be specified using the [standard predicate format](../queries.md#basic-querying-capabilities). If multiple filters are specified, they will be joined using an **AND** operator at the SQL level:

```crystal
query_set = Post.all
query_set.exclude(title: "Test")
query_set.exclude(title__startswith: "A")
```

Complex filters can also be used as part of this method by leveraging [`q` expressions](../queries.md#complex-filters-with-q-expressions):

```crystal
query_set = Post.all
query_set.exclude { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
```

### `filter`

Returns a query set matching a specific set of filters.

The filters passed to this method method can be specified using the [standard predicate format](../queries.md#basic-querying-capabilities). If multiple filters are specified, they will be joined using an **AND** operator at the SQL level:

```crystal
query_set = Post.all
query_set.filter(title: "Test")
query_set.filter(title__startswith: "A")
```

Complex filters can also be used as part of this method by leveraging [`q` expressions](../queries.md#complex-filters-with-q-expressions):

```crystal
query_set = Post.all
query_set.filter { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
```

### `join`

Returns a queryset whose specified `relations` are "followed" and joined to each result (see [Queries](../queries.md#filtering-relations) for an introduction about this capability).

When using `#join`, the specified relationships will be followed and each record returned by the queryset will have the corresponding related objects already selected and populated. Using `#join` can result in performance improvements since it can help reduce the number of SQL queries, as illustrated by the following example:

```crystal
query_set = Post.all

p1 = query_set.get(id: 1)
puts p1.author # hits the database to retrieve the related "author"

p2 = query_set.join(:author).get(id: 1)
puts p2.author # doesn't hit the database since the related "author" was already selected
```

It should be noted that it is also possible to follow foreign keys of direct related models too by using the double underscores notation (`__`). For example, the following query will select the joined "author" and its associated "profile":

```crystal
query_set = Post.all
query_set.join(:author__profile)
```

:::info
The `#join` method also supports targeting the reverse relation of a [`one_to_one`](./fields.md#one_to_one) field (such reverse relation can be defined through the use of the [`related`](./fields.md#related-2) field option). That way, you can traverse a [`one_to_one`](./fields.md#one_to_one) field back to the model record on which the field is specified.
:::

### `limit`

Returns a query set that will limit the number of records returned.

This method allows to specify the maximum number of records to return. For example:

```crystal
query_set = Post.all.limit(10)
```

In the above example, only the first 10 records will be returned.

### `none`

Returns a query set that will always return an empty array of records, without querying the database.

Once this method is used, any subsequent method calls (such as extra filters) will continue returning an empty array of records:

```crystal
query_set = Post.all
query_set.none.exists? # => false
```

### `offset`

Returns a query set that will offset the records returned.

This method allows to specify the starting point for the records to return. For example:

```crystal
query_set = Post.all.offset(10)
```

In the above example, the records will be returned starting from the 10th record.

### `order`

Allows specifying the ordering in which records should be returned when evaluating the query set.

Multiple fields can be specified in order to define the final ordering. For example:

```crystal
query_set = Post.all
query_set.order("-published_at", "title")
```

In the above example, records would be ordered by descending publication date (because of the `-` prefix), and then by title (ascending).

### `prefetch`

Returns a query set that will automatically prefetch in a single batch the records for the specified relations (see [Queries](../queries.md#pre-fetching-relations) for an introduction about this capability).

When using `#prefetch`, the records corresponding to the specified relationships will be prefetched in single batches and each record returned by the query set will have the corresponding related objects already selected and populated. Using `#prefetch` can result in performance improvements since it can help reduce the number of SQL queries, as illustrated by the following example:

```crystal
posts_1 = Post.all.to_a
# hits the database to retrieve the related "tags" (many-to-many relation)
puts posts_1[0].tags.to_a

posts_2 = Post.all.prefetch(:tags).to_a
# doesn't hit the database since the related "tags" relation was already prefetched
puts posts_2[0].tags
```

It should be noted that it is also possible to follow relations and reverse relations too by using the double underscores notation(`__`). For example, the following query will prefetch the "author" relation and then the "favorite tags" relation of the author records:

```crystal
query_set = Post.all
query_set.prefetch(:author__favorite_tags)
```

In some situations, it might be necessary to use a custom query set for the prefetched records. This is possible by using a variant of the `#prefetch` method in which a single relation name and the associated query set (`query_set` argument) are provided:

```crystal
# Query all lists and order the list items by position
query_set = List.prefetch(:items, query_set: Item.order(:position))
```

Finally, it is worth mentioning that multiple relations can be specified to `#prefetch`. For example:

```crystal
Author.all.prefetch(:books__genres, :publisher)
```

:::tip
The `#prefetch` method can also be called directly on model classes:

```crystal
Author.prefetch(:books__genres, :publisher)
```
:::

### `raw`

Returns a raw query set for the passed SQL query and optional parameters.

This method returns a [`Marten::DB::Query::RawSet`](pathname:///api/dev/Marten/DB/Query/RawSet.html) object, which allows to iterate over the model records matched by the passed SQL query. For example:

```crystal
Article.all.raw("SELECT * FROM articles")
```

Additional parameters can also be specified if the query needs to be parameterized. Those can be specified as positional or named arguments. For example:

```crystal
# Using splat positional parameters:
Article.all.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", "Hello World!", "2022-10-30")

# Using an array of positional parameters:
Article.all.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", ["Hello World!", "2022-10-30"])

# Using double splat named parameters:
Article.all.raw(
  "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
  title: "Hello World!",
  created_at: "2022-10-30"
)

# Using a hash of named parameters:
Article.all.raw(
  "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
  {
    title:      "Hello World!",
    created_at: "2022-10-30",
  }
)
```

Please refer to [Raw SQL](../raw-sql.md) to learn more about performing raw SQL queries.

### `reverse`

Allows reversing the order of the current query set.

For example, this would return all the `Article` records ordered by descending title:

```crystal
query_set = Article.all.order(:title)
query_set.reverse
```

### `using`

Allows defining which database alias should be used when evaluating the query set.

For example:

```crystal
query_set_1 = Article.all.filter(published: true)               # records are retrieved from the default database
query_set_2 = Article.all.filter(published: true).using(:other) # records are retrieved from the "other" database
```

The value passed to `#using` must be a valid database alias that was used to configure an additional database as part of the [database settings](../../development/reference/settings.md#database-settings).

## Methods that do not return new query sets

Query sets also provide a set of methods that will usually result in specific SQL queries to be executed in order to return values that don't correspond to new query sets.

### `average`

Allows calculating the average of a numeric field within the records of a specific model. The `#average` method can be used as a class method from any model class, or it can be used as an instance method from any query set object. When used on a query set, it calculates the average of the specified field for the records in that query set.

For example:

```crystal
average_price = Product.average(:price) # Calculate the average price of all products

# Calculate the average rating for a specific category of products
electronic_products = Product.filter(category: "Electronics")
average_rating = electronic_products.average(:rating)
```

### `build`

Initializes a new model instance.

This method allows initializing a new model instance using the arguments defined in the passed double splat argument.

```crystal
new_post = Post.all.build(title: "My blog post")
```

This method can also be called with a block that is executed for the new object:

```crystal
new_post = Post.all.build(title: "My blog post") do |p|
  p.complex_attribute = compute_complex_attribute
end
```

### `bulk_create`

Bulk inserts the passed model instances into the database.

This method allows to insert multiple model instances into the database in a single query. This can be useful when dealing with large amounts of data that need to be inserted into the database. For example:

```crystal
query_set = Post.all
query_set.bulk_create(
  [
    Post.new(title: "First post"),
    Post.new(title: "Second post"),
    Post.new(title: "Third post"),
  ]
)
```

An optional `batch_size` argument can be passed to this method in order to specify the number of records that should be inserted in a single query. By default, all records are inserted in a single query (except for SQLite databases where the limit of variables in a single query is 999). For example:

```crystal
query_set = Post.all
query_set.bulk_create(
  [
    Post.new(title: "First post"),
    Post.new(title: "Second post"),
    Post.new(title: "Third post"),
  ],
  batch_size: 2
)
```

:::tip
The `#bulk_create` method can also be called directly on model classes:

```crystal
Post.bulk_create(
  [
    Post.new(title: "First post"),
    Post.new(title: "Second post"),
    Post.new(title: "Third post"),
  ]
)
```
:::

It is worth mentioning that this method has a few caveats:

* The specified records are assumed to be valid and no [callbacks](../callbacks.md) will be called on them.
* Bulk-creating records making use of multi-table inheritance is not supported.
* If the model's primary key field is auto-incremented at the database level, the newly inserted primary keys will only be assigned to records on certain databases that support retrieving bulk-inserted rows (namely MariaDB, PostgreSQL, and SQLite).

### `count`

Returns the number of records that are targeted by the current query set.

For example:

```crystal
Article.all.count                              # returns the number of article records
Article.all.count(:subtitle)                   # returns the number of articles where the subtitle is not null
Article.filter(title__startswith: "Top").count # returns the number of articles whose title start with "Top"
```

Note that this method will trigger a `SELECT COUNT` SQL query if the query set was not already evaluated: when this happens, no model records will be instantiated since the records count will be determined at the database level. If the query set was already evaluated, the underlying array of records will be used to return the records count instead of running a dedicated SQL query.

### `create`

Creates a model instance and saves it to the database if it is valid.

The new model instance is initialized by using the attributes defined in the passed double splat argument. Regardless of whether it is valid or not (and thus persisted to the database or not), the initialized model instance is returned by this method:

```crystal
query_set = Post.all
query_set.create(title: "My blog post")
```

This method can also be called with a block that is executed for the new object. This block can be used to directly initialize the object before it is persisted to the database:

```crystal
query_set = Post.all
query_set.create(title: "My blog post") do |post|
  post.complex_attribute = compute_complex_attribute
end
```

### `create!`

Creates a model instance and saves it to the database if it is valid.

The model instance is initialized using the attributes defined in the passed double splat argument. If the model instance is valid, it is persisted to the database ; otherwise a `Marten::DB::Errors::InvalidRecord` exception is raised.

```crystal
query_set = Post.all
query_set.create!(title: "My blog post")
```

This method can also be called with a block that is executed for the new object. This block can be used to directly initialize the object before it is persisted to the database:

```crystal
query_set = Post.all
query_set.create!(title: "My blog post") do |post|
  post.complex_attribute = compute_complex_attribute
end
```

### `delete`

Deletes the records corresponding to the current query set and returns the number of deleted records.

By default, related objects will be deleted by following the [deletion strategy](./fields.md#on_delete) defined in each foreign key field if applicable, unless the `raw` argument is set to `true`. When the `raw` argument is set to `true`, a raw SQL delete statement will be used to delete all the records matching the currently applied filters. Note that using this option could cause errors if the underlying database enforces referential integrity.

```crystal
Article.all.delete                              # deletes all the Article records
Article.filter(title__startswith: "Top").delete # deletes all the articles whose title start with "Top"
```

### `each`

Allows iterating over the records that are targeted by the current query set.

This method can be used to define a block that iterates over the records that are targeted by a query set:

```crystal
Post.all.each do |post|
  # Do something with the post
end
```

### `exists?`

Returns `true` if the current query set matches at least one record, or `false` otherwise.

```crystal
Article.filter(title__startswith: "Top").exists?
```

Note that this method will trigger a very simple `SELECT EXISTS` SQL query if the query set was not already evaluated: when this happens, no model records will be instantiated since the records existence will be determined at the database level. If the query set was already evaluated, the underlying array of records will be used to determine if records exist or not.

It should be noted that `#exists?` can also take additional filters or `q()` expressions as arguments. This allows to apply additional filters to the considered query set in order to perform the check. For example:

```crystal
query_set = Tag.filter(name__startswith: "c")
query_set.exists?(is_active: true)
query_set.exists? { q(is_active: true) }
```

### `first`

Returns the first record that is matched by the query set, or `nil` if no records are found.

```crystal
Article.first
Article.filter(title__startswith: "Top").first
```

### `first!`

Returns the first record that is matched by the query set, or raises a `NilAssertionError` exception if no records are found.

```crystal
Article.first!
Article.filter(title__startswith: "Top").first!
```

### `get`

Returns the model instance matching the given set of filters.

Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve a specific record:

```crystal
query_set = Post.all
post_1 = query_set.get(id: 123)
post_2 = query_set.get(id: 456, is_published: false)
```

Complex filters can also be used as part of this method by leveraging [`q` expressions](../queries.md#complex-filters-with-q-expressions):

```crystal
query_set = Post.all
post_1 = query_set.get { q(id: 123) }
post_2 = query_set.get { q(id: 456, is_published: false) }
```

If the specified set of filters doesn't match any records, the returned value will be `nil`. Moreover, in order to ensure data consistency this method will raise a `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.

Note that `#get` can be used to retrieve a record with a raw SQL predicate. For example:

```crystal
Author.get("id=?", 42)
Author.get("id=:id", id: 42)
```

### `get!`

Returns the model instance matching the given set of filters.

Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve a specific record:

```crystal
query_set = Post.all
post_1 = query_set.get!(id: 123)
post_2 = query_set.get!(id: 456, is_published: false)
```

Complex filters can also be used as part of this method by leveraging [`q` expressions](../queries.md#complex-filters-with-q-expressions):

```crystal
query_set = Post.all
post_1 = query_set.get! { q(id: 123) }
post_2 = query_set.get! { q(id: 456, is_published: false) }
```

If the specified set of filters doesn't match any records, a `Marten::DB::Errors::RecordNotFound` exception will be raised. Moreover, in order to ensure data consistency this method will raise a `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.

Note that `#get` can be used to retrieve a record with a raw SQL predicate. For example:

```crystal
Author.get!("id=?", 42)
Author.get!("id=:id", id: 42)
```

### `get_or_create`

Returns the model record matching the given set of filters or create a new one if no one is found.

Model fields that uniquely identify a record should be used here. For example:

```crystal
tag = Tag.all.get_or_create(label: "crystal")
```

When no record is found, the new model instance is initialized by using the attributes defined in the double splat arguments. Regardless of whether it is valid or not (and thus persisted to the database or not), the initialized model instance is returned by this method.

This method can also be called with a block that is executed for new objects. This block can be used to directly initialize new records before they are persisted to the database:

```crystal
tag = Tag.all.get_or_create(label: "crystal") do |new_tag|
  new_tag.active = false
end
```

In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.

### `get_or_create!`

Returns the model record matching the given set of filters or create a new one if no one is found.

Model fields that uniquely identify a record should be used here. For example:

```crystall
tag = Tag.all.get_or_create!(label: "crystal")
```

When no record is found, the new model instance is initialized by using the attributes defined in the double splat arguments. If the new model instance is valid, it is persisted to the database ; otherwise a `Marten::DB::Errors::InvalidRecord` exception is raised.

This method can also be called with a block that is executed for new objects. This block can be used to directly initialize new records before they are persisted to the database:

```crystal
tag = Tag.all.get_or_create!(label: "crystal") do |new_tag|
  new_tag.active = false
end
```

In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.

### `includes?`

Returns `true` if a specific model record is included in the query set.

This method can be used to verify the membership of a specific model record in a given query set. If the query set is not evaluated yet, a dedicated SQL query will be executed in order to perform this check (without loading the entire list of records that are targeted by the query set). This is especially interesting for large query sets where we don't want all the records to be loaded in memory in order to perform such check.

```crystal
tag = Tag.get!(name: "crystal")
query_set = Tag.filter(name__startswith: "c")
query_set.includes?(tag) # => true
```

### `last`

Returns the last record that is matched by the query set, or `nil` if no records are found.

```crystal
Article.last
Article.filter(title__startswith: "Top").last
```

### `last!`

Returns the last record that is matched by the query set, or raises a `NilAssertionError` exception if no records are found.

```crystal
Article.last!
Article.filter(title__startswith: "Top").last!
```

### `maximum`

Retrieves the maximum value in a specific field across all records within a query set.

```crystal
Product.all.maximum(:price)  # Retrieves the highest price across all products
# => 125.25
```

### `minimum`

Retrieves the minimum value in a specific field across all records within a query set.

```crystal
Product.all.minimum(:price)  # Retrieves the lowest price across all products
# => 15.99
```

### `paginator`

Returns a paginator that can be used to paginate the current query set.

This method returns a [`Marten::DB::Query::Paginator`](pathname:///Marten/DB/Query/Paginator.html) object, which can then be used to retrieve specific pages. A page size must be specified when calling this method.

For example:

```crystal
query_set = Article.all
paginator = query_set.paginator(10)
paginator.page(1) # Returns the first page of records
```

### `pick`

Returns specific column values for a single record without actually loading it.

This method allows to easily select specific column values for a single record from the current query set. This allows retrieving specific column values without actually loading the entire record, and as such this is most useful for query sets that have been narrowed down to match a single record. The method returns an array containing the requested column values, or `nil` if no record was matched by the current query set.

For example:

```crystal
Post.filter(pk: 1).pick("title", "published")
# => ["First article", true]
```

### `pick!`

Returns specific column values for a single record without actually loading it.

This method allows to easily select specific column values for a single record from the current query set. This allows retrieving specific column values without actually loading the entire record, and as such this is most useful for query sets that have been narrowed down to match a single record. The method returns an array containing the requested column values, or raises `NilAssertionError` if no record was matched by the current query set.

For example:

```crystal
Post.filter(pk: 1).pick!("title", "published")
# => ["First article", true]
```

### `pks`

Returns the primary key values of the considered model records targeted by the current query set.

This method returns an array containing the primary key values of the model records that are targeted by the current query set.

For example:

```crystal
Post.all.pks # => [1, 2, 3]
```

### `pluck`

Returns specific column values without loading entire record objects.

This method allows to easily select specific column values from the current query set. This allows retrieving specific column values without actually loading entire records. The method returns an array containing one array with the actual column values for each record targeted by the query set.

For example:

```crystal
Post.all.pluck("title", "published")
# => [["First article", true], ["Upcoming article", false]]
```

### `size`

Alias for [`#count`](#count): returns the number of records that are targeted by the query set.

### `sum`

Calculates the total sum of values in a specific field across all records within a query set.

Example:

```crystal
Order.all.sum(:amount)  # Calculates the total amount across all orders
# => 7
```

### `to_s`

Returns a string representation of the considered query set.

### `to_sql`

Returns the SQL representation of the considered query set.

For example:

```crystal
Tag.filter(name__startswith: "r").to_sql
# => "SELECT app_tag.id, app_tag.name, app_tag.is_active FROM \"app_tag\" WHERE app_tag.name LIKE $1"
```

:::note
The outputted SQL will vary depending on the database backend in use.
:::

### `update`

Updates all the records matched by the current query set with the passed values.

This method allows to update all the records that are matched by the current query set with the values defined in the passed double splat argument. It returns the number of records that were updated:

```crystal
query_set = Post.all
query_set.update(title: "Updated") # => 42
```

It should be noted that this method results in a regular `UPDATE` SQL statement. As such, the records that are updated through the use of this method won't be instantiated nor validated, and no callbacks will be executed for them either.

## Field predicates

Below are listed all the available [field predicates](../queries.md#field-predicates) that can be used when filtering query sets.

### `contains`

Allows filtering records based on field values that contain a specific substring. Note that this is a **case-sensitive** predicate.

```crystal
Article.all.filter(title__contains: "tech")
```

### `endswith`

Allows filtering records based on field values that end with a specific substring. Note that this is a **case-sensitive** predicate.

```crystal
Article.all.filter(title__endswith: "travel")
```

### `exact`

Allows filtering records based on a specific field value (exact match). Note that providing a `nil` value will result in a `IS NULL` check at the SQL level.

This is the default predicate; as such it is not necessary to specify it when filtering records. The following two query sets are equivalent:

```crystal
Article.all.filter(published: true)
Article.all.filter(published__exact: true)
```

### `gte`

Allows filtering records based on field values that are greater than or equal to a specified value.

```crystal
Article.all.filter(rating__gte: 10)
```

### `gt`

Allows filtering records based on field values that are greater than a specified value.

```crystal
Article.all.filter(rating__gt: 10)
```

### `icontains`

Allows filtering records based on field values that contain a specific substring, in a case-insensitive way.

```crystal
Article.all.filter(title__icontains: "tech")
```

### `iendswith`

Allows filtering records based on field values that end with a specific substring, in a case-insensitive way.

```crystal
Article.all.filter(title__iendswith: "travel")
```

### `iexact`

Allows filtering records based on a specific field value (exact match), in a case-insensitive way.

```crystal
Article.all.filter(title__iexact: "Top blog posts")
```

### `istartswith`

Allows filtering records based on field values that start with a specific substring, in a case-insensitive way.

```crystal
Article.all.filter(title__istartswith: "top")
```

### `in`

Allows filtering records based on field values that are contained in a specific array of values.

```crystal
Tag.all.filter(slug__in=["foo", "bar", "xyz"])
```

Note that this predicate can also be used for filtering relation fields (such as [`many_to_one`](./fields.md#many_to_one) or [`one_to_one`](./fields.md#one_to_one) fields) using arrays of model records. For example:

```crystal
authors = Author.filter(first_name: "John")
articles = Article.filter(author__in: authors)
```

### `isnull`

Allows filtering records based on field values that should be null or not null.

```crystal
Article.all.filter(subtitle__isnull: true)
Article.all.filter(subtitle__isnull: false)
```

### `lte`

Allows filtering records based on field values that are less than or equal to a specified value.

```crystal
Article.all.filter(rating__lte: 10)
```

### `lt`

Allows filtering records based on field values that are less than a specified value.

```crystal
Article.all.filter(rating__lt: 10)
```

### `startswith`

Allows filtering records based on field values that start with a specific substring. Note that this is a **case-sensitive** predicate.

```crystal
Article.all.filter(title__startswith: "Top")
```

## Time predicates

Marten also supports time-related predicates that let you filter on specific parts of `date` and `date_time` fields.

The following time predicates are available:

| Predicate | Description | Supported field types | Example |
|-----------|-------------|-----------------------|---------|
| `year` | Filters by year | `date`, `date_time` | `published_at__year: 2025` |
| `month` | Filters by month (`1..12`) | `date`, `date_time` | `created_at__month: 12` |
| `day` | Filters by day of month (`1..31`) | `date`, `date_time` | `updated_at__day: 15` |
| `hour` | Filters by hour (`0..23`) | `date_time` | `created_at__hour: 14` |
| `minute` | Filters by minute (`0..59`) | `date_time` | `logged_at__minute: 30` |
| `second` | Filters by second (`0..59`) | `date_time` | `timestamp__second: 45` |

```crystal
# Basic usage
Article.filter(published_at__year: 2025)
Article.filter(created_at__month: 12)

# Through relations
Post.filter(author__created_at__year: 2024)
```

Time predicates also support comparator chaining with `exact`, `gt`, `gte`, `lt`, `lte`, `in`, and `isnull`:

```crystal
Article.filter(created_at__year__exact: 2022)
Article.filter(created_at__year__gte: 2022)
Article.filter(created_at__hour__lt: 12)
Article.filter(created_at__month__in: [11, 12])
Article.filter(created_at__year__isnull: false)
```

Accepted values for scalar comparisons are integers, numeric strings (for example `"2025"`), or `Time` instances.
For `in`, pass arrays containing these value types. For `isnull`, pass a boolean.
