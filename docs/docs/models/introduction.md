---
title: Introduction to models
sidebar_label: Introduction
---

Models define what data can be persisted and manipulated by a Marten application. They explicitly specify fields and rules that map to database tables. As such they correspond to the layer of the framework that is responsible for representing business data and logic.

## Basic model definition

Marten models must be defined as subclasses of the `Marten::Model` base class; they explicitly define "fields" through the use of the `field` macro. These classes and fields map to database tables and columns that can be queried through the use of an automatically-generated database access API (see [Queries](./queries) for more details).

For example, the following code snippet defines a simple `Article` model:

```crystal
class Article < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :title, :string, max_size: 255
  field :content, :text
end
```

In the above example, `id`, `title`, and `content` are fields of the `Article` model. Each of these fields map to a database column in a table whose name that is automatically inferred from the model name.

## Model fields

## Migrations

## Validations

## Callbacks
