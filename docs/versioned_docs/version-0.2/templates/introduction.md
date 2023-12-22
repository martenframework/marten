---
title: Introduction to templates
description: Learn how to write templates and generate HTML dynamically.
sidebar_label: Introduction
---

Templates provide a convenient way for defining the presentation logic of a web application. They allow to write textual content that is rendered dynamically by using a dedicated syntax. This syntax enables the use of dynamic variables as well as some programming constructs.

## Syntax

A template is a textual document or a string that makes use of the Marten template language, and that can be used to generate _any_ text-based format (HTML, XML, etc). In order to insert dynamic content, templates usually make use of a few constructs such as **variables**, which are replaced by the corresponding values when the template is evaluated, and **tags**, which can be used to implement the logic of the template.

For example, the following template displays the properties of an `article` variable and loops over the associated comments in order to display them as a list:

```html
<h1>{{ article.title }}</h1>
<p>{{ article.content }}</p>
<ul>
{% for comment in article.comments %}
  <li>{{ comment.message }}</li>
{% else %}
  <li>No comments!</li>
{% endfor %}
</ul>
```

Templates need to be evaluated with a **context**. This context is usually a hash-like object containing all the variables or values that can be used by the template when it is rendered.

In the previous example, the template context would at least contain one `article` key giving access to the considered article properties.

### Variables

Variables can be used to inject a value from the context into the rendered template. They must be surrounded by **`{{`** and **`}}`**.

For example:

```html
Hello, {{ name }}!
```

If the context used to render the above template is `{"name" => "John Doe"}`, then the output would be "Hello, John Doe!".

Each variable can involve additional lookups in order to access specific object attributes (if such objects have ones). These lookups are expressed by relying on a dot notation (`foo.bar`). For example, the following snippet would output the `title` attribute of the `article` variable:

```html
<h1>{{ article.title }}</h1>
```

This notation can be used to call object methods but also to perform key lookups for hashes or named tuples. It can also be used to perform index lookups for indexable objects (such as arrays or tuples):

```
{{ my_array.0 }}
```

### Filters

