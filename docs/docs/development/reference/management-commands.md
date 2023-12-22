---
title: Management commands
description: Management commands reference.
toc_max_heading_level: 2
---

This page provides a reference for all the available management commands and their options.

## `clearsessions`

**Usage:** `marten clearsessions [options]`

Clears all expired sessions for the configured session store.

Please refer to [Sessions](../../handlers-and-http/sessions.md) to learn more about sessions.

### Options

* `--no-input` - Does not show prompts to the user

### Examples

```bash
marten clearsessions            # Clears all expired sessions
marten clearsessions --no-input # Clears all expired sessions without any prompts
```

## `collectassets`

**Usage:** `marten collectassets [options]`

Collects all the assets and copies them into a unique storage.

Please refer to [Asset handling](../../assets/introduction.md) to learn more about when and how assets are "collected".

### Options

* `--no-input` - Does not show prompts to the user

### Examples

```bash
marten collectassets            # Collects all the assets
marten collectassets --no-input # Collects all the assets without any prompts
```

## `gen`

**Usage:** `marten gen [options] [generator] [arguments]`

Generate various structures, abstractions, and values within an existing project.

### Options

Generators support their own specific options. For an exact list of generator options, please refer to the [Generators reference](./generators.md).

### Arguments

* `generator` - Name of the generator to use
* `arguments` - Generator-specific arguments

Generators support their own specific arguments. For an exact list of generator arguments, please refer to the [Generators reference](./generators.md).

### Examples

```bash
marten gen secretkey                    # Generate a secret key value
marten gen email WelcomeEmail           # Generate a WelcomeEmail email in the main application
marten gen handler MyHandler --app=blog # Generate a MyHandler handler in the blog application
```

:::tip
You can also use the alias `g` to execute specific generators:

```bash
marten g model Test label:string:uniq
```
:::

## `genmigrations`

**Usage:** `marten genmigrations [options] [app_label]`

Generates new database migrations.

This command will scan the table definition corresponding to your current models and will compare it to the equivalent tables that are defined by your migration files. Based on the result of this analysis, a new set of migrations will be created and persisted in your applications' `migrations` folders. Please refer to [Migrations](../../models-and-databases/migrations.md) to learn more about this mechanism.

### Options

* `--empty` - Creates an empty migration

### Arguments

* `app_label` - The name of an application to generate migrations for (optional)

### Examples

```bash
marten genmigrations             # Generates new migrations for all the installed apps
marten genmigrations foo         # Generates new migrations for the "foo" app
marten genmigrations foo --empty # Generates an empty migration for the "foo" app
```

## `listmigrations`

**Usage:** `marten listmigrations [options] [app_label]`

Lists all the available database migrations.

This command will introspect your project and your installed applications to list the available migrations, and indicate whether they have already been applied or not. Please refer to [Migrations](../../models-and-databases/migrations.md) to learn more about this mechanism.

### Options

* `--db=ALIAS` - Allows specifying the alias of the database on which migrations will be applied or unapplied (default to  `default`)

### Arguments

* `app_label` - The name of an application to list migrations for (optional)

### Examples

```bash
marten listmigrations     # Lists all the migrations for all the installed apps
marten listmigrations foo # Lists all the migrations of the "foo" app
```

## `migrate`

**Usage:** `marten migrate [options] [app_label] [migration]`

Runs database migrations.

The `migrate` command allows you to apply (or unapply) migrations to your databases. By default, when executed without arguments, it will execute all the non-applied migrations for your installed applications. That being said, it is possible to ensure that only the migrations of a specific application are applied by specifying an additional `app_label` argument. To unapply certain migrations (or to apply some of them up to a certain version only), it is possible to specify another `migration` argument corresponding to the version of a targetted migration. Please refer to [Migrations](../../models-and-databases/migrations.md) to learn more about this mechanism.

### Options

* `--fake` - Allows marking migrations as applied or unapplied without actually running them
* `--plan` - Provides a comprehensive overview of the operations that will be performed by the applied or unapplied migrations
* `--db=ALIAS` - Allows specifying the alias of the database on which migrations will be applied or unapplied (default to `default`)

### Arguments

* `app_label` - The name of an application to run migrations for
* `migration` - A migration target (name or version) up to which the DB should be migrated. Use `zero` to unapply all the migrations of a specific application

### Examples

```bash
marten migrate                     # Applies all the non-applied migrations for all the installed apps
marten migrate foo                 # Applies migrations for the "foo" app
marten migrate foo 202203111821451 # Applies (or unapply) migrations for the "foo" app up until the "202203111821451" migration
```

## `new`

**Usage:** `marten new [options] [type] [name]`

Initializes a new Marten project or application repository structure.

The `new` management command can be used to create either a new project repository or a new [application](../applications.md) repository. This can be handy when creating new projects, or when creating new applications that are intended to be distributed as dedicated shards, as it ensures you are following Marten's best practices and conventions.

The command allows you to fully define the name of your project or application, and in which folder it should be created.

### Options

* `-d DIR, --dir=DIR` - An optional destination directory
* `--with-auth` - Adds an authentication application to newly created projects. See [Authentication](../../authentication.mdx) to learn more about this capability
* `--database` - Preconfigures the application database. Currently `mysql`, `postgresq` and `sqlite3` are supported. See [Database settings](../../development/reference/settings.md#database-settings) for more information.

### Arguments

* `type` - The type of structure to create (must be either `project` or `app`)
* `name` - The name of the project or app to create

:::tip
The `type` and `name` arguments are optional: if they are not provided, an interactive mode will be used and the command will prompt the user for inputting the structure type, the app or project name, and whether the auth app should be generated.
:::

### Examples

```bash
marten new project myblog                         # Creates a "myblog" project repository structure
marten new project myblog --dir=./projects/myblog # Creates a "myblog" project in the "./projects/myblog" folder
marten new app auth                               # Creates an "auth" application repository structure
```

## `resetmigrations`

**Usage:** `marten resetmigrations [options] [app_label]`

Resets an existing set of migrations into a single one. Please refer to [Resetting migrations](../../models-and-databases/migrations.md#resetting-migrations) to learn more about this capability.

### Arguments

* `app_label` - The name of an application to reset migrations for

### Examples

```bash
marten resetmigrations foo # Resets the migrations of the "foo" application
```

## `routes`

**Usage:** `marten routes [options]`

Displays all the routes of the application.

## `serve`

**Usage:** `marten serve [options]`

Starts a development server that is automatically recompiled when source files change.

### Options

* `-b HOST, --bind=HOST` - Allows specifying a custom host to bind
* `-p PORT, --port=PORT` - Allows specifying a custom port to listen for connections

### Examples

```bash
marten serve         # Starts a development server using the configured host and port
marten serve -p 3000 # Starts a development server by overriding the port
```

:::tip
You can also use the alias `s` to start the development server:

```bash
marten s
```
:::

## `version`

**Usage:** `marten version [options]`

Shows the Marten version.
