---
title: Template filters
description: Template filters reference.
---

This page provides a reference for all the available filters that can be used when defining [templates](../introduction.md).

## `capitalize`

The `capitalize` filter allows to modify a string so that the first letter is converted to uppercase and all the subsequent letters are converted to lowercase.

For example:

```html
{{ value|capitalize }}
```

If `value` is "marten", the output will be "Marten".

## `default`

The `default` filter allows to fallback to a specific value if the left side of the filter expression is not truthy. A filter argument is mandatory. It should be noted that empty strings are considered truthy and will be returned by this filter.

For example:

```html
{{ value|default:"foobar" }}
```

If `value` is `nil` (or `0` or `false`), the output will be "foobar".

## `downcase`

The `downcase` filter allows to convert a string so that each of its characters is lowercase.

For example:

```html
{{ value|downcase }}
```

If `value` is "Hello", then the output will be "hello".

## `linebreaks`

The `linebreaks` filter allows to convert a string replacing all newlines with HTML line breaks (`<br />`).

For example:

```html
{{ value|linebreaks }}
```

If `value` is `Hello\nWorld`, then the output will be `Hello<br />World`.

## `safe`

The `safe` filter allows to mark that a string is safe and that it should not be escaped before being inserted in the final output of a rendered template. Indeed, string values are always automatically HTML-escaped by default in templates.

For example:

```html
{{ value|safe }}
```

If `value` is `<p>Hello</p>`, then the output will be `<p>Hello</p>` as well.

## `size`

The `size` filter allows returning the size of a string or an enumerable object.

For example:

```html
{{ value|size }}
```

If `value` is `hello`, then the output will be 5.

## `upcase`

The `upcase` filter allows to convert a string so that each of its characters is uppercase.

For example:

```html
{{ value|upcase }}
```

If `value` is "Hello", then the output will be "HELLO".
