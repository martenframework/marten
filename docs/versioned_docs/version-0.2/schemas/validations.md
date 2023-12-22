---
title: Schema validations
description: Learn how to validate data with schemas.
sidebar_label: Validations
---

The main goal of schemas is to validate data and request parameters. As such, schemas provide a convenient mechanism allowing to define validation rules. These rules can be inherited from the fields in your schema depending on the options you used and the type of your fields. They can also be explicitly specified in your schema class, which is useful if you need to implement custom validation logics.


## Overview

### A short example

Let's consider the following example:

```crystal
class UserSchema < Marten::Schema
  field :name, :string, required: true, max_size: 128
end
```

In the above snippet, a `UserSchema` schema is defined and it is specified that the `name` field must be present (`required: true`) and that the associated value cannot exceed 128 characters.

Given these characteristics, it is possible to initialize `UserSchema` instances and validate data through the use of the `#valid?` method:

```crystal
schema_1 = UserSchema.new(Marten::Schema::DataHash.new)
schema_1.valid?                       # => false

schema_2 = UserSchema.new(Marten::Schema::DataHash{ "name" => "0" * 200) })
schema_2.valid?                       # => false

schema_3 = UserSchema.new(Marten::Schema::DataHash{ "name" => "John Doe") })
schema_3.valid?                       # => true
```

As you can see in the above examples, the first two schemas are invalid because either the `name` field is not specified or because its value exceeds the maximum characters limit. The last schema is valid though because it has a `name` field that is less than 128 characters.

### Running schema validations

As highlighted in the previous section, schema validation rules will be executed when calling the `#valid?` and `#invalid?` methods: these methods return `true` or `false` depending on whether the data is valid or invalid.

```crystal
schema = UserSchema.new(Marten::Schema::DataHash.new)
schema.valid?     # => false
schema.invalid?   # => true
```

## Field validation rules

As mentioned previously, fields can contribute validation rules to your schemas. These validation rules can be inherited:

* from the field type itself: some fields will validate that values are of a specific type (for example a `uuid` field will not validate values that don't correspond to valid UUIDs)
* from the field options you define (for example fields using `required: true` will result in errors if the field is missing from the validated data)

Please refer to the [fields reference](./reference/fields.md) to learn more about the supported field types and their associated options.

## Custom validation rules

Custom validation rules can be defined through the use of the `#validate` macro. This macro lets you configure the name of a validation method that should be called when a schema instance is validated. Inside this method, you can implement any validation logic that you might require and add errors to the schema instance if the data is invalid.

For example:

```crystal
class SignUpSchema < Marten::Schema
  field :email, :string, max_size: 254
  field :password1, :string, max_size: 128, strip: false
  field :password2, :string, max_size: 128, strip: false

  validate :validate_password

  def validate_password
    return unless validated_data["password1"]? && validated_data["password2"]?

    if validated_data["password1"] != validated_data["password2"]
      errors.add("The two password fields do not match")
    end
  end
end
```

In the above snippet, a custom validation method ensures that the `password1` and `password2` fields have the exact same value. If that's not the case, then a specific error (that is not associated with any fields) is added to the schema instance (which makes it invalid). It's interesting to note the use of the `#validated_data` method here: this method returns a hash of all the values that were previously sanitized and validated. You can make use of it when defining custom validation rules: indeed, these rules always run _after_ all the fields have been individually validated first.

:::important
You can define multiple validation rules in your schema classes. When doing so, don't forget that these custom validation rules are called in the order they are defined.
:::

## Validation errors

Methods like `#valid?` or `#invalid?` only let you know whether a schema instance is valid or invalid for a specific data set. But you'll likely want to know exactly what are the actual errors or how to add new ones.

As such, every schema instance has an associated error set, which is an instance of [`Marten::Core::Validation::ErrorSet`](pathname:///api/0.2/Marten/Core/Validation/ErrorSet.html).

### Inspecting errors

A schema instance error set lets you access all the errors of a specific schema instance. For example:

```crystal
schema = UserSchema.new(Marten::Schema::DataHash.new)

schema.valid?
# => false

schema.errors.size
# => 1

schema.errors
# => #<Marten::Core::Validation::ErrorSet:0x100e1b740
#      @errors=
#        [#<Marten::Core::Validation::Error:0x100db75d0
#          @field="name",
#          @message="This field is required.",
#          @type="required">]>
```

As you can see, the error set gives you the ability to know how many errors are affecting your schema instance. Each error provides some additional information as well:

* the associated field name (which can be `nil` if the error is global)
* the error message
* the error type, which is optional (`required` in the previous example)

You can also access the errors that are associated with a specific field very easily by using the `#[]` method:

```crystal
schema.errors[:name]
# => [#<Marten::Core::Validation::Error:0x104fb75d0
#      @field="name",
#      @message="This field is required.",
#      @type="required">]
```

Global errors (errors affecting the whole schema instances or multiple fields at once) can be listed through the use of the `#global` method.

### Adding errors

Errors can be added to an error set through the use of the `#add` method. This method takes a field name, a message, and an optional error type:

```crystal
schema.errors.add(:name, "Name is invalid")                      # error type is "invalid"
schema.errors.add(:name, "Name is invalid", type: :invalid_name) # error type is "invalid_name"
```

Global errors can be specified through the use of an alternative `#add` method that doesn't take a field name:

```crystal
schema.errors.add("User is invalid")                      # error type is "invalid"
schema.errors.add("User is invalid", type: :invalid_user) # error type is "invalid_user"
```
