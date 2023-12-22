---
title: Security in Marten
description: Learn about the main security features provided by the Marten framework.
sidebar_label: Introduction
---

This document describees the main security features that are provided by the Marten web framework.

## Cross-Site Request Forgery protection

Cross-Site Request Forgery (CSRF) attacks generally involve a malicious website trying to perform actions on a web application on behalf of an already authenticated user.

Marten comes with a built-in [CSRF protection mechanism](./csrf.md) that is automatically enabled for your [handlers](../handlers-and-http.mdx). The use of this CSRF protection mechanism is controlled by a set of [dedicated settings](../development/reference/settings.md#csrf-settings).

:::caution
You should be careful when tweaking those settings and avoid disabling this protection unless this is absolutely necessary.
:::

The CSRF protection provided by Marten is based on the verification of a token that must be provided for each unsafe HTTP request (ie. requests whose methods are not `GET`, `HEAD`, `OPTIONS`, or `TRACE`). This token is stored in the client cookies and it must be specified when submitting unsafe requests (either in the data itself or using a specific header): if the tokens are not valid, or if the cookie-based token does not match the one provided in the data, then this means that the request is malicious and that it must be rejected.

You can learn about the CSRF protection provided by Marten and the associated tools in the [dedicated documentation](./csrf.md).

## Clickjacking protection

Clickjacking attacks involve a malicious website embedding another unprotected website in a frame. This can lead to users performing unintended actions on the targeted website.

Marten comes with a built-in [clickjacking protection mechanism](./clickjacking.md), that involves using a dedicated middleware (the [X-Frame-Options middleware](../handlers-and-http/reference/middlewares.md#x-frame-options-middleware)). This middleware is always automatically enabled for projects that are generated via the [`new`](../development/reference/management-commands.md#new) management command and, as its name implies, it involves setting the X-Frame-Options header in order to prevent the considered Marten website from being inserted into a frame.

You can learn about the clickjacking protection provided by Marten and the associated tools in the [dedicated documentation](./clickjacking.md).

## Cross Site Scripting protection

Cross Site Scripting (XSS) attacks involve a malicious user injecting client-side scripts into the browser of another user. This usually happens when rendering database-stored HTML data or when generating HTML contents and displaying it in a browser: if these HTML contents are not properly sanitized, then this can allow an attacker's JavaScript to be executed in the browser.

To prevent this, Marten [templates](../templates.mdx) automatically escape HTML contents in variable outputs, unless those are marked as "safe". You can learn more about this capability in [Auto-Escaping](../templates/introduction.md#auto-escaping).

It should be noted that this auto-escaping mechanism can be disabled using a specific [filter](../templates/reference/filters.md#safe) if needed, but you should be aware of the risks while doing so and ensure that your HTML contents are properly sanitized in order to avoid XSS vulnerabilities.

## HTTP Host Header attacks protection

HTTP Host Header attacks happen when websites that handle the value of the Host header (eg. in order to generate fully qualified URLs) trust this header value implicitly and don't verify it.

Marten implements a protection mechanism against this type of attack by validating the Host header against a set of explicitly allowed hosts that must be specified in the [`allowed_hosts`](../development/reference/settings.md#allowed_hosts) setting. The X-Forwarded-Host header can also be used to determine the host if the use of this header is enabled ([`use_x_forwarded_host`](../development/reference/settings.md#use_x_forwarded_host) setting).

## SQL injection protection

SQL injection attacks happen when a malicious user is able to execute arbitrary SQL queries on a database, which usually occurs when submitting input data to a web application. This can lead to database records being leaked and/or altered.

The [query sets](../models-and-databases/queries.md) API provided by Marten generates SQL code by using query parameterization. This means that the actual code of a query is defined separately from its parameters, which ensures that any user-provided parameter is escaped by the considered database driver before the query is executed.

## Content Security Policy

The [Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) (CSP) header is a collection of guidelines that the browser follows to allow specific sources for scripts, styles, embedded content, and more. It ensures that only these approved sources are allowed while blocking all other sources.

Marten comes with a built-in [Content Security Policy mechanism](./content-security-policy.md), that involves using a dedicated middleware (the [Content-Security-Policy middleware](../handlers-and-http/reference/middlewares.md#content-security-policy-middleware)). This middleware guarantees the presence of the Content-Security-Policy header in the response's headers.

You can learn about the Content-Security-Policy header and how to configure it in the [dedicated documentation](./content-security-policy.md).
