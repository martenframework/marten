---
title: Multiple databases
description: Learn how to leverage multiple databases in a Marten project.
---

This section covers how to leverage multiple databases within a Marten project: how to configure these additional databases and how to query them.

:::caution
Support for multi-database projects is still experimental and lacking features such as DB routing.
:::

## Defining multiple databases

Each Marten project leveraging a single database uses what is called a "default" database. This is the database whose configuration is defined when calling the [`#database`](pathname:///api/dev/Marten/Conf/GlobalSettings.html#database(id%3DDB%3A%3AConnection%3A%3ADEFAULT_CONNECTION_NAME%2C%26)-instance-method) configuration method:

```crystal
config.database do |db|
  db.backend = :sqlite
  db.name = "default_db.db"
end
```

The "default" database is implied whenever you interact with the database (eg. by performing queries, creating records, etc), unless specified otherwise.

The [`#database`](pathname:///api/dev/Marten/Conf/GlobalSettings.html#database(id%3DDB%3A%3AConnection%3A%3ADEFAULT_CONNECTION_NAME%2C%26)-instance-method) configuration method can take an additional argument in order to define additional databases. For example:

```crystal
config.database :other_db do |db|
  db.backend = :sqlite
  db.name = "other_db.db"
end
```

Think of this additional argument as a "database identifier" or alias that you can choose and that will allow you to interact with this specific database later on.

## Applying migrations to your databases

The [`migrate`](../development/reference/management-commands.md#migrate) management command operates on the "default" database by default, but it also accepts an optional `--db` option that lets you specify to which database the migrations should be applied. The value you specify for this option must correspond to the alias you configured when defining your databases in your project's configuration. For example:

```bash
marten migrate --db=other_db
```

Note that running such a command would apply **all** the migrations to the `other_db` database. There is presently no way to ensure that only specific models or migrations are applied to a particular database only.

## Manually selecting databases

Marten lets you select which database you want to use when performing model-related operations. Unless specified, the "default" database is always implied but it is possible to explicitly define to which database operations should be applied.

### Querying records

When querying records, you can use the [`#using`](./reference/query-set.md#using) query set method in order to specify the target database. For example:

```crystal
Article.all                  # Will target the "default" database
Article.using(:other_db).all # Will target the "other_db" database
```

### Persisting records

When creating, updating, or deleting records, it is possible to specify to which database the operation should be applied to by using the `using` argument. For example:

```crystal
tag = Tag.new(label: "crystal")
tag.save(using: :other_db)
tag.delete(using: :other_db)
```
