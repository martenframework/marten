module Marten
  module DB
    module Field
      # A duration model field.
      #
      # Duration fields are persisted as big integers (number of nanoseconds) in the underlying database. They are
      # converted to `Time::Span` objects when the corresponding values are read from the database.
      class Duration < Base
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : Time::Span? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        def from_db(value) : Time::Span?
          case value
          when Nil
            value.as?(Nil)
          when Int32, Int64
            Time::Span.new(nanoseconds: value.as(Int32 | Int64))
          when Time::Span
            value.as?(Time::Span)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Time::Span?
          from_db(result_set.read(Int32 | Int64 | Nil))
        end

        def to_column : Management::Column::Base?
          Management::Column::BigInt.new(
            db_column!,
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
          when Time::Span
            value.total_nanoseconds.to_i64
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
