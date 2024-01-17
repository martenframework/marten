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

### `all`

Allows retrieving all the records of a specific model. `#all` can be used as a class method from any model class, or it can be used as an instance method from any query set object. In this last case, calling `#all` returns a copy of the current query set.

For example:

```crystal
qset = Article.all # returns a query set matching "all" the records of the Article model
qset2 = qset.all   # returns a copy of the initial query set
```

### `distinct`

Returns a new query set that will use `SELECT DISTINCT` or `SELECT DISTINCT ON` in its SQL query.

If you use this method without arguments, a `SELECT DISTINCT` statement will be used at the database level. If you pass field names as arguments, a `SELECT DISTINCT ON` statement will be used to eliminate any duplicated rows based on the specified fields:

```crystal
query_set_1 = Post.all.distinct
query_set_2 = Post.all.distinct(:title)
```

It should be noted that it is also possible to follow associations of direct related models too by using the [double underscores notation](../queries.md#joins-and-filtering-relations) (`__`). For example the following query will select distinct records based on a joined "author" attribute:

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

Returns a queryset whose specified `relations` are "followed" and joined to each result (see [Queries](../queries.md#joins-and-filtering-relations) for an introduction about this capability).

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

### `none`

Returns a query set that will always return an empty array of records, without querying the database.

Once this method is used, any subsequent method calls (such as extra filters) will continue returning an empty array of records:

```crystal
query_set = Post.all
query_set.none.exists? # => false
```

### `order`

Allows specifying the ordering in which records should be returned when evaluating the query set.

Multiple fields can be specified in order to define the final ordering. For example:

```crystal
query_set = Post.all
query_set.order("-published_at", "title")
```

In the above example, records would be ordered by descending publication date (because of the `-` prefix), and then by title (ascending).

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

Alias for [`#count`](#count): returns the number of records that are targetted by the query set.

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
