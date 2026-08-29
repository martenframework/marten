---
title: Operators
description: Operators reference.
---

This page provides a reference for all the available operators that can be used when defining conditions in templates with the [`if`](./tags.md#if) and [`unless`](./tags.md#unless) tags.

## Equality and comparison operators

The following equality and comparison operators can be used:

| Operator | Description |
| -------- | ----------- |
| `==` | Equals |
| `!=` | Not equals |
| `>` | Greater than |
| `>=` | Greater than or equals |
| `<` | Less than |
| `<=` | Greater than or equals |

For example:

```html
{% if my_var == 0 %}
  Zero!
{% elsif my_var >= 1 %}
  One or greater!
{% else %}
  Other!
{% endif %}
```

## Logical operators

The following logical operators can be used:

| Operator | Description |
| -------- | ----------- |
| `&&` | Logical AND |
| `\|\|` | Logical OR |
| `!` or `not` | Logical negation |

For example:

```html
{% if my_var == 0 %}
  Zero!
{% elsif my_var == 1 && other_var == "foobar" %}
  One!
{% elsif !additional_var %}
  Something else!
{% else %}
  Other!
{% endif %}
```

## Inclusion operator

The `in` operator is the inclusion operator that can be used in [`if`](./tags.md#if) or [`unless`](./tags.md#unless) conditions. This operator allows to check for the presence of a substring in another string or for the presence of a value in an array or tuple.

For example:

```html
{% if "Top 10" in blog.title %}
Top 10 blog article
{% endif %}

{% if "red" in colors %}
Red color available
{% endif %}
```
