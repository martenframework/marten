---
title: Why Marten?
description: Learn why Marten is a good fit for your next web application.
---

Marten is a batteries-included web framework for [Crystal](https://crystal-lang.org/). It is designed to provide a consistent and extensible foundation for building complete web applications while taking advantage of Crystal's expressive syntax, static type system, native compilation, and performance.

Rather than requiring applications to assemble and integrate many independent libraries for common web development needs, Marten provides these capabilities as parts of the framework itself.

## Batteries included

Marten follows the "batteries included" philosophy. Features commonly required by web applications are available out of the box, including an [ORM](../models-and-databases/introduction.md) and [migrations](../models-and-databases/migrations.md), [schemas](../schemas/introduction.md) and [validation](../schemas/validations.md), [templates](../templates/introduction.md), [sessions](../handlers-and-http/sessions.md), [authentication](../authentication/introduction.md), [internationalization](../i18n/introduction.md), [emailing](../emailing/introduction.md), [caching](../caching/introduction.md), and more.

The goal is not to eliminate choice, but to provide a solid foundation for common needs so that applications don't have to reinvent them.

## Consistent by design

Having many features built into a framework is most useful when those features feel like parts of the same system.

Marten aims to provide consistent conventions and predictable APIs across its different components. As applications grow and make use of more of the framework, the same concepts and patterns remain familiar instead of requiring entirely different approaches for each new concern.

This consistency is an important part of Marten's [design philosophies](./design-philosophies.md): the framework is intended to be understood as a whole rather than as a collection of unrelated libraries.

## Extensible when needed

Batteries included does not mean closed or inflexible.

Marten provides extension points throughout the framework so that built-in behavior can be complemented or adapted to specific needs. [Custom model fields](../models-and-databases/how-to/create-custom-model-fields.md), [route parameter types](../handlers-and-http/how-to/create-custom-route-parameters.md), [session stores](../handlers-and-http/sessions.md#session-stores), [template engines](../templates/introduction.md), and other components can be implemented and registered with the framework.

This allows Marten to provide useful defaults for common cases without preventing applications from going beyond them.

## Applications as building blocks

Marten projects can be divided into logical [apps](../development/applications.md). Each app can encapsulate its own [models](../models-and-databases/introduction.md), [migrations](../models-and-databases/migrations.md), [handlers](../handlers-and-http/introduction.md), [routes](../handlers-and-http/routing.md), [templates](../templates/introduction.md), and other functionality.

Apps are useful for organizing larger projects, but they can also be extracted and distributed as Crystal shards to provide reusable functionality to other Marten projects.

As a result, the same mechanism used to structure an application also provides a foundation for extending Marten and building reusable components around it.

## The benefits of Crystal, with a full-featured framework

[Crystal](https://crystal-lang.org/) provides an expressive, Ruby-inspired syntax together with a static type system, native compilation, and strong runtime performance.

Marten builds on these characteristics while providing the higher-level abstractions and built-in functionality expected from a full-featured web framework. Its goal is to make it possible to build complete web applications with Crystal without having to assemble the fundamental pieces of the web stack yourself.

## Backend-oriented by choice

Marten is intentionally backend-oriented and avoids making unnecessary assumptions about how frontend code should be structured or built.

Applications are free to use [server-rendered templates](../templates/introduction.md), dedicated frontend applications, JavaScript bundlers, asset pipelines, or other approaches depending on their needs. Marten provides the mechanisms necessary to [work with](../assets/introduction.md) and [deploy](../assets/serving-assets.md) assets without requiring a specific frontend toolchain.

This keeps the framework focused on providing a strong foundation for the backend while leaving frontend architecture in the hands of each application.

## Familiar ideas, designed for Crystal

Marten draws inspiration from established frameworks such as [Django](https://www.djangoproject.com/) and [Ruby on Rails](https://rubyonrails.org/), but it is not intended to be a port of either.

Concepts such as [models](../models-and-databases/introduction.md), [migrations](../models-and-databases/migrations.md), [handlers](../handlers-and-http/introduction.md), [templates](../templates/introduction.md), [applications](../development/applications.md), and convention-oriented development have been adapted and designed around Crystal and Marten's own architecture.

Developers familiar with batteries-included frameworks should therefore encounter many recognizable ideas while still working with APIs and patterns designed specifically for Crystal.

## How does Marten compare to other Crystal frameworks?

Crystal offers several frameworks for building web applications, but they make significantly different architectural choices. Marten is designed for those who want a complete web framework whose components form a consistent and extensible whole.

### Kemal

[Kemal](https://kemalcr.com/) intentionally provides a lightweight foundation centered around [routing](../handlers-and-http/routing.md), request handling, [middleware](../handlers-and-http/middlewares.md), and HTTP responses. This makes it an excellent choice for small services or applications where assembling the rest of the stack independently is desirable.

Marten takes the opposite approach. [Models](../models-and-databases/introduction.md), [migrations](../models-and-databases/migrations.md), [schemas](../schemas/introduction.md), [templates](../templates/introduction.md), [sessions](../handlers-and-http/sessions.md), [authentication](../authentication/introduction.md), [emailing](../emailing/introduction.md), [internationalization](../i18n/introduction.md), [caching](../caching/introduction.md), and other common needs are part of the framework and are designed to work together.

For complete web applications, this means fewer architectural and integration decisions have to be made before application-specific work can begin. If you want the framework to provide a coherent application architecture rather than primarily an HTTP layer, Marten provides a stronger foundation.

### Lucky

[Lucky](https://luckyframework.org/) is the closest alternative to Marten in terms of scope. It is also a full-featured framework and makes extensive use of Crystal's type system to catch errors at compile time.

The two frameworks differ significantly in how they approach application design. Lucky emphasizes specialized, explicit abstractions and compile-time guarantees across the stack. Marten favors a smaller set of familiar concepts and consistent conventions that recur throughout the framework.

Marten's [models](../models-and-databases/introduction.md), [query sets](../models-and-databases/queries.md), [schemas](../schemas/introduction.md), [handlers](../handlers-and-http/introduction.md), [templates](../templates/introduction.md), [routes](../handlers-and-http/routing.md), [applications](../development/applications.md), and other components are designed to feel like parts of the same system. The goal is to keep the framework predictable as its surface area grows, without requiring every concern to introduce an entirely different way of working.

For those who value a cohesive batteries-included architecture and straightforward, familiar APIs over maximizing the amount of application behavior encoded through compile-time abstractions, Marten offers a simpler and more consistent approach.

### Amber

[Amber](https://amberframework.org/) provides a full-stack, MVC-oriented framework with conventions, [generators](../development/generators.md), and tooling covering both application development and the surrounding development workflow.

Marten deliberately focuses more narrowly on providing a strong backend framework. It does not prescribe how frontend assets should be authored, bundled, or structured, allowing applications to use [server-rendered templates](../templates/introduction.md), dedicated frontend applications, or whichever frontend toolchain best fits their needs.

Marten also places reusable [applications](../development/applications.md) at the center of its architecture. The same app mechanism used to organize a project can be used to package [models](../models-and-databases/introduction.md), [migrations](../models-and-databases/migrations.md), [handlers](../handlers-and-http/introduction.md), [routes](../handlers-and-http/routing.md), [templates](../templates/introduction.md), and other functionality for reuse in other projects.

For applications where a cohesive backend architecture, frontend independence, and reusable application components are more important than a conventional full-stack MVC workflow, Marten provides a more flexible foundation.

These differences reflect deliberate architectural choices. If you want a minimal HTTP framework, [Kemal](https://kemalcr.com/) may be the better tool. If you specifically prefer [Lucky](https://luckyframework.org/)'s emphasis on compile-time guarantees and explicit abstractions, Lucky may suit you better. If you prefer [Amber](https://amberframework.org/)'s full-stack MVC approach, Amber may be the natural choice.

But if you are looking for a comprehensive, consistent, extensible, and backend-oriented foundation for building complete web applications in Crystal, Marten is designed to provide exactly that.

## When is Marten a good fit?

Marten may be a good fit when:

* You want to build a complete web application with Crystal rather than assemble the framework layer yourself.
* You value a batteries-included approach with common web development functionality available out of the box.
* You prefer a framework whose different components follow consistent conventions and are designed to work together.
* You want useful defaults while retaining the ability to extend or replace framework behavior when necessary.
* You want to organize functionality into reusable [applications](../development/applications.md).
* You want the benefits of Crystal without giving up the conveniences of a full-featured web framework.
* You prefer to keep control over your frontend architecture instead of having the backend framework prescribe one.

Marten may be less appropriate when all that is needed is a minimal HTTP layer, when an application depends heavily on integrations available only in a larger ecosystem, or when a framework is expected to prescribe the entire frontend toolchain as well as the backend.

## In short

Marten's proposition is not based on any single feature. It comes from the combination of a batteries-included approach, consistent conventions, extensibility, reusable applications, backend orientation, and the characteristics of the Crystal programming language.

If that combination matches the way you want to build web applications, Marten provides a foundation designed around it from the start.
