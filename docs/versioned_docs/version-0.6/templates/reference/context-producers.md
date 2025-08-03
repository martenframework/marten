---
title: Context producers
description: Context producers reference.
---

This page provides a reference for all the available context producers that can be used when rendering [templates](../introduction.md).

## Debug context producer

**Class:** [`Marten::Template::ContextProducer::Debug`](pathname:///api/dev/Marten/Template/ContextProducer/Debug.html)

The Debug context producer contributes a `debug` variable to the context: the associated value is `true` or `false` depending on whether [debug mode](../../development/reference/settings.md#debug) is enabled for the project or not.

## Flash context producer

**Class:** [`Marten::Template::ContextProducer::Flash`](pathname:///api/dev/Marten/Template/ContextProducer/Flash.html)

The Flash context producer contributes a `flash` variable to the context: this variable corresponds to the [flash store](../../handlers-and-http/introduction.md#using-the-flash-store) that is associated with the current HTTP request. If the template context is not initialized with an HTTP request object, then no variables are inserted.

## I18n context producer

**Class:** [`Marten::Template::ContextProducer::I18n`](pathname:///api/dev/Marten/Template/ContextProducer/I18n.html)

The I18n context producer contributes I18n-related variables to the context:

* `locale`: the current locale
* `available_locales`: an array of all the available locales that can be activated for the project

## Request context producer

**Class:** [`Marten::Template::ContextProducer::Request`](pathname:///api/dev/Marten/Template/ContextProducer/Request.html)

The Request context producer contributes a `request` variable to the context: this variable corresponds to the current HTTP request object. If the template context is not initialized with an HTTP request object, then no variables are inserted.

