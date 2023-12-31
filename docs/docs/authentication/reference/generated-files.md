---
title: Generated files
description: Generated files reference.
---

This page provides a reference of the files that are generated for the `auth` application when running the [`new`](../../development/reference/management-commands.md#new) management command with the `--with-auth` option or when using the [`auth`](../../development/reference/generators.md#auth) generator.

## Application

The `auth` application is generated under the `src` or `src/apps` folder. In addition to the abstractions mentioned below, this folder defines the following top-level files:

* `app.cr` - The entrypoint of the `auth` application, where all the other abstractions are required
* `cli.cr` - The CLI entrypoint of the `auth` application, where CLI-related abstractions (like migrations) are required
* `routes.cr` - The `auth` application routes map

### Emails

* `password_reset_email.cr` - Defines the [email](../../emailing.mdx) that is sent as part of the user password reset flow

### Handlers

* `handlers/concerns/require_anonymous_user.cr` - A concern that ensures that a handler can only be accessed by anonymous users
* `handlers/concerns/require_signed_in_user.cr` - A concern that ensures that a handler can only be accessed by signed-in users
* `handlers/password_reset_confirm_handler.cr` - A handler that handles resetting a user's password as part of the password reset flow
* `handlers/password_reset_initiate_handler.cr` - A handler that initiates the password reset flow for a given user
* `handlers/password_update_handler.cr` - A handler that allows to update the user's password
* `handlers/profile_handler.cr` - A handler that displays the currently signed-in user profile
* `handlers/sign_in_handler.cr` - A handler that allows users to sign in
* `handlers/sign_out_handler.cr` - A handler that allows users to sign out
* `handlers/sign_up_handler.cr` - A handler that allows users to sign up

### Migrations

* `migrations/0001_create_auth_user_table.cr` - Allows to create the table of the `Auth::User` model

### Models

* `models/user.cr` - Defines the main `Auth::User` model

### Schemas

* `schemas/password_reset_confirm_schema.cr` - A schema that allows a user to reset their password
* `schemas/password_reset_initiate_schema.cr` - A schema that allows a user to initiate the password reset flow
* `schemas/password_update_schema.cr` - A schema that allows a user to update their password
* `schemas/sign_in_schema.cr` - A schema used to sign in users
* `schemas/sign_up_schema.cr` - A schema used to sign up users

### Templates

* `templates/auth/emails/password_reset.html` - The template of the password reset email
* `templates/auth/password_reset_confirm.html` - The template used to let users reset their passwords
* `templates/auth/password_reset_initiate.html` - The template used to let users initiate the password reset flow
* `templates/auth/password_update.html` - The template used to let users update their password
* `templates/auth/profile.html` - The template of the user profile
* `templates/auth/sign_in.html` - The sign in page template
* `templates/auth/sign_up.html` - The sign up page template

## Specs

All the previously mentioned abstractions have associated specs that are defined under the `spec/apps/auth` folder.
