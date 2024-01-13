---
title: Managing files
description: Learn how to manage uploaded files.
sidebar_label: Managing files
---

Marten gives you the ability to associate uploaded files with model records and to fully customize how and where those files are persisted. This section covers the basics of using files with models, how to interact with file objects, and introduces the concept of file storage.

## Using files with models

You can make use of the [`file`](../models-and-databases/reference/fields.md#file) field when defining models: this allows to associate an uploaded file with specific model records.

For example, let's consider the following model:

```crystal
class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, blank: false, null: false
end
```

Any `Attachment` model record will have a `file` attribute allowing interacting with the attached file:

```crystal
attachment = Attachment.first!
attachment.file           # => #<Marten::DB::Field::File::File:0x102dd0ac0 ...>
attachment.file.attached? # => true
attachment.file.name      # => "test.txt"
attachment.file.size      # => 5796929
attachment.file.url       # => "/media/test.txt"
```

The object returned by the `Attachment#file` method is a "file object": an instance of [`Marten::DB::Field::File::File`](pathname:///api/0.4/Marten/DB/Field/File/File.html). These objects and their associated capabilities are described below in [File objects](#file-objects).

:::tip Under which path are files persisted?
Files are stored at the root of the media [storage](#file-storages) by default. It should be noted that the path used to persist files in storages can be configured by setting the `upload_to` [`file`](../models-and-databases/reference/fields.md#file) field option.

For example, the previous `Attachment` model could be rewritten as follows to ensure that files are persisted in a `foo/bar` folder:

```crystal
class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, blank: false, null: false, upload_to: "foo/bar"
end
```

It should also be noted that `upload_to` can correspond to a proc that takes the name of the file to save, which can be used to implement more complex file path generation logic if necessary:

```crystal
class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, blank: false, null: false, upload_to: ->(name : String) { File.join("files/uploads", name) }
end
```
:::

It should be noted that saving a model record will automatically result in any associated files being saved and persisted in the right [storage](#file-storages) automatically. For example, the following snippet reads a locally available file and attaches it to a new model record:

```crystal
attachment = Attachment.new

File.open("test.txt") do |file|
  attachment.file = file
  attachment.save!
end
```

:::info
You don't need to take care of possible collisions between attached file names: Marten automatically ensures that uploaded files have a unique file name in the destination storage in order to avoid possible conflicts.
:::

## File objects

As mentioned previously, file objects are used internally by Marten to allow interacting with files that are associated with model records. These objects are instances of the [`Marten::DB::Field::File::File`](pathname:///api/0.4/Marten/DB/Field/File/File.html) class. They give access to basic file properties and they allow to interact with the associated IO.

It should be noted that these "file objects" are **always** associated with a model record (persisted or not), and as such, they are only used in the context of the [`file`](../models-and-databases/reference/fields.md#file) model field.

Finally, it's worth mentioning that file objects can be **attached** and/or **committed**:

* an **attached** file object has an associated file set: in that case, its [`#attached?`](pathname:///api/0.4/Marten/DB/Field/File/File.html#attached%3F-instance-method) method returns `true`
* a **committed** file object has an associated file that is _persisted_ to the underlying [storage](#file-storages): in that case, its [`#committed?`](pathname:///api/0.4/Marten/DB/Field/File/File.html#committed%3F%3ABool-instance-method) method returns `true`

For example:

```crystal
attachment = Attachment.last!
attachment.file.attached?  # => true
attachment.file.committed? # => true
```

### Accessing file properties

File objects give access to basic file properties through the use of the following methods:

| Method | Description |
| ----------- | ----------- |
| `#file` | Returns the associated / "wrapped" file object. This can be a real [`File`](https://crystal-lang.org/api/File.html) object, an uploaded file (instance of [`Marten::HTTP::UploadedFile`](pathname:///api/0.4/Marten/HTTP/UploadedFile.html)), or `nil` if no file is associated yet. |
| `#name` | Returns the name of the file. |
| `#size` | Returns the size of the file, using the associated [storage](#file-storages). |
| `#url` | Returns the URL of the file, using the associated [storage](#file-storages). |

### Accessing the underlying file content

File objects allow you to access the underlying file content through the use of the [`#open`](pathname:///api/0.4/Marten/DB/Field/File/File.html#open%3AIO-instance-method) method. This method returns an [`IO`](https://crystal-lang.org/api/IO.html) object.

For example:

```crystal
attachment = Attachment.last!
file_io = attachment.file.open
puts file_io.gets_to_end
```

### Updating the attached file

It is possible to update the actual file of a "file object" by using the [`#save`](pathname:///api/0.4/Marten/DB/Field/File/File.html#save(filepath%3A%3A%3AString%2Ccontent%3AIO%2Csave%3Dfalse)%3ANil-instance-method) method. This method allows saving the content of a specified [`IO`](https://crystal-lang.org/api/IO.html) object and associating it with a specific file path in the underlying [storage](#file-storages).

For example:

```crystal
attachment = Attachment.new

File.open("test.txt") do |file|
  attachment.file.save("path/to/test.txt", file)
  attachment.save!
end

attachment.file.url # => "/media/path/to/test.txt"
```

### Deleting the attached file

It is also possible to manually "delete" the file associated with the "file object". To do so, the [`#delete`](pathname:///api/0.4/Marten/DB/Field/File/File.html#delete(save%3Dfalse)%3ANil-instance-method) method can be used. It should be noted that calling this method will remove the association between the model record and the file AND will also delete the file in the considered [storage](#file-storages).

For example:

```crystal
attachment = Attachment.last!
attachment.file.delete
attachment.file.attached?  # => false
attachment.file.committed? # => false
```

## File storages

Marten uses a file storage mechanism to perform file operations like saving files, deleting files, generating URLs, ... This file storages mechanism allows to save files in different backends by leveraging a standardized API (eg. in the local file system, in a cloud bucket, etc).

By default, [`file`](../models-and-databases/reference/fields.md#file) model fields make use of the configured "media" storage. This storage uses the [`settings.media_files`](../development/reference/settings.md#media-files-settings) settings to determine what storage backend to use, and where to persist files. By default, the media storage uses the [`Marten::Core::Store::FileSystem`](pathname:///api/0.4/Marten/Core/Storage/FileSystem.html) storage backend, which ensures that files are persisted in the local file system, where the Marten application is running.

### Interacting with the media file storage

You won't usually need to interact directly with the file storage, but it's worth mentioning that storage objects share the same API. Indeed, the class of these storage objects must inherit from the [`Marten::Core::Storage::Base`](pathname:///api/0.4/Marten/Core/Storage/Base.html) abstract class and implement a set of mandatory methods which provide the following functionalities:

* saving files ([`#save`](pathname:///api/0.4/Marten/Core/Storage/Base.html#save(filepath%3AString%2Ccontent%3AIO)%3AString-instance-method))
* deleting files ([`#delete`](pathname:///api/0.4/Marten/Core/Storage/Base.html#delete(filepath%3AString)%3ANil-instance-method))
* opening files ([`#open`](pathname:///api/0.4/Marten/Core/Storage/Base.html#open(filepath%3AString)%3AIO-instance-method))
* verifying that files exist ([`#exist?`](pathname:///api/0.4/Marten/Core/Storage/Base.html#exists%3F(filepath%3AString)%3ABool-instance-method))
* retrieving file sizes ([`#size`](pathname:///api/0.4/Marten/Core/Storage/Base.html#size(filepath%3AString)%3AInt64-instance-method))
* retrieving file URLs ([`#url`](pathname:///api/0.4/Marten/Core/Storage/Base.html#url(filepath%3AString)%3AString-instance-method))

These capabilities are highlighted with the following example, where the media storage is used to interact with files:

```crystal
file = File.open("test.txt")
storage = Marten.media_files_storage

filepath = storage.save("test.txt", file)
storage.exists?(filepath)  # => true
storage.exists?("unknown") # => false
storage.size(filepath)     # => 13
storage.url(filepath)      # => "/media/test_c43ba020.txt"
storage.delete(filepath)   # => nil
storage.exists?(filepath)  # => false
```

It should be noted that everything in the previous example could be done with a custom storage initialized manually as well:

```crystal
file = File.open("test.txt")
storage = Marten::Core::Storage::FileSystem.new(root: "/tmp", base_url: "/tmp")

filepath = storage.save("test.txt", file)
storage.exists?(filepath)  # => true
storage.exists?("unknown") # => false
storage.size(filepath)     # => 13
storage.url(filepath)      # => "/tmp/test.txt"
storage.delete(filepath)   # => nil
storage.exists?(filepath)  # => false
```

### Using a different storage with models

As mentioned previously, [`file`](../models-and-databases/reference/fields.md#file) model fields make use of the configured "media" storage by default. That being said, it is possible to leverage the `storage` option in order to make use of another storage if necessary.

For example:

```crystal
custom_storage = Marten::Core::Storage::FileSystem.new(root: "/tmp", base_url: "/tmp")

class Attachment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :file, :file, blank: false, null: false, storage: custom_storage
end
```

When doing this, all the file operations will be done using the configured storage instead of the default media storage.

## Serving uploaded files during development

Marten provides a handler that you can use to serve media files in development environments only. This handler ([`Marten::Handlers::Defaults::Development::ServeMediaFile`](pathname:///api/0.4/Marten/Handlers/Defaults/Development/ServeMediaFile.html)) is automatically mapped to a route when creating new projects through the use of the [`new`](../development/reference/management-commands.md#new) management command:

```crystal
Marten.routes.draw do
  # Other routes...

  if Marten.env.development?
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
```

As you can see, this route will automatically use the URL that is configured as part of the [`url`](../development/reference/settings.md#url-1) media files setting. For example, this means that a `foo/bar.txt` media file would be served by the `/media/foo/bar.txt` route in development if the [`url`](../development/reference/settings.md#url-1) setting is set to `/media/`.

:::warning
It is very important to understand that this handler should **only** be used in development environments. Indeed, the [`Marten::Handlers::Defaults::Development::ServeMediaFile`](pathname:///api/0.4/Marten/Handlers/Defaults/Development/ServeMediaFile.html) handler is not suited for production environments as it is not really efficient or secure. A better way to serve uploaded files is to leverage a web server or a cloud bucket for example (depending on the configured media files storage).
:::
