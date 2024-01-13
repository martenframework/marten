---
title: Create custom file storages
description: Learn how to create custom file storages.
---

Marten uses a file storage mechanism to perform file operations like saving files, deleting files, generating URLs, ... This file storages mechanism allows to save files in different backends by leveraging a standardized API. You can leverage this capability to implement custom file storages (which you can then use for [assets](../../assets/introduction.md) or as part of [file model fields](../uploading-files.md#persisting-uploaded-files-in-model-records)).

## Basic file storage implementation

File storages are implemented as subclasses of the [`Marten::Core::Storage::Base`](pathname:///api/0.4/Marten/Core/Storage/Base.html) abstract class. As such, they must implement a set of mandatory methods which provide the following functionalities:

* saving files ([`#save`](pathname:///api/0.4/Marten/Core/Storage/Base.html#save(filepath%3AString%2Ccontent%3AIO)%3AString-instance-method))
* deleting files ([`#delete`](pathname:///api/0.4/Marten/Core/Storage/Base.html#delete(filepath%3AString)%3ANil-instance-method))
* opening files ([`#open`](pathname:///api/0.4/Marten/Core/Storage/Base.html#open(filepath%3AString)%3AIO-instance-method))
* verifying that files exist ([`#exist?`](pathname:///api/0.4/Marten/Core/Storage/Base.html#exists%3F(filepath%3AString)%3ABool-instance-method))
* retrieving file sizes ([`#size`](pathname:///api/0.4/Marten/Core/Storage/Base.html#size(filepath%3AString)%3AInt64-instance-method))
* retrieving file URLs ([`#url`](pathname:///api/0.4/Marten/Core/Storage/Base.html#url(filepath%3AString)%3AString-instance-method))

Note that you can fully customize how file storage objects are initialized.

For example, a custom-made "file system" storage (that reads and writes files in a specific folder of the local file system) could be implemented as follows:

```crystal
require "file_utils"

class FileSystem < Marten::Core::Storage::Base
  def initialize(@root : String, @base_url : String)
  end

  def delete(filepath : String) : Nil
    File.delete(path(filepath))
  rescue File::NotFoundError
    raise Marten::Core::Storage::Errors::FileNotFound.new("File '#{filepath}' cannot be found")
  end

  def exists?(filepath : String) : Bool
    File.exists?(path(filepath))
  end

  def open(filepath : String) : IO
    File.open(path(filepath), mode: "rb")
  rescue File::NotFoundError
    raise Marten::Core::Storage::Errors::FileNotFound.new("File '#{filepath}' cannot be found")
  end

  def size(filepath : String) : Int64
    File.size(path(filepath))
  end

  def url(filepath : String) : String
    File.join(base_url, URI.encode_path(filepath))
  end

  def write(filepath : String, content : IO) : Nil
    new_path = path(filepath)

    FileUtils.mkdir_p(Path[new_path].dirname)

    File.open(new_path, "wb") do |new_file|
      IO.copy(content, new_file)
    end
  end

  private getter root
  private getter base_url

  private def path(filepath)
    File.join(root, filepath)
  end
end
```

## Using custom file storages

You have many options when it comes to using your custom file storage classes, and those depend on what you are trying to do:

* if you want to use a custom storage for [assets](../../assets/introduction.md), then you will likely want to assign an instance of your custom storage class to the [`assets.storage`](../../development/reference/settings.md#storage) setting (see [Assets storage](../../assets/introduction.md#assets-storage) to learn more about assets storages specifically)
* if you want to use a custom storage for all your [file model fields](../../models-and-databases/reference/fields.md#file), then you will likely want to assign an instance of your custom storage class to the [`media_files.storage`](../../development/reference/settings.md#storage-1) setting (see [File storages](../managing-files.md#file-storages) to learn more about file storages specifically)
