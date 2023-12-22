---
title: Database transactions
description: Learn how to leverage database transactions.
sidebar_label: Transactions
---

Transactions are blocks whose underlying SQL statements are committed to the database as one atomic action only if they can complete without errors. Marten provides a few mechanisms to control how database transactions are performed and managed.

## The basics

Transactions are essential in order to enforce database integrity. Whenever you are in a situation where you have more than one SQL operations that must be executed together or not at all, then you should consider wrapping all these operations in a dedicated transaction. Transaction blocks can be created by leveraging the `#transaction` method, which can be called either on [model records](pathname:///api/0.2/Marten/DB/Model/Connection.html#transaction(using%3ANil|String|Symbol%3Dnil%2C%26block)-instance-method) or [model classes](pathname:///api/0.2/Marten/DB/Model/Connection/ClassMethods.html#transaction(using%3ANil|String|Symbol%3Dnil%2C%26)-instance-method).

For example:

```crystal
MyModel.transaction do
  my_record.save!
  my_other_record.save!
end
```

With the above snippet, both records will be saved _only_ if each save operation completes successfully (that is if no exception is raised). If an exception occurs as part of one of the save operations (eg. if one of the records is invalid), then no records will be saved.

It should be noted that there is no difference between calling `#transaction` on [a model record](pathname:///api/0.2/Marten/DB/Model/Connection.html#transaction(using%3ANil|String|Symbol%3Dnil%2C%26block)-instance-method) or [a model class](pathname:///api/0.2/Marten/DB/Model/Connection/ClassMethods.html#transaction(using%3ANil|String|Symbol%3Dnil%2C%26)-instance-method). It's also worth mentioning that the models manipulated within a transaction block that result in SQL statements can be of different classes. For example, the following two transactions would be equivalent:

```crystal
MyModel.transaction do
  MyModel.create!(foo: "bar")
  MyOtherModel.create!(foo: "bar")
end

MyOtherModel.transaction do
  MyModel.create!(foo: "bar")
  MyOtherModel.create!(foo: "bar")
end
```

:::info
When transaction blocks are nested, this results in all the database statements of the inner transaction to be added to the outer transaction. As such, there is only one "effective" transaction at any given time when transaction blocks are nested.
:::

## Automatic transactions

Basic model operations such as [creating](./introduction.md#create), [updating](./introduction.md#update), or [deleting](./introduction.md#delete) records are automatically wrapped in a transaction. This helps in ensuring that any exception that is raised in the context of validations or as part of `after_*` [callbacks](./callbacks.md) (ie. `after_create`, `after_update`, `after_save`, and `after_delete`) will also roll back the current transaction.

The consequence of this is that the changes you make to the database in these callbacks will not be "visible" until the transaction is complete. For example, this means that if you are triggering something (like an asynchronous job) that needs to leverage the changes introduced by a model operation, then you should probably not use the regular `after_*` callbacks. Instead, you should leverage [`after_commit`](./callbacks.md#aftercommit) callbacks (which are the only callbacks that are triggered _after_ a model operation has been committed to the database).

## Exception handling and rollbacks

As mentioned before, any exception that is raised from within a transaction block will result in the considered transaction being rolled back. Moreover, it should be noted that raised exceptions will also be propagated outside of the transaction block, which means that your codebase should catch these accordingly if applicable.

If you need to roll back a transaction _manually_ from within a transaction itself while ensuring that no exception is propagated outside of the block, then you can make use of the [`Marten::DB::Errors::Rollback`](pathname:///api/0.2/Marten/DB/Errors/Rollback.html) exception: when this specific exception is raised from inside a transaction block, the transaction will be rolled back and the transaction block will return `false`.

For example:

```crystal
transaction_committed = MyModel.transaction do
  MyModel.create!(foo: "bar")
  MyOtherModel.create!(foo: "bar")

  raise Marten::DB::Errors::Rollback.new("Stop!") if should_rollback?
end

transaction_committed # => false
```
