---
title: Clickjacking protection
description: Learn about clickjacking and how Marten helps protect against this type of attacks.
---

This document describes Marten's clickjacking protection mechanism as well as the various tools that you can use in order to configure and make use of it.

## Overview

Clickjacking attacks involve a malicious website embedding another unprotected website in a frame. This can lead to users performing unintended actions on the targeted website.

The best way to mitigate this risk is to rely on the X-Frame-Options header: this header indicates whether or not the protected resource is allowed to be embedded into a frame, and if so under which conditions. The X-Frame-Options header can be set to `DENY` or `SAMEORIGIN`:

* `DENY` means that the response cannot be displayed inside a frame at all
* `SAMEORIGINS` means that the browser will allow the response to be displayed inside a frame if the site defining the frame is the same as the one serving the actual resource

## Basic usage

Marten's clickjacking protection involves using a dedicated middleware: the [X-Frame-Options middleware](../handlers-and-http/reference/middlewares.md#x-frame-options-middleware). This middleware is automatically added to the [`middleware`](../development/reference/settings.md#middleware) setting when generating projects via the [`new`](../development/reference/management-commands.md#new) management command.

The [X-Frame-Options middleware](../handlers-and-http/reference/middlewares.md#x-frame-options-middleware) simply sets the X-Frame-Options header in order to prevent the considered Marten website from being inserted into a frame. The value that is used for the X-Frame-Options header depends on the value of the [`x_frame_options`](../development/reference/settings.md#x_frame_options) setting (whose default value is `DENY`).

It should be noted that you can decide to disable or enable the use of the [X-Frame-Options middleware](../handlers-and-http/reference/middlewares.md#x-frame-options-middleware) on a per-handler basis. To do so, you can simply make use of the [`#exempt_from_x_frame_options`](pathname:///api/dev/Marten/Handlers/XFrameOptions/ClassMethods.html#exempt_from_x_frame_options(exempt%3ABool)%3ANil-instance-method) class method, which takes a single boolean as arguments:

```crystal
class ProtectedHandler < Marten::Handler
  exempt_from_x_frame_options false

  # [...]
end

class UnprotectedHandler < Marten::Handler
  exempt_from_x_frame_options true

  # [...]
end
```
