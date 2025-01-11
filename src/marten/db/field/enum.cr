module Marten
  module DB
    module Field
      # Represents an enum field.
      class Enum < Base
        @default : ::String?

        getter default

        getter values

        def initialize(
          @id : ::String,
          enum_values : Array(::String),
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
          default : ::Enum? = nil,
          **kwargs,
        )
          @values = enum_values
          @default = default.try(&.to_s)
        end

        def from_db(value) : ::String?
          case value
          when Nil | ::String
            value.as?(Nil | ::String)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::String?
          result_set.read(::String?)
        end

        def to_column : Management::Column::Base?
          Management::Column::Enum.new(
            name: db_column!,
            values: values,
            primary_key: primary_key?,
            null: null?,
            unique: unique?,
            index: index?,
            default: to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::String
            value
          when Symbol
            value.to_s
          else
            raise_unexpected_field_value(value)
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:values].is_a?(NilLiteral) %}
            {% raise "Enum fields must define the 'values' property" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% enum_klass = kwargs[:values] %}
          {% enum_ivar_name = "enum_" + field_id.stringify %}
          {% field_accessor_name = "raw_" + field_id.stringify %}

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %},
                enum_values: {{ enum_klass }}.values.map(&.to_s),
              )
            )

            {% if !model_klass.resolve.abstract? %}
              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {% unless kwargs.is_a?(NilLiteral) %}{{ kwargs }}{% else %}nil{% end %},
                field_type: {{ field_ann[:exposed_type] }}{% if field_ann[:additional_type] %} | {{ field_ann[:additional_type] }}{% end %}, # ameba:disable Layout/LineLength
                accessor: {{ field_accessor_name.id }},
                model_klass: {{ model_klass }}
              )]
              @{{ field_id }} : {{ field_ann[:exposed_type] }}?

              @{{ enum_ivar_name.id }} : {{ enum_klass }}?

              def {{ field_accessor_name.id }} : {{ field_ann[:exposed_type] }}?
                @{{ field_id }}
              end

              def {{ field_accessor_name.id }}!
                @{{ field_id }}.not_nil!
              end

              def {{ field_accessor_name.id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_accessor_name.id }})
              end

              def {{ field_accessor_name.id }}=(value : {{ field_ann[:exposed_type] }}?)
                if value.nil?
                  @{{ field_id }} = nil
                  @{{ enum_ivar_name.id }} = nil
                else
                  @{{ field_id }} = value.to_s
                  @{{ enum_ivar_name.id }} = {{ enum_klass }}.parse(value.to_s)
                end
              end

              def {{ field_id }} : {{ enum_klass }}?
                @{{ enum_ivar_name.id }} ||= if !{{ field_accessor_name.id }}.nil?
                  {{ enum_klass }}.parse({{ field_accessor_name.id }}!)
                end
              end

              def {{ field_id }}!
                {{ field_id }}.not_nil!
              end

              def {{ field_id }}?
                {{ field_accessor_name.id }}?
              end

              def {{ field_id.id }}=(value : {{ enum_klass }}?)
                if value.nil?
                  @{{ field_id }} = nil
                  @{{ enum_ivar_name.id }} = nil
                else
                  @{{ field_id }} = value.to_s
                  @{{ enum_ivar_name.id }} = value
                end
              end

              def {{ field_id.id }}=(value : {{ field_ann[:exposed_type] }}?)
                if value.nil?
                  @{{ field_id }} = nil
                  @{{ enum_ivar_name.id }} = nil
                else
                  @{{ field_id }} = value.to_s
                  @{{ enum_ivar_name.id }} = {{ enum_klass }}.parse(value.to_s)
                end
              end
            {% end %}
          end
        end
      end
    end
  end
end
