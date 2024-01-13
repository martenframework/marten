---
title: Create emailing backends
description: How to create custom emailing backends.
---

Marten lets you easily create custom [emailing backends](../introduction.md#emailing-backends) that you can then use as part of your application when it comes to sending emails.

## Basic backend definition

Defining an emailing backend is as simple as creating a class that inherits from the [`Marten::Emailing::Backend::Base`](pathname:///api/0.4/Marten/Emailing/Backend/Base.html) abstract class and that implements a unique `#deliver` method. This method takes a single `email` argument (instance of [`Marten::Emailing::Email`](pathname:///api/0.4/Marten/Emailing/Email.html)), corresponding to the email to deliver.

For example:

```crystal
class CustomEmailingBackend < Marten::Emailing::Backend::Base
  def deliver(email : Email)
    # Deliver the email!
  end
end
```

## Enabling the use of custom emailing backends

Custom emailing backends can be used by assigning an instance of the corresponding class to the [`emailing.backend`](../../development/reference/settings.md#backend-1) setting.

For example:

```crystal
config.emailing.backend = CustomEmailingBackend.new
```
