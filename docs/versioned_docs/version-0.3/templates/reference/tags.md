---
title: Template tags
description: Template tags reference.
---

## `asset`

The `asset` template tag allows to generate the URL of a given [asset](../../assets/introduction.md). It must take at least one argument (the filepath of the asset).

For example, the following line is a valid usage of the `asset` tag and will output the path or URL of the `app/app.css` asset:

```html
{% asset "app/app.css" %}
```

Optionally, resolved asset URLs can be assigned to a specific variable using the `as` keyword:

```html
{% asset "app/app.css" as my_var %}
```

## `assign`

The `assign` template tag allows to define a new variable that will be stored in the template's context.

For example:

```html
{% assign my_var = "Hello World!" %}
```

## `block`

The `block` template tag allows to define that some specific portions of a template can be overridden by child templates. This tag is only useful when used in conjunction with the [`extend`](#extend) tag. See [Template inheritance](../introduction.md#template-inheritance) to learn more about this capability.

## `cache`

The `cache` template tag allows to cache the content of a template fragment (enclosed within the `{% cache %}...{% endcache %}` tags) for a specific duration. This caching operation is done by leveraging the configured [cache store](../../caching/introduction.md#configuration-and-cache-stores).

At least a cache key and and a cache expiry (expressed in seconds) must be specified when using this tag:

```html
{% cache "mykey" 3600 %}
  Cached content!
{% endcache %}
```

It should be noted that the `cache` template tag also supports specifying additional "vary on" arguments that allow to invalidate the cache based on the value of other template variables:

```html
{% cache "mykey" 3600 current_locale user.id %}
  Cached content!
{% endcache %}
```

## `csrf_token`

The `csrf_token` template tag allows to compute and insert the value of the CSRF token into a template. This tag can only be used for templates that are rendered as part of a handler (for example by leveraging [`#render`](../../handlers-and-http/introduction.md#render) or one of the [generic handlers](../../handlers-and-http/generic-handlers.md) involving rendered templates).

This can be used to insert the CSRF token into a hidden form input so that it gets sent to the handler processing the form data for example. Indeed, handlers will automatically perform a CSRF check in order to protect unsafe requests (ie. requests whose methods are not `GET`, `HEAD`, `OPTIONS`, or `TRACE`):

```html
<form method="post" action="" enctype="multipart/form-data">
  <input type="hidden" name="csrftoken" value="{% csrf_token %}" />
  <input type="text" name="test" />
  <button>Submit</button>
</form>
```

See [Cross-Site Request Forgery protection](../../security/csrf.md) to learn more about this.

## `extend`

The `extend` template tag allows to define that a template inherits from a specific base template. This tag must be used with one mandatory argument, which can be either a string literal or a variable that will be resolved at runtime. This mechanism is useful only if the base template defines [blocks](#block) that are overridden or extended by the child template. See [Template inheritance](../introduction.md#template-inheritance) to learn more about this capability.

## `for`

The `for` template tag allows to loop over the items of iterable objects and it also handles fallbacks through the use of the `else` inner block. It should be noted that the `for` template tag requires a closing `endfor` tag.

For example:

```html
{% for item in items %}
  Display {{ item }}
{% else %}
  No items!
{% endfor %}
```

It should be noted that `for` loops support unpacking multiple items when applicable (eg. when iterating over hashes or enumerables containing arrays or tuples):

```html
{% for label, url in navigation_items %}
  <a href="{{ url }}">{{ label }}</a>
{% endfor %}
```

Finally, loops give access to a special `loop` variable _inside_ the loop in order to expose information about the iteration process:

| Variable | Description |
| -------- | ----------- |
| `loop.index` | The index of the current iteration (1-indexed) |
| `loop.index0` | The index of the current iteration (0-indexed) |
| `loop.revindex` | The index of the current iteration counting from the end of the loop (1-indexed) |
| `loop.revindex0` | The index of the current iteration counting from the end of the loop (0-indexed) |
| `loop.first?` | A boolean indicating if this is the first iteration of the loop |
| `loop.last?` | A boolean indicating if this is the last iteration of the loop |
| `loop.parent` | The parent's `loop` variable (only for nested for loops) |

## `if`

The `if` template tags allows to define conditions allowing to control which blocks should be executed. An `if` tag must always start with an `if` condition, followed by any number of intermediate `elsif` conditions and an optional (and final) `else` block. It also requires a closing `endif` tag.

For example:

```html
{% if my_var == 0 %}
  Zero!
{% elsif my_var == 1 %}
  One!
{% else %}
  Other!
{% endif %}
```

## `include`

The `include` template tag allows to include and render another template using the current context. This tag must be used with one mandatory argument: the name of the template to include, which can be either a string literal or a variable that will be resolved at runtime.

For example:

```html
{% include "path/to/my_snippet.html" %}
```

Included templates are rendered using the context of the including template. This means that all the variables that are expected or provided to the including template can also be used as part of the included template.

For example:

```html title="hello.html"
Hello, {{ name }}! {% include "question.html" %}
```

```html title="question.html"
How are you {{ name }}?
```

If `name` is "John", then the output will be "Hello, John! How are you John?".

Finally, it should be noted that additional variables that are specific to the included template only can be specified using the `with` keyword:

```html
{% include "path/to/my_snippet.html" with new_var="hello" %}
```

:::caution
Templates that are included using the `include` template are parsed and rendered _when_ the including template is rendered as well. Included templates are not parsed when the including template is parsed itself. This means that the including template and the included template are always rendered _separately_.
:::

## `local_time`

The `local_time` template tag allows to output the string representation of the local time. It must take one argument (the [format](https://crystal-lang.org/api/Time/Format.html) used to output the time).

For example, the following lines are valid usages of the `local_time` tag:

```html
{% local_time "%Y" %}
{% local_time "%Y-%m-%d %H:%M:%S %:z" %}
```

Optionally, the output of this tag can be assigned to a specific variable using the `as` keyword:

```html
{% local_time "%Y" as current_year %}
```

## `spaceless`

The `spaceless` template tag allows to remove whitespaces, tabs, and new lines between HTML tags. Whitespaces inside tags are left untouched. It should be noted that the `spaceless` template tag requires a closing `endspaceless` tag.

For example:

```html
{% spaceless %}
    <p>
        <a href="/sign-in">Sign In</a>
    </p>
{% endspaceless %}
```

Would output the following:

```html
<p><a href="/sign-in">Sign In</a></p>
```

## `super`

The `super` template tag allows to render the content of a block from a parent template (in a situation where both the `extend` and `block` tags are used). This can be useful in situations where blocks in a child template need to extend (add content) to a parent's block content instead of overwriting it. See [Template inheritance](../introduction.md#template-inheritance) to learn more about this capability.

## `translate`

The `translate` template tag allows to perform translation lookups by using the [I18n configuration](../../development/reference/settings.md#i18n-settings) of the project. It must take at least one argument (the translation key) followed by keyword arguments.

For example the following lines are valid usages of the `translate` tag:

```html
{% translate "simple.translation" %}
{% translate "simple.interpolation" value: 'test' %}
```

Translation keys and parameter values can be resolved as template variables too, but they can also be defined as literal values if necessary.

Optionally, resolved translations can be assigned to a specific variable using the `as` keyword:

```html
{% translate "simple.interpolation" value: 'test' as my_var %}
```

## `trans`

Alias for [`translate`](#translate).

## `t`

Alias for [`translate`](#translate).

## `url`

The `url` template tag allows to perform [URL lookups](../../handlers-and-http/routing.md#reverse-url-resolutions). It must take at least one argument (the name of the targeted handler) followed by optional keyword arguments (if the route requires parameters).

For example, the following lines are valid usages of the `url` tag:

```html
{% url "my_handler" %}
{% url "my_other_handler" arg1: var1, arg2: var2 %}
```

URL names and parameter values can be resolved as template variables too, but they can also be defined as literal values if necessary.

Optionally, resolved URLs can be assigned to a specific variable using the `as` keyword:

```html
{% url "my_other_handler" arg1: var1, arg2: var2 as my_var %}
```

## `verbatim`

The `verbatim` template tag prevents the content of the tag to be processed by the template engine. It should be noted that the `verbatim` template tag requires a closing `endverbatim` tag.

For example:

```
{% verbatim %}
  This should not be {{ processed }}.
{% endverbaim %}
```

Would output `This should not be {{ processed }}.`.
