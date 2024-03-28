---
title: Create custom template loaders
sidebar_label: Create custom loaders
description: How to create custom template loaders.
---

Marten has built-in support for [common template loaders](../reference/loaders.md), but the framework also allows you to write your own template loader that you can leverage as part of your project's templates.

## Defining a template loaders

Template loaders are subclasses of the [`Marten::Template::Loader::Base`](pathname:///api/dev/Marten/Template/Loader/Base.html) abstract class. They must implement a single `#get_template_source` method: this method returns the raw content of a template from a provided template name.

For example, rendering the template `content.html` with a file system loader initialised with `Marten::Template::Loader::FileSystem.new("/app/custom_dir/templates")` would return the content defined in `/app/custom_dir/templates/content.html`.

Let's say we want to write a `DatabaseTemplate` template loader: we first have to define a new class which inherits from `Marten::Template::Loader::Base`. This new class needs to define a `#get_template_source` method which takes a template_name string argument and also returns a string.

For simplicity we assume that there already exists a model `HtmlTemplate` with a `name` and `content` field:

```crystal
class DatabaseTemplate < Marten::Template::Loader::Base
  def get_template_source(template_name) : String
    begin
      return HtmlTemplate.get!(name: template_name).content.not_nil!
    rescue e : Marten::DB::Errors::RecordNotFound
      raise Marten::Template::Errors::TemplateNotFound.new("Template #{template_name} could not be found ; #{e.message}", e)
    end
  end
end
```
