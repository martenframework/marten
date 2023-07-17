module Marten
  module DB
    module Field
      # Represent's a JSON field.
      #
      # JSON model fields allow to automatically parse JSON columns and expose the corresponding `JSON::Any` object,
      # which is the default behavior:
      #
      # ```
      # class MyModel < Marten::Model
      #   # Other fields...
      #   field :metadata, :json
      # end
      # ```
      #
      # It should be noted that it is also possible to specify a `serializable` option in order to specify a class that
      # makes use of `JSON::Serializable`. When doing so, the parsing of the JSON values will result in the
      # initialization of the corresponding serializable objects:
      #
      # ```
      # class MySerializable
      #   include JSON::Serializable
      #
      #   property a : Int32 | Nil
      #   property b : String | Nil
      # end
      #
      # class MyModel < Marten::Model
      #   # Other fields...
      #   field :metadata, :json, serializable: MySerializable
      # end
      # ```
      class JSON < Base
        # :nodoc:
        alias AdditionalType = ::JSON::Any | ::JSON::Serializable

        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : ::JSON::Any | ::JSON::Serializable | Nil = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
          **kwargs
        )
        end

        def from_db(value) : ::String | Nil
          case value
          when ::JSON::PullParser
            ::JSON::Any.new(value).to_json
          when Nil | ::String
            value.as?(Nil | ::String)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::String | Nil
          from_db(result_set.read(::JSON::PullParser | ::String | Nil))
        end

        def to_column : Management::Column::Base?
          Management::Column::JSON.new(
            db_column!,
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
          when ::JSON::Any, ::JSON::Serializable
            value.to_json
          else
            raise_unexpected_field_value(value)
          end
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% serializable_klass = kwargs[:serializable] %}

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if !model_klass.resolve.abstract? %}
              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {% unless kwargs.is_a?(NilLiteral) %}{{ kwargs }}{% else %}nil{% end %},
                field_type: {{ serializable_klass.is_a?(NilLiteral) ? ::JSON::Any : ::JSON::Serializable }} | Nil
              )]

              {% if serializable_klass.is_a?(NilLiteral) %}
                @{{ field_id }} : ::JSON::Any?

                def {{ field_id }} : ::JSON::Any?
                  @{{ field_id }}
                end

                def {{ field_id }}=({{ field_id }} : ::String?)
                  @{{ field_id }} = if !{{ field_id }}.nil?
                    ::JSON.parse({{ field_id }})
                  else
                    nil
                  end
                end

                def {{ field_id }}=(@{{ field_id }} : ::JSON::Any?); end
              {% else %}
                @{{ field_id }} : {{ serializable_klass }}?

                def {{ field_id }} : {{ serializable_klass }}?
                  @{{ field_id }}
                end

                def {{ field_id }}=({{ field_id }} : ::String?)
                  @{{ field_id }} = if !{{ field_id }}.nil?
                    {{ serializable_klass }}.from_json({{ field_id }})
                  else
                    nil
                  end
                end

                def {{ field_id }}=(@{{ field_id }} : {{ serializable_klass }}?); end

                def {{ field_id }}=({{ field_id }} : ::JSON::Serializable)
                  @{{ field_id }} = {{ field_id }}.as({{ serializable_klass }})
                end
              {% end %}

              def {{ field_id }}!
                {{ field_id }}.not_nil!
              end

              def {{ field_id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_id }})
              end
            {% end %}
          end
        end
      end
    end
  end
end