Filters can be applied to [variables](#variables) or [tag](#tags) arguments in order to transform their values. They are applied to these variables or arguments through the use of a pipe (**`|`**) followed by the name of the filter.

For example, the following snippet will apply the [`capitalize`](./reference/filters.md#capitalize) filter to the output of the `name` variable, which will capitalize the value of this variable:

```html
Hello, {{ name|capitalize }}!
```

It should be noted that some filters can take an argument. When this is the case, the argument is specified following a colon character (**`:`**).

For example, the following snippet will apply the [`default`](./reference/filters.md#default) filter to the output of the `name` variable in order to fallback to a default name if the variable has a null value:

```html
Hello, {{ name|default:"Stranger" }}!
```

It should be noted that the fact that an argument is supported or not, and mandatory or not, varies based on the considered filter. In all cases, filters can support up to **one** argument only.

Please head over to the [filters reference](./reference/filters.md) to see a list of all the available filters. Implementing custom filters is also a possibility that is documented in [Create custom filters](./how-to/create-custom-filters.md).

### Tags

Tags allow to do method-calling and to run any kind of logic within a template. Some tags allow to perform control flows (like if conditions, or for loops) while others simply output values. They are delimited by **`{%`** and **`%}`**.

For example, the following snippet makes use of the [`assign`](./reference/tags.md#assign) tag to create a new variable within a template:

```html
{% assign my_var = "Hello World!" %}
```

As mentioned above, some tags allow to perform control flows and require a "closing" tag, like the [`for`](./reference/tags.md#for) or [`if`](./reference/tags.md#if) tags:

```html
{% for article in articles %}
  {{ article.title }} is {% if not article.published? %}not {% endif %}published
{% endfor %}
```

Some tags also require arguments. For example, the [`url`](./reference/tags.md#url) template tag requires at least the name of the route for which the URL resolution should be performed:

```html
{% url "my_route" %}
```

Please head over to the [tags reference](./reference/tags.md) to see a list of all the available template tags. Implementing custom tags is also a possibility that is documented in [Create custom tags](./how-to/create-custom-tags.md).

### Comments

Comments can be inserted in any templates and must be surrounded by **`{#`** and **`#}`**:

```html
{# This will not be evaluated #}
```

## Template inheritance

Templates can inherit from each other: this allows you to easily define a "base" template containing the layout of your application so that you can reuse it in order to build other templates, which helps in keeping your codebase DRY.

This works as follows:

* a "base" template defines the shared layout as well as "blocks" where child templates will actually inject their own contents
* "child" templates "extend" from the base template and explicitly define the contents of the "blocks" that are expected by the base template

For example, a "base" template could look like this:

```html
<html>
  <head>
    <title>{% block title %}My super website{% endblock %}</title>
  </head>
  <body>
    {% block content %}{% endblock %}
  </body>
</html>
```

Here the base template defines two blocks by using the [`block`](./reference/tags.md#block) template tag. Using this tag essentially makes it possible for any child templates to "override" the content of these blocks.

:::tip
Note that it is possible to specify the name of the block being closed in the `endblock` tag to improve readability. For example:

```html
{% block title %}
My super website
{% endblock title %}
````
:::

Given the above base template (that we assume is named `base.html`), a "child" template making use of it could look like this:

```html
{% extend "base.html" %}

{% block title %}Custom page title{% endblock %}

{% block content %}Custom page content{% endblock %}
```

Here we make use of the [`extend`](./reference/tags.md#extend) template tag in order to indicate that we want to inherit from the `base.html` template that we created previously. When Marten encounters this tag, it'll make sure that the targetted template is properly loaded before resuming the evaluation of the current template.

:::warning
The `{% extend %}` tag should always be called at the top of the file, before the actual content of the template. Inheritance won't work properly if that's not the case.
:::

We also use [`block`](./reference/tags.md#block) tags to redefine the content of the blocks that were defined in the `base.html` template. It should be noted that if a child template does not define the content of one of its parent's blocks, the default content of this block will be used instead (if there is one!).

:::info
You can use many levels of template inheritance if needed. Indeed, a `child.html` template can very well extend a `base_dashboard.html` template, which itself extends a `base.html` template for example.
:::

It should be noted that it is also possible to get the content of a block from a parent template by using the `super` template tag. This can be useful in situations where blocks in a child template need to extend (add content) to a parent's block content instead of overwriting it.

For example, with the following snippet the output of the `title` block would be "My super website - Example page":

```html
{% extend "base.html" %}

{% block title %}{% super %} - Example page{% endblock %}

{% block content %}Custom page content{% endblock %}
```

It's important to remember that the `super` template tag can only be used within `block` tags.

## Template loading

Templates can be loaded from specific locations within your codebase and from application folders. This is controlled by two main settings:

* [`templates.app_dirs`](../development/reference/settings.md#app_dirs-1) is a boolean that indicates whether or not it should be possible to load templates that are provided by [installed applications](../development/reference/settings.md#installed_apps). Indeed, applications can define a `templates` folder at their root, and these templates will be discoverable by Marten if this setting is set to `true`
* [`templates.dirs`](../development/reference/settings.md#dirs1) is an array of additional directories where templates should be looked for

Application templates are always enabled by default (`templates.app_dirs = true`) for new Marten projects.

It is possible to programmatically load a template by name. To do so, you can use the [`#get_template`](pathname:///api/0.2/Marten/Template/Engine.html#get_template(template_name%3AString)%3ATemplate-instance-method) method that is provided by the Marten templates engine:

```crystal
Marten.templates.get_template("foo/bar.html")
```

This will return a compiled [`Template`](pathname:///api/0.2/Marten/Template/Template.html) object that you can then render by using a specific context.

## Rendering a template

You won't usually need to interact with the "low-level" API of the Marten template engine in order to render templates: most of the time you will render templates as part of [handlers](../handlers-and-http.mdx), which means that you will likely end up using the [`#render`](../handlers-and-http/introduction.md#render) shortcut or [generic handlers](../handlers-and-http/generic-handlers.md) that automatically render templates for you.

That being said, it is also possible to render any [`Template`](pathname:///api/0.2/Marten/Template/Template.html) object that you loaded by leveraging the [`#render`](pathname:///api/0.2/Marten/Template/Template.html#render(context%3AHash|NamedTuple)%3AString-instance-method) method. This method can be used either with a Marten context object, a hash, or a named tuple:

```crystal
template = Marten.templates.get_template("foo/bar.html")
template.render(Marten::Template::Context{"foo" => "bar"})
template.render({"foo" => "bar"})
template.render({ foo: "bar" })
```

## Using custom objects in contexts

Most objects that are provided by Marten (such as Model records, query sets, schemas, etc) can automatically be used as part of templates. If your project involves other custom classes, and if you would like to interact with such objects in your templates, then you will need to explicitly ensure that they include the [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) module.

:::note Why?
Crystal being a statically typed language, the Marten engine needs to know which types of objects it is dealing with in advance in order to know (i) what can go into template contexts and (ii) how to "resolve" object attributes when templates are rendered. It is not possible to simply expect any `Object` object, hence why we need to make use of a shared [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) module to account for all the classes whose objects should be usable as part of template contexts.
:::

Let's take the example of a `Point` class that provides access to an x-coordinate and a y-coordinate:

```crystal
class Point
  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end
end
```

By default, `Point` objects cannot be used as part of templates. Let's say we want to render the following template involving a `point` variable:

```html
My point is: {{ point.x }}, {{ point.y }}
```

If you try to render such a template while passing a `Point` object into the template context, you will encounter a `Marten::Template::Errors::UnsupportedValue` exception stating:

```
Unable to initialize template values from Point objects
```

To remediate this, you will have to include the [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) module in the `Point` class and define a `#resolve_template_attribute` method as follows:

```crystal
class Point
  include Marten::Template::Object

  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end

  def resolve_template_attribute(key : String)
    case key
    when "x"
      x
    when "y"
      y
    end
  end
end
```

Each class including the [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) module must also implement a `#resolve_template_attribute` method in order to allow resolutions of object attributes when templates are rendered (for example `{{ point.x }}`). That being said, there are a few shortcuts that can be used in order to avoid writing such methods.

The first one is to use the [`#template_attributes`](pathname:///api/0.2/Marten/Template/Object.html#template_attributes(*names)-macro) macro in order to easily define the names of the methods that should be made available to the template runtime. For example, such macro could be used like this with our `Point` class:

```crystal
class Point
  include Marten::Template::Object

  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end

  template_attributes :x, :y
end
```

Another possibility is to include the [`Marten::Template::Object::Auto`](pathname:///api/0.2/Marten/Template/Object/Auto.html) module instead of the [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) one in your class. This module will automatically ensure that every "attribute-like" public method that is defined in the including class can also be accessed in templates when performing variable lookups.

```crystal
class Point
  include Marten::Template::Object::Auto

  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end
end
```

Note that **all** "attribute-like" public methods will be made available to the template runtime when using the [`Marten::Template::Object::Auto`](pathname:///api/0.2/Marten/Template/Object/Auto.html) module. This may be a good enough behavior, but if you want to have more control over what can be accessed in templates or not, you will likely end up using [`Marten::Template::Object`](pathname:///api/0.2/Marten/Template/Object.html) and the [`#template_attributes`](pathname:///api/0.2/Marten/Template/Object.html#template_attributes(*names)-macro) macro instead.

## Using context producers

Context producers are helpers that ensure that common variables are automatically inserted in the template context whenever a template is rendered. They are applied every time a new template context is generated.

For example, they can be used to insert the current HTTP request object in every template context being rendered in the context of a handler and HTTP request. This makes sense considering that the HTTP request object is a common object that is likely to be used by multiple templates in your project: that way there is no need to explicitly "insert" it in the context every time you render a template. This specific capability is provided by the [`Marten::Template::ContextProducer::Request`](pathname:///api/0.2/Marten/Template/ContextProducer/Request.html) context producer, which inserts a `request` object into every template context.

Template context producers can be configured through the use of the [`templates.context_producers`](../development/reference/settings.md#contextproducers) setting. When generating a new project by using the `marten new` command, the following context producers will be automatically configured:

```crystal
config.templates.context_producers = [
  Marten::Template::ContextProducer::Request,
  Marten::Template::ContextProducer::Flash,
  Marten::Template::ContextProducer::Debug,
  Marten::Template::ContextProducer::I18n,
]
```

Each context producer in this array will be applied in order when a new template context is created and will contribute "common" context values to it. This means that the order of these is important since context producers can technically overwrite the values that were added by previous context producers.

Please head over to the [context producers reference](./reference/context-producers.md) to see a list of all the available context producers. Implementing custom context producers is also a possibility that is documented in [Create custom context producers](./how-to/create-custom-context-producers.md).

## Auto-escaping

The output of template variables is automatically escaped by Marten in order to prevent Cross-Site Scripting (XSS) vulnerabilities.

For example, let's consider the following snippet:

```html
Hello, {{ name }}!
```

If this template is rendered with `<script>alert('popup')</script>` as the content of the `name` variable, then the output will be:

```html
Hello, &lt;script&gt;alert(&#39;popup&#39;)&lt;/script&gt;!
```

It should be noted that this behavior can be disabled _explicitly_. Indeed, sometimes it is expected that some template variables will contain trusted HTML content that you intend to embed into the template's HTML.

To do this, it is possible to make use of the [`safe`](./reference/filters.md#safe) template filter. This filter "marks" the output of a variable as safe, which ensures that its content is not escaped before being inserted in the final output of a rendered template.

For example:

```html
Hello, {{ name }}!
Hello, {{ name|safe }}!
```

When rendered with `<b>John</b>` as the content of the `name` variable, the above template will output:

```html
Hello, &lt;b&gt;John&lt;/b&gt;!
Hello, <b>John</b>!
```
