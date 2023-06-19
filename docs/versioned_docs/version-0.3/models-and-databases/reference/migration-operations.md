---
title: Migration operations
description: Migration operations reference.
---

This page provides a reference for all the available migration operations that can be leveraged when writing migrations.

## `add_column`

The `add_column` operation allows adding a column to an existing table. It must be called with a table name as first argument, followed by a column definition (column name and attributes).

For example:

```crystal
add_column :test_table, :foo, :string, max_size: 255
add_column :test_table, :new_id, :reference, to_table: :target_table, to_column: :id
```

## `add_index`

The `add_index` operation allows adding an index to an existing table. It must be called with a table name as first argument, followed by an index definition (index name and indexed column names).

For example:

```crystal
add_index :test_table, :test_index, [:foo, :bar]
```

## `add_unique_constraint`

The `add_unique_constraint` operation allows adding a unique constraint to an existing table. It must be called with a table name as first argument, followed by a unique constraint definition (constraint name and targetted column names).

For example:

```crystal
add_unique_constraint :test_table, :test_constraint, [:foo, :bar]
```

## `change_column`

The `change_column` operation allows altering an existing column definition. It must be called with a table name as first argument, followed by a column definition (column name and attributes).

For example:

```crystal
change_column :test_table, :test_column, :string, max_size: 155, null: true
```

## `create_table`

The `create_table` operation allows creating a new table, which includes the underlying column definitions, indexes, and unique constraints. It must be called with a table name as first argument and requires a block where columns, indexes, and unique constraints are defined.

For example:

```crystal
create_table :test_table do
  column :id, :big_int, primary_key: true, auto: true
  column :foo, :int, null: true
  column :bar, :int, null: true

  unique_constraint :cname, [:foo, :bar]
  index :index_name, [:foo, :bar]
end
```

## `delete_table`

The `delete_table` operation allows deleting an existing table. It must be called with a table name as first argument.

For example:

```crystal
delete_table :test_table
```

## `execute`

The `execute` operation allows executing custom SQL statements as part of a migration. It must be called with a forward statement as first positional argument, and it can also take a second positional argument in order to specify the statement to execute when unapplying the migration.

For example:

```crystal
execute(
  (
    <<-SQL
    SELECT 1
    SQL
  ),
  (
    <<-SQL
    SELECT 2
    SQL
  )
)
```

## `remove_column`

The `remove_column` operation allows removing an existing column from a table. It must be called with a table name as first argument, followed by a column name.

For example:

```crystal
remove_column :test_table, :test_column
```

## `remove_index`

The `remove_index` operation allows removing an existing index from a table. It must be called with a table name as first argument, followed by an index name.

For example:

```crystal
remove_index :test_table, :test_index
```

## `remove_unique_constraint`

The `remove_unique_constraint` operation allows removing an existing unique constraint from a table. It must be called with a table name as first argument, followed by a unique constraint name.

For example:

```crystal
remove_unique_constraint :test_table, :test_constraint
```

## `rename_column`

The `rename_column` operation allows renaming an existing column in a table. It must be called with a table name as first argument, followed by the old column name, and the new one.

For example:

```crystal
rename_column :test_table, :old_column, :new_column
```

## `rename_table`

The `rename_table` operation allows renaming an existing table. It must be called with the existing table name as first argument, followed by the new table name.

For example:

```crystal
rename_table :old_table, :new_table
```

## `run_code`

The `run_code` operation allows to define that arbitrary methods will be called when applying and unapplying a migration. It must be called with a method name as first positional argument (the method that will be called when applying the migration), and it can also take an additional argument in order to specify the name of the method to execute when unapplying the migration.

For example:

```crystal
run_code :run_forward_code, :run_backward_code
```
