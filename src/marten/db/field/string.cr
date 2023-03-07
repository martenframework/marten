module Marten
  module DB
    module Field
      class String < Base
        getter default

        # Returns the maximum string size allowed.
        getter max_size

        # Returns the minimum string size allowed.
        getter min_size

        def initialize(
          @id : ::String,
          @max_size : ::Int32,
          @min_size : ::Int32? = nil,
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
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
          Management::Column::String.new(
            name: db_column!,
            max_size: max_size,
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

        def empty_value?(value) : ::Bool
          case value
          when Nil
            true
          when ::String
            value.empty?
          when Symbol
            value.to_s.empty?
          else
            raise_unexpected_field_value(value)
          end
        end

        def validate(record, value)
          return if !value.is_a?(::String)

          if value.size > max_size
            record.errors.add(id, I18n.t("marten.db.field.string.errors.too_long", max_size: max_size))
          end

          if !min_size.nil? && value.size < min_size.not_nil!
            record.errors.add(id, I18n.t("marten.db.field.string.errors.too_short", min_size: min_size))
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:max_size].is_a?(NilLiteral) %}
            {% raise "String fields must define 'max_size' property" %}
          {% end %}
        end
      end
    end
  end
end
