---
title: Design philosophies
description: Learn about the design philosophies behind the Marten web framework.
---

This document goes over the fundamental design philosophies that influenced the creation of the Marten web framework. It seeks to provide insight into the past and serve as a reference for the future.

## Simple and easy to use

Marten tries to ensure that everything it enables is as simple as possible and that the syntax provided for dealing with the framework's components remains obvious and easy to remember (and certainly not complex or obscure). The framework makes it as easy as possible to leverage its capabilities and perform CRUD operations.

## Full-featured

Marten adheres to the "batteries included" philosophy. Out of the box, it provides the tools and features that are commonly required by web applications: [ORM](../models-and-databases/introduction.md), [migrations](../models-and-databases/migrations.md), [translations](../i18n/introduction.md), [templating engine](../templates/introduction.md), [sessions](../handlers-and-http/sessions.md), [emailing](../emailing/introduction.md), and [authentication](../authentication/introduction.md).

## Extensible

Marten gives developers the ability to contribute extra functionalities to the framework easily. Things like [custom model field implementations](../models-and-databases/how-to/create-custom-model-fields.md), [new route parameter types](../handlers-and-http/how-to/create-custom-route-parameters.md), [session stores](../handlers-and-http/sessions.md#session-stores), etc... can all be registered to the framework easily.

## DB-Neutral

The framework's ORM is and should remain usable with multiple database backends (including MySQL, PostgreSQL, and SQLite).

## App-oriented

Marten allows separating projects into a set of logical "[apps](../development/applications.md)", which helps improve code organization and makes it easy for multiple developers to work on different components. Each app can contribute specific abstractions and features to a project like models and migrations, templates, HTTP handlers and routes, etc. These apps can also be extracted in Crystal shards in order to contribute features and behaviors to other Marten projects. The goal behind this capability is to allow the creation of a powerful apps ecosystem over time and to encourage "reusability" and "pluggability".

:::tip
In this light, the [Awesome Marten](https://github.com/martenframework/awesome-marten) repository lists applications that you can leverage in your projects.
:::

## Backend-oriented

The framework is intentionally very "backend-oriented" because the idea is to not make too many assumptions regarding how the frontend code and assets should be structured, packaged or bundled together. The framework can't account for all the ways assets can be packaged and/or bundled together and does not advocate for specific solutions in this area. Some projects might require a webpack strategy to bundle assets, some might require a fingerprinting step on top of that, and others might need something entirely different. How these toolchains are configured or set up is left to the discretion of web application developers, and the framework simply makes it easy to [reference these assets](../assets/introduction.md) and [collect them](../assets/introduction.md#serving-assets-in-production) at deploy time to upload them to their final destination.
