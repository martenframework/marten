module Marten
  abstract class Schema
    module Field
      # Represents an enum schema field.
      class Enum < Base
        @values : ::Array(::String)

        getter values

        def initialize(
          @id : ::String,
          enum_values : ::Array(::String),
          @required : ::Bool = true,
          **kwargs,
        )
          @values = enum_values.map(&.downcase)
        end

        def deserialize(value) : ::String?
          value.to_s.strip
        end

        def serialize(value) : ::Array(::String) | Nil | ::String
          value.try(&.to_s)
        end

        def validate(schema, value)
          return if !schema.errors[id].empty?
          return if empty_value?(value) && !required?

          if !values.includes?(value.to_s.downcase)
            schema.errors.add(id, I18n.t("marten.schema.field.enum.errors.invalid", value: value))
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:values].is_a?(NilLiteral) %}
            {% raise "Enum fields must define the 'values' property" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_array_to_schema(schema_klass, field_id, field_ann, kwargs)
          {% enum_klass = kwargs[:values] %}
          {% field_accessor_name = "raw_" + field_id.stringify %}

          class ::{{ schema_klass }}
            def self.{{ field_id }}_member_field
              {{ @type }}.new(
                "{{ field_id }}_member",
                enum_values: {{ enum_klass }}.values.map(&.to_s)
              )
            end

            def {{ field_accessor_name.id }} : ::Array({{ field_ann[:exposed_type] }})?
              return if validated_data[{{ field_id.stringify }}]?.nil?

              ret = ::Array({{ field_ann[:exposed_type] }}).new
              validated_data[{{ field_id.stringify }}].as(::Array(Field::Any)).try do |values|
                values.each do |value|
                  ret << value.as({{ field_ann[:exposed_type] }})
                end
              end

              ret
            end

            def {{ field_accessor_name.id }}!
              {{ field_id }}.not_nil!
            end

            def {{ field_id }} : ::Array({{ enum_klass }})?
              {{ field_accessor_name.id }}.try do |values|
                values.map do |value|
                  {{ enum_klass }}.parse(value.to_s)
                end
              end
            end

            def {{ field_id }}!
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}?
              !self.class.get_field({{ field_id.stringify }}).empty_value?({{ field_accessor_name.id }})
            end
          end
        end

        # :nodoc:
        macro contribute_to_schema(schema_klass, field_id, field_ann, kwargs)
          {% enum_klass = kwargs[:values] %}
          {% enum_ivar_name = "enum_" + field_id.stringify %}
          {% field_accessor_name = "raw_" + field_id.stringify %}

          class ::{{ schema_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %},
                enum_values: {{ enum_klass }}.values.map(&.to_s),
              )
            )

            def {{ field_accessor_name.id }} : {{ field_ann[:exposed_type] }}?
              validated_data[{{ field_id.stringify }}]?.as({{ field_ann[:exposed_type] }}?)
            end

            def {{ field_accessor_name.id }}! : {{ field_ann[:exposed_type] }}
              {{ field_accessor_name.id }}.not_nil!
            end

            def {{ field_id }} : {{ enum_klass }}?
              {{ enum_klass }}.parse({{ field_accessor_name.id }}!) if {{ field_id }}?
            end

            def {{ field_id }}!
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}?
              !self.class.get_field({{ field_id.stringify }}).empty_value?({{ field_accessor_name.id }})
            end
          end
        end
      end
    end
  end
end
