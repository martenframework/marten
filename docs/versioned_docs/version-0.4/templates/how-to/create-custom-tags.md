---
title: Create custom template tags
sidebar_label: Create custom tags
description: How to create custom template tags.
---

Marten has built-in support for common [template tags](../reference/tags.md), but the framework also allows you to write your own template tags that you can leverage as part of your project's templates.

## Defining a template tag

Template tags are subclasses of the [`Marten::Template::Tag::Base`](pathname:///api/0.4/Marten/Template/Tag/Base.html) abstract class. When writing custom template tags, you will usually want to define two methods in your tag classes: the `#initialize` and the `#render` methods. These two methods are called at different moments in a template's lifecycle:

* the `#initialize` method is used to initialize a template tag object and it is called at **parsing time**: this means that it is the responsibility of this method to ensure that the content of the template tag is valid from a parsing standpoint
* the `#render` method is called at **rendering time** to apply the tag's logic: this means that the method is only called for valid template tag statements that were parsed without errors

Since tags are created and processed when the template is parsed, they can theoretically be used to implement any kind of behavior. That being said, there are a few patterns that are frequently used when writing tags that you might want to consider to help you get started:

* **simple tags:** tags outputting a value that can (optionally) be assigned to a new variable
* **inclusion tags:** tags including and rendering other templates
* **closable tags:** tags involving closing statements and doing something with the output of a block

### Simple tags

Simple tags usually output a value while allowing this value to be assigned to a new variable (that will be added to the template context). They can eventually take arguments in order to return the right result at rendering time.

Let's take the example of a `local_time` template tag that outputs the string representation of the local time and that takes one mandatory argument (the [format](https://crystal-lang.org/api/Time/Format.html) used to output the time). Such a template tag could be implemented as follows:

```crystal
class LocalTimeTag < Marten::Template::Tag::Base
  include Marten::Template::Tag::CanSplitSmartly

  @assigned_to : String? = nil

  def initialize(parser : Marten::Template::Parser, source : String)
    parts = split_smartly(source)

    if parts.size < 2
      raise Marten::Template::Errors::InvalidSyntax.new(
        "Malformed local_time tag: one argument must be provided"
      )
    end

    @pattern_expression = Marten::Template::FilterExpression.new(parts[1])

    # Identify possible assigned variable name.
    if parts.size > 2 && parts[-2] == "as"
      @assigned_to = parts[-1]
    elsif parts.size > 2
      raise Marten::Template::Errors::InvalidSyntax.new(
        "Malformed local_time tag: only one argument must be provided"
      )
    end
  end

  def render(context : Marten::Template::Context) : String
    time_pattern = @pattern_expression.resolve(context).to_s

    local_time = Time.local(Marten.settings.time_zone).to_s(time_pattern)

    if @assigned_to.nil?
      local_time
    else
      context[@assigned_to.not_nil!] = local_time
      ""
    end
  end
end
```

As you can see template tags are initialized from a parser (instance of [Marten::Template::Parser](pathname:///api/0.4/Marten/Template/Parser.html)) and the raw "source" of the template tag (that is the content between the `{%` and `%}` tag delimiters). The `#initialize` method is responsible for extracting any information that might be necessary to implement the template tag's logic. In the case of the `local_time` template tag, we must take care of a few things:

* ensure that we have a format specified as argument (and raise an invalid syntax error otherwise)
* initialize a filter expression (instance of [Marten::Template::FilterExpression](pathname:///api/0.4/Marten/Template/FilterExpression.html)) from the format argument: this is necessary because the argument can be a string literal or variable with filters applied to it
* verify if the output of the template tag is assigned to a variable by looking for an `as` statement: if that's the case the name of the variable is persisted in a dedicated instance variable

The `#render` method is called at rendering time: it takes the current context object as argument and must return a string. In the above example, this method "resolves" the time format expression that was identified at initialization time from the context (which is necessary if it was a variable) and generates the right time representation. If the tag wasn't specified with an `as` variable, then this value is simply returned, otherwise, it is persisted in the context and an empty string is returned.

### Inclusion tags

Inclusion tags are similar to simple tags: they can take arguments (mandatory or not), and assign their outputs to variables, but the difference is that they render a template in order to produce the final output.

Let's take the example of a `list` template tag that outputs the elements of an array in a regular `ul` HTML tag. The template being rendered by such template tag could look like this:

```html title=path/to/list_tag.html
<ul>
  {% for item in list %}
    <li>{{ item }}</li>
  {% endfor %}
</ul>
```

And the template tag itself could be implemented as follows:

```crystal
class ListTag < Marten::Template::Tag::Base
  include Marten::Template::Tag::CanSplitSmartly

  @assigned_to : String? = nil

  def initialize(parser : Marten::Template::Parser, source : String)
    parts = split_smartly(source)

    if parts.size < 2
      raise Marten::Template::Errors::InvalidSyntax.new(
        "Malformed list tag: one argument must be provided"
      )
    end

    @list_expression = Marten::Template::FilterExpression.new(parts[1])

    # Identify possible assigned variable name.
    if parts.size > 2 && parts[-2] == "as"
      @assigned_to = parts[-1]
    elsif parts.size > 2
      raise Marten::Template::Errors::InvalidSyntax.new(
        "Malformed list tag: only one argument must be provided"
      )
    end
  end

  def render(context : Marten::Template::Context) : String
    template = Marten.templates.get_template("path/to/list_tag.html")

    rendered = ""

    context.stack do |include_context|
      include_context["list"] = @list_expression.resolve(context)
      rendered = template.render(include_context)
    end

    if @assigned_to.nil?
      Marten::Template::SafeString.new(rendered)
    else
      context[@assigned_to.not_nil!] = rendered
      ""
    end
  end
end
```

As you can see, the implementation of this tag looks quite similar to the one highlighted in [Simple tags](#simple-tags). The only differences that are worth noting here are:

1. the argument of the template tag corresponds to the list of items that should be rendered
2. the `#render` method explicitly renders the template mentioned previously by using a context with the "list" object in it (the [`#stack`](pathname:///api/0.4/Marten/Template/Context.html#stack(%26)%3ANil-instance-method) method allows to create a new context where new values are stacked over the existing ones). The output of this rendering operation is either assigned to a variable or returned directly depending on whether the `as` statement was used

### Closable tags

Closable tags involve a closing statement, like this is the case for the `{% block %}...{% endblock %}` template tag for example. Usually, such tags will "capture" all the nodes between the opening tag and the closing tag, render them at rendering time, and do something with the output of this rendering.

To illustrate this, let's take the example of a `spaceless` tag that will remove whitespaces, tabs and new lines between HTML tags. Such a template tag could be implemented as follows:

```crystal
class SpacelessTag < Marten::Template::Base
  @inner_nodes : Marten::Template::NodeSet

  def initialize(parser : Marten::Template::Parser, source : String)
    @inner_nodes = parser.parse(up_to: %w(endspaceless))
    parser.shift_token
  end

  def render(context : Marten::Template::Context) : String
    @inner_nodes.render(context).strip.gsub(/>\s+</, "><")
  end
end
```

In this example, the `#initialize` method explicitly calls the parser's [`#parse`](pathname:///api/0.4/Marten/Template/Parser.html#parse(up_to%3AArray(String)%3F%3Dnil)%3ANodeSet-instance-method) in order to parse the following "nodes" up to the expected closing tag (`endspaceless` in this case). If the specified closing tag is not encountered, the parser will automatically raise a syntax error. The obtained nodes are returned as a "node set" (instance of [`Marten::Template::NodeSet`](pathname:///api/0.4/Marten/Template/NodeSet.html)): this is a special object returned by the template parser that maps to multiple parsed nodes (those can be tags, variables, or plain text values) that can be rendered through a [`#render`](pathname:///api/0.4/Marten/Template/NodeSet.html#render(context%3AContext)-instance-method) method at rendering time.

The `#render` method of the above tag is relatively simple: it simply "renders" the node set corresponding to the template nodes that were extracted between the `{% spaceless %}...{% endspaceless %}` tags and then removes any whitespaces between the HTML tags in the output.

## Registering template tags

In order to be able to use custom template tags, you must register them to Marten's global template tags registry.

To do so, you will have to call the [`Marten::Template::Tag#register`](pathname:///api/0.4/Marten/Template/Tag.html#register(tag_name%3AString|Symbol%2Ctag_klass%3ABase.class)-class-method) method with the name of the tag you wish to use in templates, and the template tag class.

For example:

```crystal
Marten::Template::Tag.register("local_time", LocalTimeTag)
```

With the above registration, you could technically use this tag (the one from the above [Simple tags](#simple-tags) section) as follows:

```html
{% local_time "%Y-%m-%d %H:%M:%S %:z" %}
```
