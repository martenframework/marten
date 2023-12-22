---
title: Model callbacks
description: Learn how to define model callbacks.
sidebar_label: Callbacks
---

Models callbacks let you define logic that is triggered before or after a record's state alteration. They are methods that get called at specific stages of a record's lifecycle. For example, callbacks can be called when model instances are created, updated, or deleted. This documents covers the available callbacks and introduces you to the associated API, which you can use to define hooks in your models.

## Overview

As stated above, callbacks are methods that will be called when specific events occur for a specific model instance. They need to be registered explicitly as part your model definitions. There are [many types of of callbacks](#available-callbacks), and it is possible to register "before" or "after" callbacks for most of these types.

Registering a callback is as simple as calling the right callback macro (eg. `#before_validation`) with a symbol of the name of the method to call when the callback is executed. For example:

```crystal
class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :username, :string, max_size: 64, unique: true

  before_validation :ensure_username_is_downcased

  private def ensure_username_is_downcased
    self.username = username.try(&.downcase)
  end
end
```

In the above snippet, a `before_validation` callback is registered to ensure that the `username` of a `User` instance is downcased before any validation.

This technique of callback registration is shared by all types of callbacks.

It should be noted that the order in which callback methods are registered for a given callback type (eg. `before_update`) matters: callbacks will be called in the order in which they were registered.

## Available callbacks

### `after_initialize`

`after_initialize` callbacks are called right after a model instance is initialized. They will be called automatically when new model instances are initialized through the use of `new` or when records are retrieved from the database.

### `before_validation` and `after_validation`

`before_validation` callbacks are called before running validation rules for a given model instance while `after_validation` callbacks are executed after. They can be used to sanitize model instance attributes for example.

The use of methods like `#valid?` or `#invalid?`, or any other methods involving validations (`#save`, `#save!`, `#create`, or `#create!`), will trigger validation callbacks. See [Model validations](./validations.md) for more details.

### `before_create` and `after_create`

`before_create` callbacks are called before a new record is inserted into the database. `after_create` callbacks are called after a new record has been created at the database level.

The use of the `#save` method (or `#save!`) on a new model instance will trigger the execution of creation callbacks. The use of the `#create` / `#create!` methods will also trigger these callbacks.

### `before_update` and `after_update`

`before_update` callbacks are called before an existing record is updated while `after_update` callbacks are called after.

The use of the `#save` method (or `#save!`) on an existing model record will trigger the execution of update callbacks.

### `before_save` and `after_save`

`before_save` callbacks are called before a record (existing or new) is saved to the database while `after_save` callbacks are called after.

The use of the `#save` / `#save!` and the `#create` / `#create!` methods will trigger the execution of save callbacks.

:::info
`before_save` and `after_save` are called for both new and existing records. `before_save` callbacks are always executed _before_ `before_create` or `before_update` callbacks. `after_save` callbacks on the other hand are always executed _after_ `after_create` or `after_update` callbacks.
:::

### `before_delete` and `after_delete`

`before_delete` callbacks are called before a record gets deleted while `after_delete` callbacks are called after.

The use of the `#delete` method will trigger these callbacks.

### `after_commit`

`after_commit` callbacks are called after a record is created, updated, or deleted, but only after the corresponding SQL transaction has been committed to the database (which isn't the case for other `after_*` callbacks - See [Transactions](./transactions.md) for more details). For example:

```crystal
after_commit :do_something
```

As mentioned previously, by default such callbacks will run in the context of record creations, updates, and deletions. That being said it is also possible to associate these callbacks with one or more specific actions only by using the `on` argument. For example:

```crystal
after_commit :do_something, on: :create # Will run after creations only
after_commit :do_something, on: :update # Will run after updates only
after_commit :do_something, on: :update # Will run after saves (creations or updates) only
after_commit :do_something, on: :delete # Will run after deletions only
after_commit :do_something_else, on: [:create, :delete] # Will run after creations and deletions only
```

The actions supported by the `on` argument are `create`, `update`, `save`, and `delete`.

### `after_rollback`

`after_rollback` callbacks are called after a transaction is rolled back when a record is created, updated, or deleted. For example:

```crystal
after_rollback :do_something
```

As mentioned previously, by default such callbacks will run in the context of record creations, updates, and deletions. That being said it is also possible to associate these callbacks with one or more specific actions only by using the `on` argument. For example:

```crystal
after_rollback :do_something, on: :create # Will run after rolled back creations only
after_rollback :do_something, on: :update # Will run after rolled back updates only
after_rollback :do_something, on: :update # Will run after rolled back saves (creations or updates) only
after_rollback :do_something, on: :delete # Will run after rolled back deletions only
after_rollback :do_something_else, on: [:create, :delete] # Will run after rolled back creations and deletions only
```

The actions supported by the `on` argument are `create`, `update`, `save`, and `delete`.
