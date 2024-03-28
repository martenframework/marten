---
title: Template loaders
description: Template loaders reference.
---

This page provides a reference for all the available template loaders that can be used to customize template retrieval in Marten.

## FileSystem Loader

**Class**: [`Marten::Template::Loader::FileSystem`](pathname:///api/dev/Marten/Template/Loader/FileSystem.html)

Loads templates directly from the file system.

## AppDirs Loader

**Class**: [`Marten::Template::Loader::AppDirs`](pathname:///api/dev/Marten/Template/Loader/AppDirs.html)

Coordinates template loading from application directories. Relies on instances of FileSystem.

## Cached Loader

**Class**: [`Marten::Template::Loader::Cached`](pathname:///api/dev/Marten/Template/Loader/Cached.html)

Provides a caching layer for compiled templates. Can wrap other loaders to optimize retrieval.

