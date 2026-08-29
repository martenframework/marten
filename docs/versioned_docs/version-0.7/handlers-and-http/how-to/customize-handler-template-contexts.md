---
title: Customize handler template contexts
sidebar_label: Customize handler contexts
description: How to customize handler template contexts.
---

This guide covers how to easily customize the [template context](../../templates/introduction.md) of handlers involving template renderings and how to add variables to it. Doing so will allow you to leverage custom variables in your handler templates and easily manipulate the appearance and content of your web pages, tailoring them to suit your specific needs and preferences.

## Requirements

It is possible to customize the template context used by most handlers involving template renderings. This is the case for:

* Handlers that make use of the [`#render`](../introduction.md#render) helper method.
* Handlers that inherit from the [`Marten::Handlers::Template`](../reference/generic-handlers.md#rendering-a-template), [`Marten::Handlers::Schema`](../reference/generic-handlers.md#processing-a-schema), [`Marten::Handlers::RecordCreate`](../reference/generic-handlers.md#creating-a-record), [`Marten::Handlers::RecordDetail`](../reference/generic-handlers.md#displaying-a-record), [`Marten::Handlers::RecordUpdate`](../reference/generic-handlers.md#updating-a-record), or [`Marten::Handlers::RecordDelete`](../reference/generic-handlers.md#deleting-a-record) generic handlers.

## Customizing the template context of a handler

If your handler adheres to the [requirements](#requirements) mentioned above, then the simplest way to customize what variables are made available to the considered template context is to leverage the [`#before_render`](../callbacks.md#before_render) callback.

This callback is invoked prior to rendering a template when generating a response that incorporates its content. This means that they can be used to add new variables to the [global handler template context](../introduction.md#global-template-context) so that they become accessible to the template runtime.

For example:

```crystal
class MyHandler < Marten::Handlers::Template
  template_name "app/my_template.html"
  before_render :add_foo_to_context

  private def add_foo_to_context : Nil
    context["foo"] = "bar"
  end
end
```

In the above snippet, a very simple handler (that inherits from the [`Marten::Handlers::Template`](../reference/generic-handlers.md#rendering-a-template) generic handler) defines a [`#before_render`](../callbacks.md#before_render) callback in which a `foo` variable is added to the template context.

## A concrete example: currently active link in navigation sections

To exemplify this functionality, let's consider a straightforward scenario involving navigation sections. Typically, it's essential to determine the currently active item within the navigation. This can be effortlessly accomplished by utilizing a dedicated template variable.

For example, let's assume that our navigation template looks something like this:

```html
<nav class="navbar navbar-light">
  <div class="container">
    <ul class="nav navbar-nav">
      <li class="nav-item">
        <a class="nav-link{% if nav_bar_item == 'home' %} active{% endif %}" href="/">Home</a>
      </li>
      <li class="nav-item">
        <a class="nav-link{% if nav_bar_item == 'sign_in' %} active{% endif %}" href="{% url 'auth:sign_in' %}">Sign in</a>
      </li>
      <li class="nav-item">
        <a class="nav-link{% if nav_bar_item == 'sign_up' %} active{% endif %}" href="{% url 'auth:sign_up' %}">Sign up</a>
      </li>
    </ul>
  </div>
</nav>
```

This template utilizes a `nav_bar_item` variable to determine the currently active navigation bar item and applies a dedicated `active` CSS class to the corresponding link based on the value of this variable.

In order for this navigation to work as intended, we need to ensure that the applicable handlers define the `nav_bar_item` template variables. We could utilize the method described previously and simply define a [`#before_render`](../callbacks.md#before_render) callback in the handlers that need to define this template variable. A better solution though would be to define a concern module that eases the process of doing this.

For example, we could define a `NavBarActiveable` module that automatically sets the `nav_bar_item` template variable based on the value of a class variable that is set by handler classes making use of it:

```crystal
module NavBarActiveable
  macro included
    class_getter nav_bar_item : String?

    extend NavBarActiveable::ClassMethods

    before_render :add_nav_bar_item_to_context
  end

  module ClassMethods
    def nav_bar_item(item : String | Symbol)
      @@nav_bar_item = item.to_s
    end
  end

  private def add_nav_bar_item_to_context
    context[:nav_bar_item] = self.class.nav_bar_item
  end
end
```

Using this approach, defining the `nav_bar_item` variable in a handler would be as simple as including the `NavBarActiveable` module in the handler class and calling the `#nav_bar_item` method:

```crystal
class MyHandler < Marten::Handlers::Template
  include NavBarActiveable

  template_name "app/my_template.html"
  nav_bar_item :home
end
```
