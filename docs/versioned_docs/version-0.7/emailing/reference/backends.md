---
title: Emailing backends
description: Emailing backends reference.
sidebar_label: Backends
---

## Built-in backends

### Development backend

This is the default backend used as part of the [`emailing.backend`](../../development/reference/settings.md#backend-1) setting.

This backend "collects" all the emails that are "delivered", which can be used in specs in order to test sent emails. This "collect" behavior can be disabled if necessary, and the backend can also be configured to print email details to the standard output.

For example:

```crystal
config.emailing.backend = Marten::Emailing::Backend::Development.new(print_emails: true, collect_emails: false)
```

## Other backends

Additional emailing backend shards are also maintained under the umbrella of the Marten project or by the community itself and can be used as part of your application depending on your specific email sending requirements:

* [`marten-smtp-emailing`](https://github.com/martenframework/marten-smtp-emailing) provides an SMTP emailing backend
* [`marten-sendgrid-emailing`](https://github.com/martenframework/marten-sendgrid-emailing) provides a [Sendgrid](https://sendgrid.com/) emailing backend
* [`marten-mailgun-emailing`](https://github.com/martenframework/marten-mailgun-emailing) provides a [Mailgun](https://www.mailgun.com/) emailing backend

:::info
Feel free to contribute to this page and add links to your shards if you've created emailing backends that are not listed here!
:::
