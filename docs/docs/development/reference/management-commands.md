---
title: Management commands
description: Management commands reference.
---

This page provides a reference for the Marten CLI, all the available management commands, and their options.

## Usage

The `marten` command is available with each Marten installation, and it is also automatically compiled when the Marten shard is installed. This means that you can either use the `marten` command from anywhere in your system (if the Marten CLI was installed globally like described in [Installation](../../getting-started/installation)) or you can run the relative `bin/marten` command from inside your project structure.

When the `marten` command is executed, it will look for a relative `manage.cr` file in order to identify your current project, its [settings](../settings), and its installed [applications](../applications), which in turns will define the available sub commands that you can run.

The `marten` command is intended to be used as follows:

```bash
marten [command] [options] [arguments]
```

As you can see, the `marten` CLI must be used with a specific **command**, possibly followed by **options** and **arguments** (which may be required or not depending on the considered command). All the built-in commands are listed below in [Available commands](#available-commands).

### Displaying help information

You can display help information about a specific management command by using the `marten` CLI as follows:

```bash
marten help [command]
marten [command] --help
```

### Listing commands

It is possible to list all the available commands within a project by running the `marten` CLI as follows:

```bash
marten help
```

This should output something like this:

```bash
Usage: marten [command] [arguments]

Available commands:

[marten]
  › collectassets
  › genmigrations
  › listmigrations
  › migrate
  › new
  › resetmigrations
  › routes
  › serve
  › version

Run a command followed by --help to see command specific information, ex:
marten [command] --help
```

All the available commands are listed per application: by default only `marten` commands are listed obviously (if no other applications are installed), but it should be noted that [applications](../applications) can contribute management commands as well. If that's the case, these additional commands will be automatically listed as well.

### Shared options

Each command can accept its own set of arguments and options, but it should be noted that all the available commands always accept the following options:

* `--error-trace` - Allows to show the full error trace (if a compilation is involved)
* `--no-color` - Disables colored outpus
* `-h, --help` - Displays help information about the considered command

## Available commands

### `collectassets`

**Usage:** `marten collectassets [options]`

Collects all the assets and copy them in a unique storage.

Please refer to [Asset handling](../../files/asset-handling) to lear more about when and how assets are "collected".

#### Options

* `--no-input` - Does not show prompts to the user

#### Examples

```bash
marten collectassets            # Collects all the assets
marten collectassets --no-input # Collects all the assets without any prompts
```

### `genmigrations`

**Usage:** `marten genmigrations [options] [app_label]`

Generates new database migrations.

This command will scan the table definition corresponding to your current models and will compare it to the equivalent tables that are defined by your migration files. Based on the result of this analysis, a new set of migrations will be created and persisted in your applications' `migrations` folders. Please refer to [Migrations](../../models-and-databases/migrations) to learn more about this mechanism.

#### Options

* `--empty` - Creates an empty migration

#### Arguments

* `app_label` - The name of an application to generate migrations for (optional)

#### Examples

```bash
marten genmigrations             # Generates new migrations for all the installed apps
marten genmigrations foo         # Generates new migrations for the "foo" app
marten genmigrations foo --empty # Generates an empty migration for the "foo" app
```

### `listmigrations`

**Usage:** `marten listmigrations [options] [app_label]`

Lists all the available database migrations.

This command will introspect your project and your installed applications in order to list the available migrations, and indicate whether they have already been applied or not. Please refer to [Migrations](../../models-and-databases/migrations) to learn more about this mechanism.

#### Options

* `--db=ALIAS` - Allows to specify the alias of the database on which migrations will be applied or unapplied (default to  `default`)

#### Arguments

* `app_label` - The name of an application to list migrations for (optional)

#### Examples

```bash
marten listmigrations     # Lists all the migrations for all the installed apps
marten listmigrations foo # Lists all the migrations of the "foo" app
```

### `migrate`

**Usage:** `marten migrate [options] [app_label] [migration]`

Runs database migrations.

The `migrate` command allows to apply (or unapply) migrations to your databases. By default, when executed without arguments, it will execute all the non-applied migrations for your installed applications. That being said, it is possible to ensure that only the migrations of a specific application are applied by specifying an additional `app_label` argument. In order to unapply certain migrations (or to apply some of them up to a certain version only), it is possible to specify another `migration` argument corresponding to the version of a targetted migration. Please refer to [Migrations](../../models-and-databases/migrations) to learn more about this mechanism.

#### Options

* `--fake` - Allows to mark migrations as applied or unapplied without actually running them
* `--db=ALIAS` - Allows to specify the alias of the database on which migrations will be applied or unapplied (default to `default`)

#### Arguments

* `app_label` - The name of an application to run migrations for
* `migration` - A migration target (name or version) up to which the DB should be migrated. Use `zero` to unapply all the migrations of a specific application

#### Examples

```bash
marten migrate                     # Applies all the non-applied migrations for all the installed apps
marten migrate foo                 # Applies migrations for the "foo" app
marten migrate foo 202203111821451 # Applies (or unapply) migrations for the "foo" app up until the "202203111821451" migration
```

### `new`

**Usage:** `marten new [options] [type] [name] [dir]`

Initializes a new Marten project or application structure.

The `new` management command can be used to create either a new project structure or a new [application](../applications) structure. This can be handy when creating new projects or when introducing new applications into an existing project, as it ensures you are following Marten's best practices and conventions.

The command allows you to fully define the name of your project or application, and in which folder it should be created.

#### Arguments

* `type` - The type of structure to create (must be either `project` or `app`)
* `name` - The name of the project or app to create
* `dir` - A destination directory (optional)

#### Examples

```bash
marten new project myblog                   # Creates a "myblog" project
marten new project myblog ./projects/myblog # Creates a "myblog" project in the "./projects/myblog" folder
marten new app auth                         # Creates an "auth" application
```

### `resetmigrations`

**Usage:** `marten resetmigrations [options] [app_label]`

Resets an existing set of migrations into a single one. Please refer to [Resetting migrations](../../models-and-databases/migrations#resetting-migrations) to learn more about this capability.

#### Arguments

* `app_label` - The name of an application to reset migrations for

#### Examples

```bash
marten resetmigrations foo # Resets the migrations of the "foo" application
```

### `routes`

**Usage:** `marten routes [options]`

Displays all the routes of the application.

### `serve`

**Usage:** `marten serve [options]`

Starts a development server that is automatically recompiled when source files change.

### `version`

**Usage:** `marten version [options]`

Shows the Marten version.
