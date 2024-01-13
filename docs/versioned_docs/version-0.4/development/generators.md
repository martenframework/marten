---
title: Generators
description: Learn how to use generators in Marten.
---

Marten features a generator mechanism that simplifies the creation of various abstractions, files, and structures within an existing project. This feature facilitates the generation of key components such as [models](../models-and-databases/introduction.md), [schemas](../schemas/introduction.md), [emails](../emailing/introduction.md), or [applications](./applications.md). By leveraging generators, developers can improve their workflow and speed up the development of their Marten projects while following best practices.

## Usage

Generators can be invoked by leveraging the [`marten gen`](./reference/management-commands.md#gen) management command. This command is intended to be used as follows:

```bash
marten gen [generator] [options] [arguments]
```

As you can see, the `marten gen` command must be used with a specific **generator** name, possibly followed by **options** and **arguments** (which may be required or not depending on the considered generator). All the built-in generators are listed in the [generators reference](./reference/generators.md).

### Displaying help information

You can display help information about a specific generator by using the `marten gen` command as follows:

```bash
marten gen [generator] --help
```

### Listing generators

It is possible to list all the available generators within a project by running the `marten gen` command as follows:

```bash
marten gen
```

This should output something like this:

```
Usage: marten gen [options] [generator]

Generate various structures, abstractions, and values within an existing project.

Arguments:
    generator                        Name of the generator to use

Options:
    --error-trace                    Show full error trace (if a compilation is involved)
    --no-color                       Disable colored output
    -h, --help                       Show this help

Available generators are listed below.

[marten]

  › app
  › auth
  › email
  › handler
  › model
  › schema
  › secretkey

Run a generator followed by --help to see generator specific information, ex:
marten gen [generator] --help
```

## Examples

### Generating a model

Generating a model can be achieved with the [`model`](./reference/generators.md#model) generator:

```bash
# Generate a model in the main app:
marten gen model User name:string email:string

# Generate a model in the admin app:
marten gen model User name:string email:string --app admin

# Generate a model with a many-to-one reference:
marten gen model Article label:string body:text author:many_to_one{User}

# Generate a model with a parent class:
marten gen model Admin::User name:string email:string --parent User

# Generate a model without timestamps:
marten gen model User name:string email:string --no-timestamps
```

### Generating an email

Generating an email can be achieved with the [`email`](./reference/generators.md#email) generator:

```bash
marten gen email TestEmail            # Generate a new TestEmail email in the main application
marten gen email TestEmail --app blog # Generate a new TestEmail email in the blog application
```

### Generating an application

Generating an application can be achieved with the [`app`](./reference/generators.md#app) generator:

```bash
marten gen app blogging # Generate a new 'blogging' application
```

## Available generators

Please head over to the [generators reference](./reference/generators.md) to see a list of all the available generators.
