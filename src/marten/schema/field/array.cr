require "./base"

module Marten
  abstract class Schema
    module Field
      # Represents an array schema field.
      class Array < Base
        def initialize(
          @id : ::String,
          @of_field : Base,
          @required : ::Bool = true,
        )
        end

        def empty_value?(value) : ::Bool
          super || (value.is_a?(::Array) && value.empty?)
        end

        def get_raw_data(data)
          get_raw_data_as_array(data)
        end

        def deserialize(value) : ::Array(Field::Any)?
          case value
          when ::Array
            ret = ::Array(Field::Any).new
            value.each do |v|
              ret << of_field.deserialize(v)
            end

            ret.reject!(Nil)
          end
        end

        def serialize(value) : ::Array(::String) | Nil | ::String
          case value
          when ::Array
            value.map do |v|
              of_field.serialize(v).to_s
            end
          end
        end

        def validate(schema, value)
          return if !value.is_a?(::Array)

          value.each do |v|
            of_field.validate(schema, v)
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:of].is_a?(NilLiteral) %}
            {% raise "Array fields must define the 'of' property" %}
          {% end %}

          {% if !kwargs.is_a?(NilLiteral) && kwargs[:of] == :array %}
            {% raise "Array fields cannot be nested" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_schema(schema_klass, field_id, field_ann, kwargs)
          {% array_options = [:of, :required] %}
          {% array_options_used_count = 0 %}
          {% if !kwargs.is_a?(NilLiteral) && !kwargs.empty? %}
            {% for array_option in array_options %}
              {% if kwargs.has_key?(array_option) %}
                {% array_options_used_count += 1 %}
              {% end %}
            {% end %}
          {% end %}

          {% of_type = kwargs[:of].is_a?(StringLiteral) || kwargs[:of].is_a?(SymbolLiteral) ? kwargs[:of].id : nil %}
          {% if of_type.is_a?(NilLiteral) %}{% raise "Cannot use '#{kwargs[:of]}' as a valid field type" %}{% end %}

          {% of_type_exists = false %}
          {% of_type_klass = nil %}
          {% of_type_ann = nil %}
          {% for k in Marten::Schema::Field::Base.all_subclasses %}
            {% ann = k.annotation(Marten::Schema::Field::Registration) %}
            {% if ann && ann[:id] == of_type %}
              {% of_type_exists = true %}
              {% of_type_klass = k %}
              {% of_type_ann = ann %}
            {% end %}
          {% end %}
          {% unless of_type_exists %}
            {% raise "'#{of_type}' is not a valid type for field '#{schema_klass.id}##{field_id}'" %}
          {% end %}

          {{ of_type_klass }}.check_definition(
            {{ field_id }},
            {% unless kwargs.empty? %}{{ kwargs }}{% else %}nil{% end %}
          )

          {{ of_type_klass }}.contribute_array_to_schema(
            {{ schema_klass }},
            {{ field_id }},
            {{ of_type_ann }},
            {% if !kwargs.is_a?(NilLiteral) && !kwargs.empty? && kwargs.size > array_options_used_count %}
              {
                {% for key, value in kwargs %}
                  {% if !array_options.includes?(key.symbolize) %}
                    {{ key }}: {{ value }},
                  {% end %}
                {% end %}
              }
            {% else %}
              nil
            {% end %}
          )

          class ::{{ schema_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                of_field: {{ field_id }}_member_field,
                required: {{ kwargs[:required].is_a?(NilLiteral) ? true : kwargs[:required] }},
              )
            )
          end
        end

        private getter of_field

        private def get_raw_data_as_array(data)
          if data.responds_to?(:fetch_all)
            data.fetch_all(id)
          else
            data[id]?.try do |value|
              if value.is_a?(::Array)
                value
              else
                [value]
              end
            end
          end
        end
      end
    end
  end
end
