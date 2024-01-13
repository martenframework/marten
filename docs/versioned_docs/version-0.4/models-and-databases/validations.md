---
title: Model validations
description: Learn how to validate model records.
sidebar_label: Validations
---

Model instances _should_ be validated before being persisted to the database. As such models provide a convenient way to define validation rules through the use of model fields and through the use of a custom validation rules DSL. The underlying validation logics are completely database-agnostic, cannot be skipped (unless explicitly specified), and can be unit-tested easily.

Validation rules can be inherited from the fields in your model depending on the options you used and the type of your fields (for example fields using `blank: false` will make the associated record validation fail if the field value is blank). They can also be explicitly specified in your model class, which is useful if you need to implement custom validation logics.

## Overview

### A short example

Let's consider the following example:

```crystal
class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 128, blank: false
end
```

In the above snippet, a `User` model is defined and it is specified that the `name` field must be present (`blank: false`) and that the associated value cannot exceed 128 characters.

Given these characteristics, it is possible to create `User` instances and to validate them through the use of the `#valid?` method:

```crystal
user_1 = User.new
user_1.valid?                       # => false

user_2 = User.new(name: "0" * 200)
user_2.valid?                       # => false

user_3 = User.new(name: "John Doe")
user_3.valid?                       # => true
```

As you can see in the above examples, the first two users are invalid because either the `name` is not specified or because its value exceeds the maximum characters limit. The last user is valid though because it has a `name` that is less than 128 characters.

### When does model validation happen?

Model instances are validated when they are created or updated, before any values are persisted to the database. Methods like `#create` or `#save` automatically run validations. They return `false` to indicate that the considered object is invalid (and they return `true` if the object is valid). The `#create` and `#save` methods also have bang counterparts (`#create!` and `#save!`) that will explicitly raise a validation error (instance of `Marten::DB::Errors::InvalidRecord`) in case of invalid records.

For example:

```crystal
user = User.new
user.save
# => false
user.save!
# => Unhandled exception: Record is invalid (Marten::DB::Errors::InvalidRecord)
```

When validating model records, the validation rules that are inherited by fields will be executed first and then any custom validation rule defined in the model will be applied.

### Running model validations

As mentioned previously, validation rules will be executed automatically when calling the `#create` or `#save` methods on a model record. It is also possible to manually verify whether a model instance is valid or not using the `#valid?` and `#invalid?` methods:

```crystal
user = User.new
user.valid?     # => false
user.invalid?   # => true
```

## Field validation rules

As mentioned previously, fields can contribute validation rules to your models. These validation rules can be inherited:

* from the field type itself: some fields will validate that values are of a specific type (for example a `uuid` field will not validate values that don't correspond to valid UUIDs)
* from the field options you define (for example fields using `blank: true` won't accept empty values)

Please refer to the [fields reference](./reference/fields.md) in order to learn more about the supported field types and their associated options.

## Custom validation rules

Custom validate rules can be defined through the use of the `#validate` macro. This macro lets you configure the name of a validation method that should be called when a model instance is validated. Inside this method, you can implement any validation logic that you might require and add errors to your model instances if they are identified as invalid.

For example:

```crystal
class User < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 128, blank: false

  validate :validate_name_is_not_forbidden

  private def validate_name_is_not_forbidden
    errors.add(:name, "admin can't be used!") if name == "admin"
  end
end
```

In the above snippet, a custom validation method ensures that the `name` of a `User` model instance can't be set to `"admin"`: if the name is set to `"admin"`, then a specific error (associated with the `name` attribute) is added to the model instance (which makes it invalid).

## Validation errors

Methods like `#valid?` or `#invalid?` only let you know whether a model instance is valid or invalid. But you'll likely want to know exactly what are the actual errors or how to add new ones.

As such, every model instance has an associated error set, which is an instance of [`Marten::Core::Validation::ErrorSet`](pathname:///api/0.4/Marten/Core/Validation/ErrorSet.html).

### Inspecting errors

A model instance error set lets you access all the errors of a specific model instance. For example:

```crystal
user = User.new

user.valid?
# => false

user.errors.size
# => 1

user.errors
# => #<Marten::Core::Validation::ErrorSet:0x100e1b740
#      @errors=
#        [#<Marten::Core::Validation::Error:0x100db75d0
#          @field="name",
#          @message="This field cannot be blank.",
#          @type="blank">]>
```

As you can see, the error set gives you the ability to know how many errors are affecting your model instance. Each error provides some additional information as well:

* the associated field name (which can be `nil` if the error is global)
* the error message
* the error type, which is optional (`blank` in the previous example)

You can also access the errors that are associated with a specific field very easily by using the `#[]` method:

```crystal
user.errors[:name]
# => [#<Marten::Core::Validation::Error:0x104fb75d0
#      @field="name",
#      @message="This field cannot be blank.",
#      @type="blank">]
```

Global errors (errors affecting the whole model instances or multiple fields at once) can be listed through the use of the `#global` method.

### Adding errors

Errors can be added to an error set through the use of the `#add` method. This method takes a field name, a message, and an optional error type:

```crystal
user.errors.add(:name, "Name is invalid")                      # error type is "invalid"
user.errors.add(:name, "Name is invalid", type: :invalid_name) # error type is "invalid_name"
```

Global errors can be specified through the use of an alternative `#add` method that doesn't take a field name:

```crystal
user.errors.add("User is invalid")                      # error type is "invalid"
user.errors.add("User is invalid", type: :invalid_user) # error type is "invalid_user"
```

## Skipping validations

Model validations can be explicitly skipped when using the `#save` or `#save!` methods. To do so, the `validate: false` argument can be used:

```crystal
user = User.new
user.save(validate: false)
```

:::caution
It is generally not a good idea to skip validation that way. This technique should be used with caution!
:::
