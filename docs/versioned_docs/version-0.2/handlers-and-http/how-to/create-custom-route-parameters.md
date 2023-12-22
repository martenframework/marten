---
title: Create custom route parameters
description: How to create custom route parameters.
---

Although Marten has built-in support for [common route parameters](../routing.md#specifying-route-parameters), it is also possible to implement your very own parameter types. This may be necessary if your routes have more complex matching requirements.

## Defining a route parameter

In order to implement custom parameters, you need to subclass the [`Marten::Routing::Parameter::Base`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html) abstract class. Each parameter class is responsible for:

* defining a [regex](https://crystal-lang.org/reference/master/syntax_and_semantics/literals/regex.html) allowing to match the parameters in raw paths (which can be done through the use of the [`#regex`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html#regex(regex)-macro) macro)
* defining _how_ the route parameter value should be deserialized (which can be done by implementing a [`#loads`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html#loads(value%3A%3A%3AString)-instance-method) method)
* defining _how_ the route parameter value should serialized (which can be done by implementing a [`#dumps`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html#dumps(value)%3A%3A%3AString%3F-instance-method) method)

The [`#loads`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html#loads(value%3A%3A%3AString)-instance-method) method takes the raw parameter (string) as argument and is expected to return the final Crystal object corresponding to the route parameter (this is the object that will be forwarded to the handler in the route parameters hash).

The [`#dumps`](pathname:///api/0.2/Marten/Routing/Parameter/Base.html#dumps(value)%3A%3A%3AString%3F-instance-method) method takes the final route parameter object as argument and must return the corresponding string representation. Note that this method can either return a string or `nil`: `nil` means that the passed value couldn't be serialized properly, which will make any URL reverse resolution fail with a `Marten::Routing::Errors::NoReverseMatch` error.

For example, a "year" (1000-2999) route parameter could be implemented as follows:

```crystal
class YearParameter < Marten::Routing::Parameter::Base
  regex /[12][0-9]{3}/

  def loads(value : ::String) : UInt64
    value.to_u64
  end

  def dumps(value) : Nil | ::String
    if value.as?(UInt8 | UInt16 | UInt32 | UInt64)
      value.to_s
    elsif value.is_a?(Int8 | Int16 | Int32 | Int64) && [1000..2999].includes?(value)
      value.to_s
    else
      nil
    end
  end
end
```

## Registering route parameters

In order to be able to use custom route parameters in your [route definitions](../routing.md#specifying-route-parameters), you must register them to Marten's global routing parameters registry.

To do so, you will have to call the [`Marten::Routing::Parameter#register`](pathname:///api/0.2/Marten/Routing/Parameter.html#register(id%3A%3A%3AString|Symbol%2Cparameter_klass%3ABase.class)-class-method) method with the identifier of the parameter you wish to use in route path definitions, and the actual parameter class. For example:

```crystal
Marten::Routing::Parameter.register(:year, YearParameter)
```

With the above registration, you could technically create the following route definition:

```crystal
Marten.routes.draw do
  path "/vintage/<vintage:year>", VintageHandler, name: "vintage"
end
```
