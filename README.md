# Marten

![logo](docs/static/img/hero.svg)

[![Version](https://img.shields.io/github/v/tag/martenframework/marten)](https://github.com/martenframework/marten/tags)
[![License](https://img.shields.io/github/license/martenframework/marten)](https://github.com/martenframework/marten/blob/main/LICENSE)
[![CI](https://github.com/martenframework/marten/workflows/Specs/badge.svg)](https://github.com/martenframework/marten/actions)
[![CI](https://github.com/martenframework/marten/workflows/QA/badge.svg)](https://github.com/martenframework/marten/actions)
[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://martenframework.com/chat)

---

**Marten** is a Crystal Web framework that enables pragmatic development and rapid prototyping. It 
provides a consistent and extensible set of tools that developers can leverage to build web applications without 
reinventing the wheel.

## Overview

### Key characteristics

**🎯 Simple** 

Marten's syntax is inherited from the slickness and simplicity of the Crystal programming language. On top of that, the framework tries to be KISS and DRY compliant as much as possible to reduce time-to-market.

**⚡ Fast**

Marten gives you the ability to build full-featured web applications by leveraging the bare metal performances of the Crystal programming language. It also tries to optimize for decent compile times.

**🧳 Full-featured**

Marten adheres to the "batteries included" philosophy. Out of the box, it provides the tools and features that are commonly required by web applications: ORM, migrations, translations, templating engines, sessions, emailing, authentication, etc.

**🔧 Extensible**

Marten gives you the ability to contribute extra functionalities to the framework easily. Things like custom model field implementations, new route parameter types, session stores, etc... can be registered to the framework easily.

**💠 App-oriented**

Marten allows separating projects into a set of logical "apps". These apps can also be extracted to contribute features and behaviors to other Marten projects. The goal here is to allow the creation of a powerful apps ecosystem over time.

**🛡️ Secure**

Marten comes with security mechanisms out of the box. Things like cross-site request forgeries, clickjacking, or SQL injections are taken care of by the framework to avoid common security issues.

### Batteries included

The tools you need are built into the framework. Database ORM, translations, migrations, templates, sessions, emailing, authentication, and many more can be leveraged right away.

**Design your models easily**

Marten comes with an object-relational-mapper (ORM) that you can leverage to describe your database using Crystal classes and a convenient DSL.

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

Templates provide a convenient way to define your presentation logic and to write contents (such as HTML) that are rendered dynamically. This rendering can involve model records or any other variables you define.

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

Online browsable documentation is available at [https://martenframework.com/docs](https://martenframework.com/docs).

## Getting started

Are you new to the Marten web framework? The following resources will help you get started:

* The [installation guide](https://martenframework.com/docs/getting-started/installation) will help you install Crystal and the Marten CLI
* The [tutorial](https://martenframework.com/docs/getting-started/tutorial) will help you discover the main features of the framework by creating a simple web application

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten/contributors).

## Acknowledgments

The Marten web framework initially draws its inspiration from [Django](https://www.djangoproject.com/) and [Ruby on Rails](https://rubyonrails.org/). You can browse the [Acknowledgments](https://martenframework.com/docs/the-marten-project/acknowledgments) section of the documentation to learn more about the various inspirations and contributions that helped shape Marten.

## License

MIT. See ``LICENSE`` for more details.
