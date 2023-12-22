---
title: Generators
description: Generators reference.
toc_max_heading_level: 2
---

This page provides a reference for all the available generators and their options.

## `app`

**Usage:** `marten gen app [options] [label]`

Add and configure a new [application](../applications.md) to the current project.

:::info
This generator will attempt to add the generated application to the [`installed_apps`](./settings.md#installed_apps) setting and will also configure Crystal requirements for it (in the `src/project.cr` and `src/cli.cr` files).
:::

### Arguments

* `label` - Label of the application to generate

### Examples

```bash
marten gen app blogging # Generate a new 'blogging' application
```

## `auth`

**Usage:** `marten gen auth [options] [label]`

Generate and configure a fully functional authentication application for your project. Please refer to [Authentication](../../authentication.mdx) to learn more about authentication in Marten, and to [Generated files](../../authentication/reference/generated-files.md) to see a list of the files generated for the authentication app specifically.

:::info
This generator will attempt to add the generated application to the [`installed_apps`](./settings.md#installed_apps) setting and will also configure Crystal requirements for it (in the `src/project.cr` and `src/cli.cr` files). It will also add authentication-related settings to your base settings file and will add the [`marten-auth`](https://github.com/martenframework/marten-auth) shard to your project's `shard.yml`.
:::

### Arguments

* `label` - Label of the authentication application to generate (default to "auth")

### Examples

```bash
marten gen auth         # Generate a new authentication app with the 'auth' label
marten gen auth my_auth # Generate a new authentication app with the 'my_auth' label
```

## `email`

**Usage:** `marten gen email [options] [name]`

Generate an email. Please refer to [Emailing](../../emailing.mdx) to learn more about emailing in Marten.

### Options

* `--app=APP` - Target app where the email should be created (default to the [main app](../applications.md#the-main-application))
* `--parent=PARENT` - Parent class name for the generated email

### Arguments

* `name` - Name of the email to generate (must be CamelCase)

### Examples

```bash
marten gen email TestEmail            # Generate a new TestEmail email in the main application
marten gen email TestEmail --app blog # Generate a new TestEmail email in the blog application
```

## `handler`

Generate a handler. Please refer to [Handlers](../../handlers-and-http/introduction.md) to learn more about handlers.

### Options

* `--app=APP` - Target app where the handler should be created (default to the [main app](../applications.md#the-main-application))
* `--parent=PARENT` - Parent class name for the generated handler

### Arguments

* `name` - Name of the handler to generate (must be CamelCase)

### Examples

```bash
marten gen handler TestHandler            # Generate a new TestHandler handler in the main application
marten gen handler TestHandler --app blog # Generate a new TestHandler handler in the blog application
```

## `model`

Generate a model. Please refer to [Models](../../models-and-databases/introduction.md) to learn more about models.

### Options

* `--app=APP` - Target app where model handler should be created (default to the [main app](../applications.md#the-main-application))
* `--parent=PARENT` - Parent class name for the generated model
* `--no-timestamps` - Do not include timestamp fields in the generated model

### Arguments

* `name` - Name of the model to generate (must be CamelCase)
* `field_definitions` - Field definitions of the model to generate

### Details

This generator can generate a model with the specified name and field definitions. The model is generated in the app specified by the `--app` option or in the [main app](../applications.md#the-main-application) if no app is specified.

Field definitions can be specified using the following formats:

```
name:type
name:type{qualifier}
name:type:modifier:modifier
```

Where `name` is the name of the field and `type` is the type of the field.

`qualifier` can be required depending on the considered field type; when this is the case, it corresponds to a mandatory field option. For example, `label:string{128}` will produce a [string field](../../models-and-databases/reference/fields.md#string) whose `max_size` option is set to `128`. Another example: `author:many_to_one{User}` will produce a [many-to-one field](../../models-and-databases/reference/fields.md#many_to_one) whose `to` option is set to target the `User` model.

`modifier` is an optional field modifier. Field modifiers are used to specify additional (but non-mandatory) field options. For example: `name:string:uniq` will produce a [string field](../../models-and-databases/reference/fields.md#string) whose `unique` option is set to `true`. Another example: `name:string:uniq:index` will produce a [string field](../../models-and-databases/reference/fields.md#string) whose `unique` and `index` options are set to `true`.

### Examples

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

## `schema`

Generate a schema. Please refer to [Schemas](../../schemas/introduction.md) to learn more about schemas.

### Options

* `--app=APP` - Target app where schema should be created (default to the [main app](../applications.md#the-main-application))
* `--parent=PARENT` - Parent class name for the generated schema

### Arguments

* `name` - Name of the schema to generate (must be CamelCase)
* `field_definitions` - Field definitions of the schema to generate

### Details

This generator can generate a schema with the specified name and field definitions. The schema is generated in the app specified by the `--app` option or in the [main app](../applications.md#the-main-application) if no app is specified.

Field definitions can be specified using the following formats:

```
name:type
name:type:modifier:modifier
```

Where `name` is the name of the field and `type` is the type of the field.

`modifier` is an optional field modifier. Field modifiers are used to specify additional (but non-mandatory) field options. For example: `name:string:optional` will produce a [string field](../../schemas/reference/fields.md#string) whose `required` option is set to `false`.

### Examples

```bash
# Generate a schema in the main app:
marten gen schema ArticleSchema title:string body:string

# Generate a schema in the blog app:
marten gen schema ArticleSchema title:string body:string --app admin

# Generate a schema with a parent class:
marten gen schema ArticleSchema title:string body:string --parent BaseSchema
```

## `secretkey`

Generate a new secret key value that can be used in the [`secret_key`](./settings.md#secret_key) setting.

### Examples

```bash
marten gen secretkey
```
