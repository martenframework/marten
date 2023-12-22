---
title: Create custom context producers
sidebar_label: Create context producers
description: How to create custom context producers.
---

Marten has built-in support for common [context producers](../reference/context-producers.md), but the framework also allows you to write your own context producers that you can leverage as part of your project's templates. This allows you to easily reuse common context values over multiple templates.

## Defining a context producer

Defining a context producer involves creating a subclass of the [`Marten::Template::ContextProducer`](pathname:///api/0.2/Marten/Template/ContextProducer.html) abstract class. This abstract class requires that subclasses implement a single [`#produce`](pathname:///api/0.2/Marten/Template/ContextProducer.html#produce(request%3AHTTP%3A%3ARequest%3F%3Dnil)-instance-method) method: this method takes an optional request object as argument and must return either:

* a hash or a named tuple containing the values to contribute to the template context
* or `nil` if no values can be generated for the passed request

For example, the following context producer would expose the value of the [`debug`](../../development/reference/settings.md#debug) setting to all the template contexts being created:

```crystal
class Debug < Marten::Template::ContextProducer
  def produce(request : Marten::HTTP::Request? = nil)
    {"debug" => Marten.settings.debug}
  end
end
```

## Activating context producers

As mentioned in [Using context producers](../introduction.md#using-context-producers), context producers classes must be added to the [`templates.context_producers`](../../development/reference/settings.md#contextproducers) setting in order to be used by the Marten templates engine when initializing new context objects.
