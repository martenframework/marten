module Marten
  abstract class Schema
    module Field
      # Represents a JSON schema field.
      class JSON < Base
        @serializable_proc : Proc(::String, ::JSON::Serializable)?

        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          serializable : ::JSON::Serializable.class | Nil = nil
        )
          if !serializable.nil?
            @serializable_proc = ->(value : ::String) {
              serializable.not_nil!.from_json(value).as(::JSON::Serializable)
            }
          end
        end

        def deserialize(value) : ::JSON::Any | ::JSON::Serializable | Nil
          return if empty_value?(value)

          case value
          when Nil
            value
          when ::String
            parse_string_value(value)
          when ::JSON::Any
            deserialize(value.to_json)
          else
            raise_unexpected_field_value(value)
          end
        rescue ArgumentError | ::JSON::ParseException
          raise_unexpected_field_value(value)
        end

        def serialize(value) : ::String?
          return if value.nil?

          if (v = value).is_a?(::JSON::Any | ::JSON::Serializable)
            v.to_json
          else
            raise_unexpected_field_value(value)
          end
        end

        # :nodoc:
        macro contribute_to_schema(schema_klass, field_id, field_ann, kwargs)
          {% serializable_klass = kwargs.is_a?(NilLiteral) ? nil : kwargs[:serializable] %}

          class ::{{ schema_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if serializable_klass.is_a?(NilLiteral) %}
              def {{ field_id }} : ::JSON::Any?
                validated_data[{{ field_id.stringify }}]?.as(::JSON::Any?)
              end
            {% else %}
              def {{ field_id }} : {{ serializable_klass }}?
                if (v = validated_data[{{ field_id.stringify }}]?).as?({{ serializable_klass }})
                  v.as({{ serializable_klass }})
                end
              end
            {% end %}

            def {{ field_id }}!
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}?
              !{{ field_id }}.nil?
            end
          end
        end

        private getter serializable_proc

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.json.errors.invalid")
        end

        private def parse_string_value(value)
          serializable_proc.nil? ? ::JSON.parse(value) : serializable_proc.not_nil!.call(value)
        end
      end
    end
  end
end
