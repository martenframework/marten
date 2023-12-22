---
title: Introduction to emails
description: Learn how to define emails in a Marten project and how to deliver them.
sidebar_label: Introduction
---

Marten lets you define emails in a very declarative way and gives you the ability to fully customize the content of these emails, their properties and associated header values, and obviously how they should be delivered.

## Email definition

Emails must be defined as subclasses of the [`Emailing::Email`](pathname:///api/0.3/Marten/Emailing/Email.html) abstract class and they usually live in an `emails` folder at the root of an application. These classes can define to which email addresses the email is sent (including CC or BCC addresses) and with which [templates](../templates.mdx) the body of the email (HTML or plain text) is rendered.

For example, the following snippet defines a simple email that is sent to a specific user's email address:

```crystal
class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  def initialize(@user : User)
  end
end
```

:::info
It is not necessary to systematically specify the `from` email address with the [`#from`](pathname:///api/0.3/Marten/Emailing/Email.html#from(value)-macro) macro. Indeed, unless specified, the default "from" email address that is defined in the [`emailing.from_address`](../development/reference/settings.md#from_address) setting is automatically used.
:::

In the above snippet, a `WelcomeEmail` email class is defined by inheriting from the [`Emailing::Email`](pathname:///api/0.3/Marten/Emailing/Email.html) abstract class. This email is initialized with a hypothetical `User` record, and this user's email address is used as the recipient email (through the use of the [`#to`](pathname:///api/0.3/Marten/Emailing/Email.html#to(value)-macro) macro). Other email properties are also defined in the above snippet, such as the "from" email address ([`#from`](pathname:///api/0.3/Marten/Emailing/Email.html#from(value)-macro) macro) and the subject of the email ([`#subject`](pathname:///api/0.3/Marten/Emailing/Email.html#subject(value)-macro) macro).

### Specifying email properties

Most email properties (eg. from address, recipient addresses, etc) can be specified in two ways:

* through the use of a dedicated macro
* by overriding a corresponding method in the email class

Indeed, it is convenient to define email properties through the use of the dedicated macros: [`#from`](pathname:///api/0.3/Marten/Emailing/Email.html#from(value)-macro) for the sender email, [`#to`](pathname:///api/0.3/Marten/Emailing/Email.html#to(value)-macro) for the recipient addresses, [`#cc`](pathname:///api/0.3/Marten/Emailing/Email.html#cc(value)-macro) for the CC addresses, [`#bcc`](pathname:///api/0.3/Marten/Emailing/Email.html#bcc(value)-macro) for the BCC addresses, [`#reply_to`](pathname:///api/0.3/Marten/Emailing/Email.html#reply_to(value)-macro) for the Reply-To address, and [`#subject`](pathname:///api/0.3/Marten/Emailing/Email.html#subject(value)-macro) for the email subject.

That being said, if more complicated logics need to be implemented to generate these email properties, it is perfectly possible to simply override the corresponding method in the considered email class. For example:

```crystal
class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  template_name "emails/welcome_email.html"

  def initialize(@user : User)
  end

  def subject
    if @user.referred?
      "Glad to see you here!"
    else
      "Welcome to the app!"
    end
  end
end
```

### Defining HTML and text bodies

The HTML body (and optionally text body) of the email is rendered using a [template](../templates.mdx) whose name can be specified by using the [`#template_name`](pathname:///api/0.3/Marten/Emailing/Email.html#template_name(template_name%3AString%3F%2Ccontent_type%3AContentType|String|Symbol%3DContentType%3A%3AHTML)%3ANil-class-method) class method. By default, unless explicitly specified, it is assumed that the template specified to this method is used for rendering the HTML body of the email. That being said, it is possible to explicitly specify for which content type the template should be used by specifying an optional `content_type` argument as follows:

```crystal
class WelcomeEmail < Marten::Email
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html", content_type: :html
  template_name "emails/welcome_email.txt", content_type: :text

  def initialize(@user : User)
  end
end
```

Note that it is perfectly valid to specify one template for rendering the HTML body AND another one for rendering the text body (like in the above example).

:::info
Note that you can define [`#html_body`](pathname:///api/0.3/Marten/Emailing/Email.html#html_body%3AString%3F-instance-method) and [`#text_body`](pathname:///api/0.3/Marten/Emailing/Email.html#html_body%3AString%3F-instance-method) methods if you need to override the logic that allows generating the HTML or text body of your email.
:::

### Defining custom headers

If you need to insert custom headers into your emails, then you can easily do so by defining a `#headers` method in your email class. This method must return a hash of string keys and values.

For example:

```crystal
class WelcomeEmail < Marten::Email
  to @user.email
  template_name "emails/welcome_email.html"

  def initialize(@user : User)
  end
  
  def headers
    {"X-Foo" => "bar"}
  end
end
```

## Sending emails

Emails are sent _synchronously_ through the use of the [`#deliver`](pathname:///api/0.3/Marten/Emailing/Email.html#deliver-instance-method). For example, the `WelcomeEmail` email defined in the previous sections could be initialized and delivered by doing:

```crystal
email = WelcomeEmail.new(user)
email.deliver
```

When calling [`#deliver`](pathname:///api/0.3/Marten/Emailing/Email.html#deliver-instance-method), the considered email will be delivered by using the currently configured [emailing backend](#emailing-backends).

## Emailing backends

Emailing backends define _how_ emails are actually sent when [`#deliver`](pathname:///api/0.3/Marten/Emailing/Email.html#deliver-instance-method) gets called. For example, a [development backend](./reference/backends.md#development-backend) might simply "collect" the sent emails and print their information to the standard output. Other backends might also integrate with existing email services or interact with an SMTP server to ensure email delivery.

Which backend is used when sending emails is something that is controlled by the [`emailing.backend`](../development/reference/settings.md#backend-1) setting. All the available emailing backends are listed in the [emailing backend reference](./reference/backends.md).

:::tip
If necessary, it is also possible to override which emailing backend is used on a per-email basis by leveraging the [`#backend`](pathname:///api/0.3/Marten/Emailing/Email.html#backend(backend%3ABackend%3A%3ABase)%3ANil-class-method) class method. For example:

```crystal
class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  backend Marten::Emailing::Backend::Development.new(print_emails: true)

  def initialize(@user : User)
  end
end
```
:::
