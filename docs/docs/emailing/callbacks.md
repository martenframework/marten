---
title: Email callbacks
description: Learn how to define email callbacks.
sidebar_label: Callbacks
---

Callbacks enable you to define logic that is triggered at different stages of an email's lifecycle. This document covers the available callbacks and introduces you to the associated API, which you can use to define hooks in your emails.

## Overview

As stated above, callbacks are methods that will be called when specific events occur for a specific email instance. They need to be registered explicitly in your email classes.

Registering a callback is as simple as calling the right callback macro (eg. `#before_deliver`) with a symbol of the name of the method to call when the callback is executed.

For example, the following email leverages the [`#after_deliver`](#after_deliver) callback in order to emit a specific StatsD metric:

```crystal
require "statsd"

statsd = Statsd::Client.new

class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  after_deliver :emit_delivered_welcome_email_metric

  def initialize(@user : User)
  end

  private def emit_delivered_welcome_email_metric
    statsd.increment "email.welcome.delivered", tags: ["app:myapp"]
  end
end
```

## Available callbacks

### `before_deliver`

`before_deliver` callbacks are executed _before_ an email is delivered (as part of the email's [`#deliver`](pathname:///api/dev/Marten/Emailing/Email.html#deliver-instance-method) method). For example, this capability can be leveraged to mutate the considered email instance before the actual email gets delivered:

```crystal
class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  before_deliver :set_header

  def initialize(@user : User)
  end

  private def set_header
    headers["X-Debug"] = "True" if Marten.env.staging?
  end
end
```

### `after_deliver`

`after_deliver` callbacks are executed _after_ an email is delivered (as part of the email's [`#deliver`](pathname:///api/dev/Marten/Emailing/Email.html#deliver-instance-method) method). For example, such callbacks can be leveraged to increment email-specific metrics:

```crystal
require "statsd"

statsd = Statsd::Client.new

class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  after_deliver :emit_delivered_welcome_email_metric

  def initialize(@user : User)
  end

  private def emit_delivered_welcome_email_metric
    statsd.increment "email.welcome.delivered", tags: ["app:myapp"]
  end
end
```

### `before_render`

`before_render` callbacks are invoked prior to rendering a template when generating the HTML or text body of the email. This means that these callbacks are executed when calling either the [`#deliver`](pathname:///api/dev/Marten/Emailing/Email.html#deliver-instance-method), [`#html_body`](pathname:///api/dev/Marten/Emailing/Email.html#html_body%3AString|Nil-instance-method), or [`#text_body`](pathname:///api/dev/Marten/Emailing/Email.html#text_body%3AString|Nil-instance-method) methods.

Typically, these callbacks can be used to add new variables to the global email template context, in order to make them available to the template runtime. This can be useful if your email has some instance variables that you want to expose to your email template. For example:

```crystal
class WelcomeEmail < Marten::Email
  from "no-reply@martenframework.com"
  to @user.email
  subject "Hello!"
  template_name "emails/welcome_email.html"

  before_render :prepare_context

  def initialize(@user : User)
  end

  private def prepare_context
    context[:user] = @user
  end
end
```
