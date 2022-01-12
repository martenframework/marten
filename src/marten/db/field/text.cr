module Marten
  module DB
    module Field
      class Text < Base
        @max_size : ::Int32?

        getter default
        getter max_size

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @max_size = nil,
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
          Management::Column::Text.new(
            db_column!,
            primary_key?,
            null?,
            unique?,
            index?,
            to_db(default)
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
          return if !value.is_a?(::String) || @max_size.nil?

          if value.size > @max_size.not_nil!
            record.errors.add(id, I18n.t("marten.db.field.text.errors.too_long", max_size: max_size))
          end
        end
      end
    end
  end
end
