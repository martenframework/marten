---
title: Coming from Rails?
description: A concept map for developers already familiar with Ruby on Rails.
---

If you already know [Ruby on Rails](https://rubyonrails.org/), Marten will feel familiar in spirit. It provides a convention-oriented structure, models with validations and callbacks, migrations, and a batteries-included backend toolkit. Marten also draws from [Django](../the-marten-project/acknowledgments.md#django) in areas like templates and applications. It is [not a port](../the-marten-project/why-marten.md#familiar-ideas-designed-for-crystal) of Rails though; it is designed around Crystal.

This guide maps Rails concepts to their Marten equivalents. For a hands-on introduction, you can continue with the [tutorial](./tutorial.md) once you have completed [installation](./installation.md).

## Concept map

| Rails | Marten | Learn more |
| --- | --- | --- |
| ActiveRecord model | [`Marten::Model`](../models-and-databases/introduction.md) | ORM, validations, callbacks |
| Controller | [Handler](../handlers-and-http/introduction.md) | Request processing |
| View (ERB/Haml) | [Marten templates](../templates/introduction.md) | Django-inspired syntax, not ERB |
| `routes.rb` | [`config/routes.cr`](../handlers-and-http/routing.md) | Route maps and reverse URLs |
| Strong parameters / form objects | [Schema](../schemas/introduction.md) | Input validation in handlers |
| Scaffold / resourceful routing | [Generic handlers](../handlers-and-http/generic-handlers.md) | List, detail, create, update, delete |
| `ActiveRecord::Relation` | [Query set](../models-and-databases/queries.md) | Filtering, ordering, aggregation |
| Migrations | [Migrations](../models-and-databases/migrations.md) | Auto-generated with `genmigrations` |
| `bin/rails` | [`marten` CLI](../development/management-commands.md) | Project management commands |
| `config/application.rb` / environments | [`config/settings/`](../development/settings.md) | Per-environment configuration |
| Engine | [Application](../development/applications.md) | Reusable app packaged as a shard |
| Rack middleware | [Middleware](../handlers-and-http/middlewares.md) | Request/response pipeline |
| Authentication (eg. Devise) | [Authentication](../authentication/introduction.md) | Optional `--with-auth` app |
| `session` | [Sessions](../handlers-and-http/sessions.md) | Persisted between requests (cookie store by default) |
| `flash` | [Flash store](../handlers-and-http/introduction.md#using-the-flash-store) | One-request messages |
| I18n | [Internationalization](../i18n/introduction.md) | YAML locales via crystal-i18n |
| Action Mailer | [Emailing](../emailing/introduction.md) | Email classes and backends |
| `Rails.cache` | [Caching](../caching/introduction.md) | Cache stores |
| Asset pipeline / Propshaft | [Assets](../assets/introduction.md) | Collected with `collectassets` |
| Generators | [Generators](../development/generators.md) | Models, handlers, schemas, etc. |

## What works differently

### Crystal, not Ruby

Crystal's syntax is Ruby-inspired, which can ease the transition, but Marten applications are compiled Crystal programs. You get static typing, compile-time checks, and native binaries. Types and nilability are explicit, and the compiler is part of your day-to-day feedback loop.

### Handlers, not controllers

Rails controllers map to Marten [handlers](../handlers-and-http/introduction.md). Handlers receive a request object and return a response. You can use `#get`, `#post`, and other HTTP verb methods, or override `#dispatch`, instead of defining action methods on a controller. [Handler callbacks](../handlers-and-http/callbacks.md) replace much of what you might otherwise do with `before_action`.

### Schemas instead of strong parameters

Request data is usually validated through [schemas](../schemas/introduction.md) rather than strong parameters or ActiveModel form objects. Schemas declare fields and rules; handlers initialize and validate them against incoming data. Model validations remain on [models](../models-and-databases/validations.md).

### Templates are not ERB

Marten templates use a [Django-inspired language](../templates/introduction.md) with tags, filters, and auto-escaping. They are not ERB templates. The mental model is closer to Django templates than to Rails views.

### No built-in admin

Marten has no equivalent to tools like Rails Admin or ActiveAdmin out of the box. Admin interfaces are built with handlers and templates.

### Dependencies and packaging

Gems map to [Crystal shards](https://crystal-lang.org/reference/the_shards_command/) declared in `shard.yml`. Reusable features are packaged as Marten [applications](../development/applications.md), which play a similar role to Rails engines. Application routes can be [included](../handlers-and-http/routing.md#defining-included-routes) in the main routes map under a common prefix. The main application associated with the `src/` folder is always available implicitly; only additional applications need to be listed in [`installed_apps`](../development/reference/settings.md#installed_apps).

### Frontend is your choice

Marten is [backend-oriented](../the-marten-project/why-marten.md#backend-oriented-by-choice). It does not prescribe a JavaScript bundler or SPA architecture. You can use server-rendered templates, a separate frontend, or whichever frontend toolchain best fits your project.

## Where to go next

* The [installation guide](./installation.md) will help you install Crystal and the Marten CLI
* The [Applications](../development/applications.md) guide explains how projects and apps are organized
* The [models](../models-and-databases/introduction.md) and [handlers](../handlers-and-http/introduction.md) guides cover the core request and data flow
* The [tutorial](./tutorial.md) will walk you through building a small application
* [Why Marten?](../the-marten-project/why-marten.md) compares Marten to other Crystal frameworks

Please refer to [Acknowledgements](../the-marten-project/acknowledgments.md#ruby-on-rails) for a deeper look at Marten's Rails lineage.
