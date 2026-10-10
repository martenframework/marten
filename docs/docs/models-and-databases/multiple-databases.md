---
title: Multiple databases
description: Learn how to leverage multiple databases in a Marten project.
---

This section covers how to leverage multiple databases within a Marten project: how to configure these additional databases, how to query them, and how to route model operations automatically.

## Defining multiple databases

Each Marten project leveraging a single database uses what is called a "default" database. This is the database whose configuration is defined when calling the [`#database`](pathname:///api/dev/Marten/Conf/GlobalSettings.html#database(id%3DDB%3A%3AConnection%3A%3ADEFAULT_CONNECTION_NAME%2C%26)-instance-method) configuration method:

```crystal
config.database do |db|
  db.backend = :sqlite
  db.name = "default_db.db"
end
```

The "default" database is implied whenever you interact with the database (eg. by performing queries, creating records, etc), unless specified otherwise or unless a database router selects another connection.

The [`#database`](pathname:///api/dev/Marten/Conf/GlobalSettings.html#database(id%3DDB%3A%3AConnection%3A%3ADEFAULT_CONNECTION_NAME%2C%26)-instance-method) configuration method can take an additional argument in order to define additional databases. For example:

```crystal
config.database :other_db do |db|
  db.backend = :sqlite
  db.name = "other_db.db"
end
```

Think of this additional argument as a "database identifier" or alias that you can choose and that will allow you to interact with this specific database later on.

## Database routers

Database routers let you define which database should be used for reads, writes, relations, and migrations. Routers are configured via the [`database_routers`](../development/reference/settings.md#database_routers) setting:

```crystal
config.database_routers = [
  AnalyticsRouter,
]
```

Each router must inherit from [`Marten::DB::Router::Base`](pathname:///api/dev/Marten/DB/Router/Base.html) and can override any of the following methods:

| Method | Role | Return value |
| --- | --- | --- |
| `#db_for_read` | Suggest a database alias for read operations | alias `String`, or `nil` (no opinion) |
| `#db_for_write` | Suggest a database alias for write operations | alias `String`, or `nil` |
| `#allow_relation?` | Allow or forbid a relation between two records | `true`, `false`, or `nil` |
| `#allow_migrate?` | Allow or forbid applying migrations to a database | `true`, `false`, or `nil` |

Configured routers are consulted **in order**. The first non-`nil` opinion wins. If all routers abstain:

* read/write operations fall back to the `"default"` database
* relations and migrations are allowed

### Example: routing an app to a dedicated database

```crystal
class AnalyticsRouter < Marten::DB::Router::Base
  def db_for_read(model, hints = Marten::DB::Router::Hints.new) : String?
    "analytics" if model.app_config.label == "analytics"
  end

  def db_for_write(model, hints = Marten::DB::Router::Hints.new) : String?
    db_for_read(model, hints)
  end

  def allow_migrate?(db, app_label, model_name = nil, hints = Marten::DB::Router::Hints.new) : Bool?
    return app_label == "analytics" if db == "analytics"
    return app_label != "analytics" if db == "default"
    nil
  end
end
```

### Example: primary / replica split

```crystal
class PrimaryReplicaRouter < Marten::DB::Router::Base
  def db_for_read(model, hints = Marten::DB::Router::Hints.new) : String?
    "replica"
  end

  def db_for_write(model, hints = Marten::DB::Router::Hints.new) : String?
    "default"
  end
end
```

### Connection resolution order

When Marten needs a database connection for a model operation, it resolves it in this order:

1. An explicit `#using` / `using:` argument, if provided
2. The sticky database alias stored on the model instance, if any
3. The first configured router that returns a non-`nil` alias
4. The `"default"` database

The sticky alias is set when a record is loaded from or saved to a database via an explicit `#using` selection. Subsequent bare `#save`, `#delete`, `#update`, or `#update_columns` calls on that instance reuse the same database.

## Applying migrations to your databases

The [`migrate`](../development/reference/management-commands.md#migrate) management command operates on the "default" database by default, but it also accepts an optional `--db` option that lets you specify to which database the migrations should be applied. The value you specify for this option must correspond to the alias you configured when defining your databases in your project's configuration. For example:

```bash
marten migrate --db=other_db
```

When database routers are configured, Marten consults `#allow_migrate?` for each migration and only applies migrations that are allowed for the target database. This makes it possible to keep app-specific schemas on dedicated databases.

## Manually selecting databases

Marten lets you select which database you want to use when performing model-related operations. Unless specified, the connection suggested by routers (or the "default" database) is used, but it is possible to explicitly define to which database operations should be applied. Explicit selection always takes precedence over routers.

### Querying records

When querying records, you can use the [`#using`](./reference/query-set.md#using) query set method in order to specify the target database. For example:

```crystal
Article.all                  # Targets the routed (or default) database
Article.using(:other_db).all # Targets the "other_db" database
```

### Persisting records

When creating, updating, or deleting records, it is possible to specify to which database the operation should be applied to by using the `using` argument. For example:

```crystal
tag = Tag.new(label: "crystal")
tag.save(using: :other_db)
tag.delete(using: :other_db)
```

After an explicit `using:` persistence, the record remembers that database alias. Later bare saves on the same instance continue targeting it unless another alias is specified.
