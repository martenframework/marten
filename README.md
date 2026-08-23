# Marten

![logo](https://raw.githubusercontent.com/martenframework/marten/main/docs/static/img/hero.png)

[![Version](https://img.shields.io/github/v/tag/martenframework/marten?label=Version)](https://github.com/martenframework/marten/tags)
[![License](https://img.shields.io/github/license/martenframework/marten?label=License)](https://github.com/martenframework/marten/blob/main/LICENSE)
[![CI](https://github.com/martenframework/marten/actions/workflows/specs.yml/badge.svg?branch=main)](https://github.com/martenframework/marten/actions)
[![CI](https://github.com/martenframework/marten/actions/workflows/qa.yml/badge.svg?branch=main)](https://github.com/martenframework/marten/actions)
[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://martenframework.com/chat)

---

**Marten** is a batteries-included web framework for Crystal. It provides a consistent and extensible set of tools that developers can leverage to build complete web applications without reinventing the wheel.

## Overview

### Key characteristics

**🧳 Batteries included**

Marten adheres to the "batteries included" philosophy. Out of the box, it provides the tools and features that are commonly required by web applications: ORM, migrations, translations, templating engines, sessions, emailing, authentication, etc.

**🧩 Consistent**

Marten's components are designed to work together and follow consistent conventions across the framework, making its APIs predictable and easy to learn.

**🔧 Extensible**

Marten gives you the ability to contribute extra functionalities to the framework easily. Things like custom model field implementations, new route parameter types, session stores, etc. can be registered with the framework.

**💠 App-oriented**

Marten allows separating projects into a set of logical "apps". These apps can also be extracted to contribute features and behaviors to other Marten projects. This provides a foundation for developing and distributing reusable Marten applications.

**⚡ Fast**

Marten gives you the ability to build full-featured web applications while leveraging the native performance of the Crystal programming language. It also aims to keep compile times under control.

**🛡️ Secure by default**

Marten comes with security mechanisms out of the box. Things like cross-site request forgeries, clickjacking, or SQL injections are taken care of by the framework to avoid common security issues.

### Marten at a glance

**Design your models easily**

Marten comes with an object-relational mapper (ORM) that you can leverage to describe your database using Crystal classes and a convenient DSL.

```crystal
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 128
  field :content, :text
  field :author, :many_to_one, to: User
end
```

**Process requests with handlers**

Handlers are responsible for processing web requests and for returning responses. This can involve loading records from the database, rendering HTML templates, or producing JSON payloads.

```crystal
class ArticleListHandler < Marten::Handler
  def get
    render "articles/list.html", { articles: Article.all }
  end
end
```

**Render user-facing content with templates**

Templates provide a convenient way to define your presentation logic and to write content (such as HTML) that is rendered dynamically. This rendering can involve model records or any other variables you define.

```html
{% extend "base.html" %}
{% block content %}
<ul>
  {% for article in articles %}
    <li>{{ article.title }}</li>
  {% endfor %}
</ul>
{% endblock content %}
```

## Documentation

Documentation is available at [https://martenframework.com/docs](https://martenframework.com/docs).

## Getting started

Are you new to the Marten web framework? The following resources will help you get started:

* The [installation guide](https://martenframework.com/docs/getting-started/installation) will help you install Crystal and the Marten CLI
* The [tutorial](https://martenframework.com/docs/getting-started/tutorial) will help you discover the main features of the framework by creating a simple web application

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten/contributors).

## Acknowledgments

The Marten web framework initially drew its inspiration from [Django](https://www.djangoproject.com/) and [Ruby on Rails](https://rubyonrails.org/). You can browse the [Acknowledgments](https://martenframework.com/docs/the-marten-project/acknowledgments) section of the documentation to learn more about the various inspirations and contributions that helped shape Marten.

## License

MIT. See ``LICENSE`` for more details.
