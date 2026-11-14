module Marten
  module DB
    module Field
      class Binary < Base
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : ::Bytes? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
        )
        end

        def from_db(value) : ::Bytes?
          case value
          when Nil
            nil
          when ::Bytes
            # Drivers can return a slice into a buffer that does not outlive the row.
            value.dup
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::Bytes?
          from_db(result_set.read(::Bytes?))
        end

        def to_column : Management::Column::Base?
          Management::Column::Binary.new(
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
          when ::Bytes
            # `Bytes.empty` uses a null pointer, which SQLite binds as NULL. A zero-size allocation keeps an empty
            # value distinct from NULL on every backend.
            value.empty? ? ::Bytes.new(0) : value
          else
            raise_unexpected_field_value(value)
          end
        end

        def empty_value?(value) : ::Bool
          case value
          when Nil
            true
          when ::Bytes
            value.empty?
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
