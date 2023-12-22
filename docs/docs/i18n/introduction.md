---
title: Introduction to internationalization
description: Learn how to leverage translations and localized contents in your Marten projects.
sidebar_label: Introduction
---

Marten provides integration with [crystal-i18n](https://crystal-i18n.github.io/) to make it possible to leverage translations and localized content in your Marten projects.

## Overview

Internationalization and localization are techniques allowing a website to provide content using languages and formats that are adapted to specific audiences.

Marten's internationalization and localization integration rely on the use of the [crystal-i18n](https://crystal-i18n.github.io/) shard, which provides a unified interface allowing to leverage translations and localized contents in a Crystal project. You don't have to manually install this shard in your projects: it is a dependency of the framework itself, and as such, it is automatically installed with Marten.

Crystal-I18n makes it easy to configure translations and formats for a specific set of locales. These can be used to perform translation lookups and localization. With this library, translations can be defined through the use of dedicated "loaders" (abstractions that load the translations from a specific source and make them available to the I18n API). For example, translations can be loaded from a YAML file, a JSON file, or something entirely different if needed.

Marten itself defines a set of translated contents for things that should be internationalized (eg. model field errors or schema field errors) that are loaded through the use of the regular YAML loader. Other [app-specific translations](#locales-and-apps) must also be defined as YAML files since they are loaded using a YAML loader as well.

## Configuration

Marten provides an integration allowing to configure internationalization-related settings. These settings are available under the [`i18n`](../development/reference/settings.md#i18n-settings) namespace and allow to define things like the default locale and the available locales:

```crystal
config.i18n.default_locale = :fr
config.i18n.available_locales = [:en, :fr]
```

You can also leverage the [various configuration options](https://crystal-i18n.github.io/configuration.html) that are provided by this shard to further configure how translations should be performed. By doing so you can add more custom I18n backend loaders for example.

:::tip
If you need to further [configure Crystal I18n](https://crystal-i18n.github.io/configuration.html), you should probably define a dedicated initializer file under the `config/initializers` folder.
:::

## Basic usage

As stated before, Marten relies on the [crystal-i18n](https://crystal-i18n.github.io/) shard, which means that you can also look at the dedicated documentation to learn more about this shard and its configuration options. The following section mainly highlights some of the main features of this library.

### Defining translations

Translations must be defined in a `locales` folder at the root of an application. For example, if you are using the [main application](../development/applications.md#the-main-application) (which corresponds to the standard `src` folder) you could define a `src/locales` folder containing an `en.yml` file as follows:

```
myproject/
├── src
│   ├── locales
│   │   ├── en.yml
```

Translations inside a YAML file must be namespaced to the locale they are associated with (`en` in this case). Example content for our `en.yml` file could look like this:

```yaml title=src/en.yml
en:
  message: "This is a message"
  simple:
    translation: "This is a simple translation"
    interpolation: "Hello, %{name}!"
```

The "path" leading to a translation in such files is important because it corresponds to the key that should be used when performing [translation lookups](#translations-lookups). For example, `simple.translation` would be the key to use in order to translate the corresponding message.

It should be noted that the `%{var}` syntax in the above example is used to define _interpolations_: these variables must be specified when performing translation lookups so that their values are inserted in the translated strings.

### Translations lookups

Translation lookups can be performed by leveraging the `I18n#translate` or `I18n#translate!` methods. Those methods try to find a matching translation for a specific key, which can be comprised of multiple namespaces or scopes separated by a dot (.): this key corresponds to the "path" leading to the actual translation (as mentioned before).

The `I18n#translate` and `I18n#translate!` methods differ in regards to how they handle missing translations:

* `I18n#translate` returns a message indicating that the translation is missing
* `I18n#translate!` raises a specific exception

For example, given the translations defined in [Defining translations](#defining-translations), we could perform the following translation lookups:

```crystal
I18n.translate(:message)                                 # => "This is a message"
I18n.translate("simple.translation")                     # => "This is a simple translation"
I18n.translate("simple.interpolation", name: "John Doe") # => "Hello, John Doe!"
```

This only scratches the surface of what's possible in terms of translation lookups. You can refer to the [dedicated documentation](https://crystal-i18n.github.io/translation_lookups.html), and more specifically the [interpolations](https://crystal-i18n.github.io/translation_lookups.html#interpolations) and [pluralizations](https://crystal-i18n.github.io/translation_lookups.html#pluralization) sections, to learn about these capabilities.

### Localization

Localization of datetimes and numbers can be achieved through the use of the `I18n#localize` method. In both cases, localization _formats_ need to be defined in your locale files. There are a lot of available formats at your disposal (and all of them are documented in the [related documentation](https://crystal-i18n.github.io/localization.html)). For example, the following translations could be used to format dates in English:

```yaml
en:
  i18n:
    date:
      month_names: [January, February, March, April, May, June,
                    July, August, September, October, November, December]
      formats:
        default: "%Y-%m-%d"
        long: "%B %d, %Y"
```

The above structure is expected by Crystal I18n and defines basic translations for the relevant directives that can be outputted when localizing dates. It also defines a few formats under the `i18n.date.formats` scope: among these formats, only the default one is really mandatory since this is the one that is used by default if no other format is explicitly provided to the `I18n#localize` method. All these formats make use of the directives defined by the [`Time::Format`](https://crystal-lang.org/api/Time/Format.html) struct.

Given the above translations, you could localize date objects as follows:

```crystal
I18n.localize(Time.local.date)        # outputs "2020-12-13"
I18n.localize(Time.local.date, :long) # outputs "December 13, 2020"
```

### Switching locales

Once you have defined translations, it is generally needed to explicitly "activate" the use of a specific locale in order to ensure that the right translations are generated for your users. In this light, the current locale can be specified using the `I18n#activate` method:

```crystal
I18n.activate(:fr)
```

When activating a locale with `I18n#activate`, all further translations or localizations will be done using the specified locale.

Note that it is also possible to execute a block with a specific locale activated. This can be done by using the `I18n#with_locale` method:

```crystal
I18n.with_locale(:fr) do
  I18n.t("simple.translation") # Will output a text in french
end
```

Finally, it should be noted that Marten provides an [I18n middleware](../handlers-and-http/reference/middlewares.md#i18n-middleware) that activates the right locale based on the Accept-Language header. Only explicitly-configured locales can be activated by this middleware (that is, locales that are specified in the [`i18n.available_locales`](../development/reference/settings.md#available_locales) and [`i18n.default_locale`](../development/reference/settings.md#default_locale) settings). If the incoming locale can't be found in the project configuration, the default locale will be used instead. By leveraging this middleware, you can be sure that the right locale is automatically enabled for your users, so you don't need to take care of it.

## Locales and apps

As mentioned previously, each [application](../development/applications.md) can define translations inside a `locales` folder that must be located at the root of the application's directory. This `locales` folder should contain YAML files defining the translations that are required by the application.

The way to organize translations inside this folder is left to application developers. That being said, it is necessary to ensure that all the YAML files containing translations are namespaced with the targeted locale (eg. `en`, `fr`, etc). 

Moreover, it is also recommended to explicitly namespace an application's translations by using an identifier that is unique for the considered application. For example, a `foo` application could define a `message` translation and another `bar` application could define a `message` translation as well. If these translation keys are not properly namespaced, one of the translations will be overridden by the one of the other application. The best way to avoid this is to namespace all the translations of an application with the identifier of the application itself. For example:

```yaml
en:
  foo:
    message: This is a message
```

In this case, the `foo` application's codebase would request translations using the `foo.message` key, which makes it impossible to encounter conflict issues with other application translations.

## How Marten resolves the current locale

Marten will attempt to determine the "current" locale for activation only when the [I18n middleware](../handlers-and-http/reference/middlewares.md#i18n-middleware) is used.

This middleware can activate the appropriate locale by considering the following:

* The value of the Accept-Language header.
* The value of a cookie, with its name defined by the [`i18n.locale_cookie_name`](../development/reference/settings.md#locale_cookie_name) setting.


The [I18n middleware](../handlers-and-http/reference/middlewares.md#i18n-middleware) only allows activation of explicitly configured locales, which are specified in the  [`i18n.available_locales`](../development/reference/settings.md#available_locales) and [`i18n.default_locale`](../development/reference/settings.md#default_locale) settings. If the incoming locale is not found in the project configuration, the default locale will be used instead. By utilizing this middleware, you can be sure that the right locale is automatically enabled for your users, so that you don't need to take care of it.

## Limitations

It's important to be aware of a few limitations when working with translations powered by [Crystal I18n](https://crystal-i18n.github.io/) within a Marten project:

1. Marten automatically configures YAML translation loaders for applications, and it is not currently possible to use other loader types (such as JSON) presently
2. Marten does not allow the use of "embedded" translations for applications since those are discovered and configured at runtime: as such application translations are treated as "assets" that must be deployed along with the compiled binary

Note that these restrictions do not prevent the use of custom translation backends if necessary. Please refer to the [related documentation](https://crystal-i18n.github.io/configuration.html#loaders) if you need to use custom translation loaders in your projects.
