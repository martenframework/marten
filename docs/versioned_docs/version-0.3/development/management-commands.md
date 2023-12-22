---
title: Management commands
description: Learn the basics of the Marten management CLI tool.
sidebar_label: Management commands
---

Marten comes with a built-in command line interface (CLI) that developers can leverage to perform common actions and interact with the framework. This tool provides a set of built-in sub-commands that can be easily extended with new commands.

## Usage

The `marten` command is available with each Marten installation, and it is also automatically compiled when the Marten shard is installed. This means that you can either use the `marten` command from anywhere in your system (if the Marten CLI was installed globally like described in [Installation](../getting-started/installation.md)) or you can run the relative `bin/marten` command from inside your project structure.

When the `marten` command is executed, it will look for a relative `manage.cr` file to identify your current project, its [settings](./settings.md), and its installed [applications](./applications.md), which in turn will define the available sub-commands that you can run.

The `marten` command is intended to be used as follows:

```bash
marten [command] [options] [arguments]
```

As you can see, the `marten` CLI must be used with a specific **command**, possibly followed by **options** and **arguments** (which may be required or not depending on the considered command). All the built-in commands are listed in the [management commands reference](./reference/management-commands.md).

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

All the available commands are listed per application: by default, only `marten` commands are listed obviously (if no other applications are installed), but it should be noted that [applications](./applications.md) can contribute management commands as well. If that's the case, these additional commands will be automatically listed as well.

### Shared options

Each command can accept its own set of arguments and options, but it should be noted that all the available commands always accept the following options:

* `--error-trace` - Allows showing the full error trace (if a compilation is involved)
* `--no-color` - Disables colored outputs
* `-h, --help` - Displays help information about the considered command

## Available commands

Please head over to the [management commands reference](./reference/management-commands.md) to see a list of all the available management commands. Implementing custom management commands is also a possibility that is documented in [Create custom commands](./how-to/create-custom-commands.md).
