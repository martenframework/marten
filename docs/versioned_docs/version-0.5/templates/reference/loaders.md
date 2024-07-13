---
title: Template loaders
description: Template loaders reference.
---

This page provides a reference for all the available template loaders that can be used to customize template retrieval in Marten.

## FileSystem Loader

**Class**: [`Marten::Template::Loader::FileSystem`](pathname:///api/0.5/Marten/Template/Loader/FileSystem.html)

Loads templates directly from the file system.

Initialization example:

```crystal
loader = Marten::Template::Loader::FileSystem.new("/path/to/templates")
```

## AppDirs Loader

**Class**: [`Marten::Template::Loader::AppDirs`](pathname:///api/0.5/Marten/Template/Loader/AppDirs.html)

Coordinates template loading from application directories. Relies on instances of FileSystem.

Initialization example:

```crystal
loader = Marten::Template::Loader::AppDirs.new
```

## Cached Loader

**Class**: [`Marten::Template::Loader::Cached`](pathname:///api/0.5/Marten/Template/Loader/Cached.html)

Provides a caching layer for compiled templates. Can wrap other loaders to optimize retrieval.

Initialization example:

```crystal
file_loader = Marten::Template::Loader::FileSystem.new("/path/to/templates")
loader = Marten::Template::Loader::Cached.new([file_loader] of Marten::Template::Loader::Base)
```
