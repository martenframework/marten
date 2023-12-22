---
title: Create custom template filters
sidebar_label: Create custom filters
description: How to create custom template filters.
---

Marten has built-in support for common [template filters](../reference/filters.md), but the framework also allows you to write your own template filters that you can leverage as part of your project's templates.

## Defining a template filter

Filters are subclasses of the [`Marten::Template::Filter::Base`](pathname:///api/dev/Marten/Template/Filter/Base.html) abstract class. They must implement a single `#apply` method: this method takes the value the filter should be applied to (a [`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) object wrapping _any_ of the object types supported by templates) and an optional argument that was specified to the filter.

For example, in the expression `{{ var|test:42 }}`, the `test` filter would be called with the value of the `var` variable and the filter argument `42`.

Let's say we want to write an `underscore` template filter: this template won't need any arguments and will simply return the "underscore" version of the string representation of the incoming value. Such filter could be defined as follows:

```crystal
class UnderscoreFilter < Marten::Template::Filter::Base
  def apply(value : Marten::Template::Value, arg : Marten::Template::Value? = nil) : Marten::Template::Value
    Marten::Template::Value.from(value.to_s.underscore)
  end
end
```

As you can see, the `#apply` method must return a [`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) object.

Now let's try to write a `chomp` template filter that actually makes use of the specified argument. In this case, the argument will be used to define the suffix that should be removed from the end of the string representation of the incoming value:

```crystal
class ChompFilter < Marten::Template::Filter::Base
  def apply(value : Marten::Template::Value, arg : Marten::Template::Value? = nil) : Marten::Template::Value
    raise Marten::Template::Errors::InvalidSyntax.new("The 'chomp' filter requires one argument") if arg.nil?
    Marten::Template::Value.from(value.to_s.chomp(arg.not_nil!.to_s))
  end
end
```

:::info
You should feel free to raise [`Marten::Template::Errors::InvalidSyntax`](pathname:///api/dev/Marten/Template/Errors/InvalidSyntax.html) from a filter's `#apply` method: this is especially relevant if the input has an unexpected type or if an argument is missing. That being said, it should be noted that any exception raised from a template filter won't be handled by the template engine and will result in a server error (unless explicitly handled by the application itself).
:::

### `Marten::Template::Value` objects

As highlighted previously, template filters mainly interact with [`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) objects: they take such objects as parameters (for the incoming value the filter should be applied to and for the optional filter parameter), and they must return such objects as well.

[`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) objects can be created from any supported object by using the `#from` method as follows:

```crystal
Marten::Template::Value.from("hello")
Marten::Template::Value.from(42)
Marten::Template::Value.from(true)
```

These objects are essentially "wrappers" around a real value that is manipulated as part of a template's runtime, and they provide a common interface allowing to interact with these during the template rendering. Your filter implementation can perform checks on the incoming [`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) objects if necessary: eg. in order to verify that the underlying value is of the expected type. In this light, it is possible to make use of the `#raw` method to retrieve the real value that is wrapped by the [`Marten::Template::Value`](pathname:///api/dev/Marten/Template/Value.html) object:

```crystal
value = Marten::Template::Value.from("hello")
value.raw  # => "hello"
```

### Filters and HTML auto-escaping

When writing filters that are intended to operate on strings, it is important to remember that [HTML is automatically escaped](../introduction.md#auto-escaping) in templates. As such, some string values might be flagged as "safe" and some others as "unsafe":

* regular `String` values are always assumed to be "unsafe" and will be automatically escaped by Marten's template engine
* safe strings are wrapped in `Marten::Template::SafeString` objects

This means that if your filter needs to have a different behavior based on the fact that a string is safe or not, then you will have to verify what is the type of the underlying value (by relying on the `#raw` method as explained in the previous section). It is the filter's responsibility to ensure that an incoming "safe string" is returned as a "safe string" as well or simply converted to a regular string that will be auto-escaped.

Creating safe strings is simply a matter of initializing `Marten::Template::SafeString` from a regular string:

```crystal
class SafeFilter < Marten::Template::Filter::Base
  def apply(value : Marten::Template::Value, arg : Marten::Template::Value? = nil) : Marten::Template::Value
    Marten::Template::Value.from(Marten::Template::SafeString.new(value.to_s))
  end
end
```

## Registering template filters

To be able to use custom template filters, you must register them to Marten's global template filters registry.

To do so, you will have to call the [`Marten::Template::Filter#register`](pathname:///api/dev/Marten/Template/Filter.html#register(filter_name%3AString|Symbol%2Cfilter_klass%3ABase.class)-class-method) method with the name of the filter you wish to use in templates, and the filter class.

For example:

```crystal
Marten::Template::Filter.register("underscore", UnderscoreFilter)
```

With the above registration, you could technically use this filter as follows:

```html
{{ my_var|underscore }}
```
