---
title: Relationships
description: Learn how to define relationships in models.
---

Marten offers a powerful and intuitive solution for defining the three most common types of database relationships (many-to-one, one-to-one, and many-to-many) through the use of [model fields](./introduction.md#model-fields). By leveraging these special fields, developers can enhance their application's data modeling and streamline data access.

## Many-to-one relationships

Many-to-one relationships can be defined through the use of [`many_to_one`](./reference/fields.md#many_to_one) fields. This special field type requires the utilization of the [`to`](./reference/fields.md#to-1) argument, allowing to explicitly define the target model class associated with the current model.

For example, an `Article` model could have a many-to-one field towards an `Author` model. In such case, an `Article` record would only have one associated `Author` record, but every `Author` record could be associated with many `Article` records:

```crystal
class Author < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  // highlight-next-line
  field :author, :many_to_one, to: Author
end
```

### Interacting with related records

Like for any other [model fields](./introduction.md#model-fields), Marten automatically generates getters and setters allowing to interact with the field's value.

With the above snippet, it would be possible to access the `Author` record associated with a specific `Article` record by leveraging the `#author` and `#author=` methods. For example:

```crystal
# Create two authors
author_1 = Author.create!(full_name: "Foo Bar")
author_2 = Author.create!(full_name: "John Doe")

# Create an article
article = Article.create!(title: "First article", author: author_1)
article.author!.id # => 1
article.author # => #<Author:0x101590c40 id: 1, full_name: "Foo Bar">

# Change the article author
article.author = author_2
article.save!
article.author!.id # => 2
article.author # => #<Author:0x101590c41 id: 2, full_name: "John Doe">
```

:::tip
Note that you can also access the related record's ID directly without actually loading it by leveraging the `#<field_name>_id` method (which corresponds to the actual name of the column used to persist the reference to the related record's primary key in the model table).

For instance, using the model definitions provided earlier, you could perform the following operation:

```crystal
author = Author.create!(full_name: "Foo Bar")
article = Article.create!(title: "First article", author: author)
article.author_id # => 1
```
:::

### Backward relations

By default, [`many_to_one`](./reference/fields.md#many_to_one) fields do not establish a backward relation. This means that you cannot directly retrieve records that target a specific related record starting from the related record itself. For instance, by default, it is not possible to retrieve all the `Article` records associated with a specific `Author` record.

To enable this capability, you need to make use of the [`related`](./reference/fields.md#related-1) argument when defining your  [`many_to_one`](./reference/fields.md#many_to_one) field. For instance, we could modify the previous model definitions as follows in order to define an `articles` backward relation and to let `Author` records expose their related `Article` records:

```crystal
class Author < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  // highlight-next-line
  field :author, :many_to_one, to: Author, related: :articles
end
```

When the [`related`](./reference/fields.md#related-1) argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that all the `Article` records associated with a specific `Author` record will be accessible through the use of the `Author#articles` method:

```crystal
# Create two authors
author_1 = Author.create!(full_name: "Foo Bar")
author_2 = Author.create!(full_name: "John Doe")

# Create articles
article_1 = Article.create!(title: "First article", author: author_1)
article_2 = Article.create!(title: "Second article", author: author_2)
article_3 = Article.create!(title: "Third article", author: author_1)

# List the first author's articles
author_1.articles.to_a # [#<Article:0x1036e3ee0 id: 1, title: "First article", author_id: 1>,
                       #  #<Article:0x1036e3e70 id: 3, title: "Third article", author_id: 1>]
```

:::tip
The method generated for the backward relation returns a [query set](./queries.md) that you can use to further filter the list of records. For example:

```crystal
author.articles.filter(title__startswith: "Top")
```
:::

### Deletion strategy

When defining [`many_to_one`](./reference/fields.md#many_to_one) fields, it is highly advisable to specify a deletion strategy for the associated relation. This configuration determines the behavior of records with many-to-one fields when one of the records referred to by such fields gets deleted.

Such behavior can be configured by leveraging the [`on_delete`](./reference/fields.md#on_delete) argument when defining [`many_to_one`](./reference/fields.md#many_to_one) fields. This argument allows specifying the deletion strategy to adopt when a related record (one that is targeted by the [`many_to_one`](./reference/fields.md#many_to_one) field) is deleted. This argument accepts the following values (expressed as symbols):

* `:do_nothing`: This is the default strategy. With this strategy, Marten won't do anything to ensure that records referencing the record being deleted are deleted or updated. If the database enforces referential integrity (which will be the case for foreign key fields), this means that deleting a record could result in database errors.
* `:cascade`: This strategy can be used to perform cascade deletions. When deleting a record, Marten will try to first destroy the other records that reference the object being deleted.
* `:protect`: This strategy allows explicitly preventing the deletion of records if they are referenced by other records. This means that attempting to delete a "protected" record will result in a `Marten::DB::Errors::ProtectedRecord` error.
* `:set_null`: This strategy will set the reference column to `null` when the related record is deleted.

For example, we could modify our previous model definition so that `Article` records are cascade-deleted if the associated `Author` records are destroyed:

```crystal
class Author < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  // highlight-next-line
  field :author, :many_to_one, to: Author, related: :articles, on_delete: :cascade
end
```

With this change, if we try to delete an `Author` record, we should notice that the associated `Article` records are deleted as well:

```crystal
# Create two authors
author_1 = Author.create!(full_name: "Foo Bar")
author_2 = Author.create!(full_name: "John Doe")

# Create articles
article_1 = Article.create!(title: "First article", author: author_1)
article_2 = Article.create!(title: "Second article", author: author_2)
article_3 = Article.create!(title: "Third article", author: author_1)

# Delete the first author
author_1.delete

article_1.reload # => raises Marten::DB::Errors::RecordNotFound
```

## One-to-one relationships

One-to-one relationships can be defined through the use of [`one_to_one`](./reference/fields.md#one_to_one) fields. This special field type requires the utilization of the [`to`](./reference/fields.md#to-2) argument, allowing to explicitly define the target model class associated with the current model.

For example, a `User` model could have a one-to-one field towards a `Profile` model. In such case, the `User` model could only have one associated `Profile` record, and the reverse would be true as well (a `Profile` record could only have one associated `User` record):

```crystal
class Profile < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :email, :email
  // highlight-next-line
  field :profile, :one_to_one, to: Profile
end
```

:::info
A one-to-one field is really similar to a many-to-one field, but with an additional unicity constraint.
:::

### Interacting with related records

Like for any other [model fields](./introduction.md#model-fields), Marten automatically generates getters and setters allowing to interact with the field's value.

With the above snippet, it would be possible to access the `Profile` record associated with a specific `User` record by leveraging the `#profile` and `#profile=` methods. For example:

```crystal
# Create two users
user_1 = User.create!(email: "test1@example.com", profile: Profile.create!(full_name: "Foo Bar"))
user_2 = User.create!(email: "test2@example.com", profile: Profile.create!(full_name: "John Doe"))

# Access a user's profile
user_1.profile!.id # => 1
user_1.profile # => #<Profile:0x101590c40 id: 1, full_name: "Foo Bar">

# Change a user's profile
user_1.profile = Profile.create!(full_name: "New Profile")
user_1.save!
user_1.profile!.id # => 3
user_1.profile # => #<Profile:0x101590c41 id: 3, full_name: "New Profile">
```

:::tip
Like for [many-to-one relationships](#many-to-one-relationships), you can also access the related record's ID directly without actually loading it by leveraging the `#<field_name>_id` method (which corresponds to the actual name of the column used to persist the reference to the related record's primary key in the model table).

For instance, using the model definitions provided earlier, you could perform the following operation:

```crystal
user = User.create!(email: "test1@example.com", profile: Profile.create!(full_name: "Foo Bar"))
user.profile_id # => 1
```
:::

### Backward relations

By default, [`one_to_one`](./reference/fields.md#one_to_one) fields do not establish a backward relation. This means that you cannot directly retrieve the record that targets a specific related record starting from the related record itself. For instance, by default, it is not possible to retrieve the `User` record associated with a specific `Profile` record.

To enable this capability, you need to make use of the [`related`](./reference/fields.md#related-2) argument when defining your  [`one_to_one`](./reference/fields.md#one_to_one) field. For instance, we could modify the previous model definitions as follows in order to define a `user` backward relation and to let `Profile` records expose their related `User` record:

```crystal
class Profile < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :email, :email
  // highlight-next-line
  field :profile, :one_to_one, to: Profile, related: :user
end
```

When the [`related`](./reference/fields.md#related-2) argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that the `User` record associated with a specific `Profile` record will be accessible through the use of the `Profile#user` method:

```crystal
# Create two profiles
profile_1 = Profile.create!(full_name: "Foo Bar")
profile_2 = Profile.create!(full_name: "John Doe")

# Create two users
user_1 = User.create!(email: "test1@example.com", profile: profile_1)
user_2 = User.create!(email: "test2@example.com", profile: profile_2)

# Get the first profile's user
profile_1.user # => #<User:0x1036e3ee0 id: 1, email: "test1@example.com", profile_id: 1>
```

:::tip
Note that in the previous example, `#user` could return `nil` if no `User` record is available for the considered profile. A nil-safe version of the related method is also automatically defined with the following name: `#<related_name>!`. For example:

```crystal
# Create two profiles
profile_1 = Profile.create!(full_name: "Foo Bar")
profile_2 = Profile.create!(full_name: "John Doe")

# Create two users
user_1 = User.create!(email: "test1@example.com", profile: profile_1)
user_2 = User.create!(email: "test2@example.com", profile: profile_2)

# Delete the first user
user_1.delete

# Get the first profile's user
profile_1.user! # => raises Marten::DB::Errors::RecordNotFound
```
:::

### Deletion strategy

Like for [many-to-one relationships](#deletion-strategy), the deletion strategy to use for [`one_to_one`](./reference/fields.md#one_to_one) fields can be configured by leveraging the [`on_delete`](./reference/fields.md#on_delete-1) argument. This argument allows specifying the deletion strategy to adopt when a related record (one that is targeted by the [`many_to_one`](./reference/fields.md#many_to_one) field) is deleted. This argument accepts the following values (expressed as symbols):

* `:do_nothing`: This is the default strategy. With this strategy, Marten won't do anything to ensure that the record referencing the record being deleted is deleted or updated. If the database enforces referential integrity (which will be the case for foreign key fields), this means that deleting a record could result in database errors.
* `:cascade`: This strategy can be used to perform cascade deletions. When deleting a record, Marten will try to first destroy the other record that references the object being deleted.
* `:protect`: This strategy allows explicitly preventing the deletion of the record if is is referenced by another record. This means that attempting to delete a "protected" record will result in a `Marten::DB::Errors::ProtectedRecord` error.
* `:set_null`: This strategy will set the reference column to `null` when the related record is deleted.

For example, we could modify our previous model definition so that a `User` record is cascade-deleted if the associated `Profile` records is destroyed:

```crystal
class Profile < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :full_name, :string, max_size: 128
end

class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :email, :email
  // highlight-next-line
  field :profile, :one_to_one, to: Profile, related: :user, on_delete: :cascade
end
```

With this change, if we try to delete a `Profile` record, we should notice that the associated `User` records is deleted as well:

```crystal
# Create two profiles
profile_1 = Profile.create!(full_name: "Foo Bar")
profile_2 = Profile.create!(full_name: "John Doe")

# Create two users
user_1 = User.create!(email: "test1@example.com", profile: profile_1)
user_2 = User.create!(email: "test2@example.com", profile: profile_2)

# Delete the first profile
profile_1.delete

user_1.reload # => raises Marten::DB::Errors::RecordNotFound
```

## Many-to-many relationships

Many-to-many relationships can be defined through the use of [`many_to_many`](./reference/fields.md#many_to_many) fields. This special field type requires the utilization of the [`to`](./reference/fields.md#to) argument, allowing to explicitly define the target model class associated with the current model.

For example, an `Article` model could have a many-to-many field towards a `Tag` model. In such case, an `Article` record could have many associated `Tag` records, and every `Tag` record could be associated with many `Article` records as well:

```crystal
class Tag < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :label, :string, max_size: 128
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  // highlight-next-line
  field :tags, :many_to_many, to: Tag
end
```

### Interacting with related records

[`many_to_many`](./reference/fields.md#many_to_many) fields exhibit unique characteristics compared to other relationship fields. When using [`many_to_many`](./reference/fields.md#many_to_many) fields in Marten, the framework generates a `#<field_name>` getter method that returns a specialized [query set](./queries.md) that not only enables filtering of targeted records but also facilitates the dynamic addition and removal of records to/from the set.

With the above snippet, it would be possible to access the `Tags` records associated with a specific `Article` record by leveraging the `#tags` method. For example:

```crystal
# Create three tags
tag_1 = Tag.create!(label: "Tag 1")
tag_2 = Tag.create!(label: "Tag 2")
tag_3 = Tag.create!(label: "Tag 3")

# Create one article
article = Article.create!(title: "My article")

# Add one tag to the article
article.tags.add(tag_1)
article.tags.to_a # => [#<Tag:0x1036e3ee0 id: 1, label: "Tag 1">]

# Add two tags to the article
article.tags.add(tag_2, tag_3)
article.tags.to_a # => [#<Tag:0x1036e3ee0 id: 1, label: "Tag 1">,
                  #     #<Tag:0x1036e3ee1 id: 2, label: "Tag 2">,
                  #     #<Tag:0x1036e3ee2 id: 3, label: "Tag 3">]

# Filter the article's tags
article.tags.filter(label: "Tag 1").to_a # => [#<Tag:0x1036e3ee0 id: 1, label: "Tag 1">]

# Remove a tag from the article's tags
article.tags.remove(tag_2)
article.tags.to_a # => [#<Tag:0x1036e3ee0 id: 1, label: "Tag 1">,
                  #     #<Tag:0x1036e3ee2 id: 3, label: "Tag 3">]

# Clear the article's tags
article.tags.clear
```

Take note of the utilization of the [`#add`](pathname:///api/0.4/Marten/DB/Query/ManyToManySet.html#add(*objs%3AM)-instance-method) and [`#remove`](pathname:///api/0.4/Marten/DB/Query/ManyToManySet.html#remove(*objs%3AM)%3ANil-instance-method) methods, facilitating the addition or removal of objects from the record's many-to-many collection of associated items. These methods are callable with single or multiple records as parameters, as well as with arrays of records for streamlined addition or removal.

### Backward relations

By default, [`many_to_many`](./reference/fields.md#many_to_many) fields do not establish a backward relation. This means that you cannot directly retrieve records that target a specific related record starting from the related record itself. For instance, by default, it is not possible to retrieve all the `Article` records associated with a specific `Tag` record.

To enable this capability, you need to make use of the [`related`](./reference/fields.md#related-1) argument when defining your  [`many_to_many`](./reference/fields.md#many_to_many) field. For instance, we could modify the previous model definitions as follows in order to define an `articles` backward relation and to let `Tag` records expose their related `Article` records:

```crystal
class Tag < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :label, :string, max_size: 128
end

class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  // highlight-next-line
  field :tags, :many_to_many, to: Tag, related: :articles
end
```

When the [`related`](./reference/fields.md#related) argument is used, a method will be automatically created on the targetted model by using the chosen argument's value. For example, this means that all the `Article` records associated with a specific `Tag` record will be accessible through the use of the `Tag#articles` method:

```crystal
# Create three tags
tag_1 = Tag.create!(label: "Tag 1")
tag_2 = Tag.create!(label: "Tag 2")
tag_3 = Tag.create!(label: "Tag 3")

# Create two articles
article_1 = Article.create!(title: "First article")
article_2 = Article.create!(title: "Second article")

# Add tags to the articles
article_1.tags.add(tag_1, tag_2)
article_2.tags.add(tag_2, tag_3)

# Retrieve the second tag's articles
tag_2.articles.to_a # => [#<Article:0x1036e3ee0 id: 1, title: "First article">,
                    #     #<Article:0x1036e3ee2 id: 3, title: "Second article">]
tag_2.articles.filter(title: "First article").to_a # => [#<Article:0x1036e3ee0 id: 1, title: "First article">]
```

## Advanced topics

### Recursive relationships

All the relationship fields mentioned previously support defining recursive relations, ie. relations that target the same model as the model defining the relation field. To do so, you can define a [`many_to_one`](./reference/fields.md#many_to_one), [`one_to_one`](./reference/fields.md#one_to_one), or [`many_to_many`](./reference/fields.md#many_to_many) field whose `to` argument is set to the `self` keyword.

For example:

```crystal
class TreeNode < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :label, :string, max_size: 128
  // highlight-next-line
  field :parent, :many_to_one, to: self
end
```

In the above snippet, the `TreeNode` model will have a relation to itself through the `parent` field.
