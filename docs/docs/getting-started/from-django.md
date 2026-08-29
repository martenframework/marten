---
title: Coming from Django?
description: A concept map for developers already familiar with Django.
---

If you already know [Django](https://www.djangoproject.com/), many Marten ideas will feel familiar. Marten follows a similar Model, Handler, and Template structure and borrows conventions from Django's apps, migrations, templates, and generic views. It is [not a port](../the-marten-project/why-marten.md#familiar-ideas-designed-for-crystal) of Django though; it is designed around Crystal's type system and compilation model.

This guide maps Django concepts to their Marten equivalents. For a hands-on introduction, you can continue with the [tutorial](./tutorial.md) once you have completed [installation](./installation.md).

## Concept map

| Django | Marten | Learn more |
| --- | --- | --- |
| Model | [`Marten::Model`](../models-and-databases/introduction.md) | ORM, validations, callbacks |
| View (function or class-based) | [Handler](../handlers-and-http/introduction.md) | Request processing |
| Template (Django template language) | [Marten templates](../templates/introduction.md) | Django-inspired syntax |
| `urls.py` | [`config/routes.cr`](../handlers-and-http/routing.md) | Route maps and reverse URLs |
| Form / `ModelForm` | [Schema](../schemas/introduction.md) | Input validation in handlers |
| Generic class-based views | [Generic handlers](../handlers-and-http/generic-handlers.md) | List, detail, create, update, delete |
| `QuerySet` | [Query set](../models-and-databases/queries.md) | Filtering, ordering, aggregation |
| Migrations | [Migrations](../models-and-databases/migrations.md) | Auto-generated with `genmigrations` |
| `manage.py` | [`marten` CLI](../development/management-commands.md) | Project management commands |
| `settings.py` | [`config/settings/`](../development/settings.md) | Per-environment configuration |
| `INSTALLED_APPS` | [`installed_apps`](../development/reference/settings.md#installed_apps) | Applications and reusable apps |
| Middleware | [Middleware](../handlers-and-http/middlewares.md) | Request/response pipeline |
| `django.contrib.auth` | [Authentication](../authentication/introduction.md) | Optional `--with-auth` app |
| `django.contrib.sessions` | [Sessions](../handlers-and-http/sessions.md) | Persisted between requests (cookie store by default) |
| `django.contrib.messages` | [Flash store](../handlers-and-http/introduction.md#using-the-flash-store) | One-request messages |
| Translation / i18n | [Internationalization](../i18n/introduction.md) | YAML locales via crystal-i18n |
| `send_mail` | [Emailing](../emailing/introduction.md) | Email classes and backends |
| `cache` framework | [Caching](../caching/introduction.md) | Cache stores |
| `static` / `collectstatic` | [Assets](../assets/introduction.md) | Collected with `collectassets` |

## What works differently

### Crystal comes first

Marten is a Crystal framework. Even when APIs look Django-like, you will write Crystal code with static typing, compile-time checks, macros, and native compilation. If Crystal is new to you, you may want to skim the [Crystal language reference](https://crystal-lang.org/reference/) alongside this documentation.

### Handlers, not views

In Django, "views" process requests and return responses. In Marten, this role is filled by [handlers](../handlers-and-http/introduction.md). A handler is a class that receives a request and returns a response. HTTP verbs map to methods such as `#get` and `#post`, or to an overridden `#dispatch` method. [Handler callbacks](../handlers-and-http/callbacks.md) can be used for logic that would otherwise live in a view's `dispatch` method or in middleware.

### Schemas instead of forms

User input is usually validated through [schemas](../schemas/introduction.md) rather than Django forms. Schemas define fields and validation rules, and handlers bind them to incoming request data. They are not model-bound like `ModelForm` classes; model-level validation still lives on [models](../models-and-databases/validations.md).

### No built-in admin

Django's automatic admin interface has no direct equivalent in Marten. You can build admin-style interfaces with handlers, templates, and generic handlers, or integrate a dedicated frontend.

### Dependencies and packaging

Python packages map to [Crystal shards](https://crystal-lang.org/reference/the_shards_command/) declared in `shard.yml`. Reusable Marten functionality is often packaged as [applications](../development/applications.md), which play a similar role to Django apps distributed as installable packages. Unlike `INSTALLED_APPS`, the main application associated with the `src/` folder is always available implicitly; only additional applications need to be listed in [`installed_apps`](../development/reference/settings.md#installed_apps).

### Compile-time feedback

Many mistakes surface at compile time rather than at runtime. This is usually a good thing: the compiler can catch issues early when refactoring models, handlers, and schemas.

## Where to go next

* The [installation guide](./installation.md) will help you install Crystal and the Marten CLI
* The [Applications](../development/applications.md) guide explains how projects and apps are organized
* The [models](../models-and-databases/introduction.md) and [handlers](../handlers-and-http/introduction.md) guides cover the core request and data flow
* The [tutorial](./tutorial.md) will walk you through building a small application
* [Why Marten?](../the-marten-project/why-marten.md) compares Marten to other Crystal frameworks

Please refer to [Acknowledgements](../the-marten-project/acknowledgments.md#django) for a deeper look at Marten's Django lineage.
