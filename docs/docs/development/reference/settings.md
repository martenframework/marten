---
title: Settings
description: Settings reference.
sidebar_label: Settings
---

This page provides a reference for all the available settings that can be used to configure Marten projects.

## Common settings

### `allowed_hosts`

Default: `[] of String`

An explicit array of allowed hosts for the application.

The application has to be explictely configured to serve a list of allowed hosts. This is to mitigate HTTP Host header attacks. The strings in this array can correspond to regular domain names or subdomains (eg. `example.com` or `www.example.com`); when this is the case the Host header of the incoming request will be checked to ensure that it exactly matches one of the configured allowed hosts.

It is also possible to match all the subdomains of a specific domain by specifying prepending a `.` at the beginning of host string. For example `.example.com` will matches `example.com`, `www.example.com`, `sub.example.com`, or any other subdomains. Finally the special `*` string can be used to match any Host value, but this wildcard value should be used with caution as you wouldn't be protected against Host header attacks.

It should be noted that this setting is automatically set to the following array when a project is running in [debug mode](#debug) (unless it is explicitly set):

```crystal
[".localhost", "127.0.0.1", "[::1]"]
```

### `debug`

## Assets settings

## CSRF settings

## Database settings

## I18n settings

## Sessions settings

## Templates settings
