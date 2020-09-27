module Marten
  module DB
    module Field
      class UUID < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::UUID?
          value = result_set.read(::String?)
          ::UUID.new(value) unless value.nil?
        end

        def to_column : Migration::Column::Base
          Migration::Column::UUID.new(
            db_column,
            primary_key?,
            null?,
            unique?,
            db_index?
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::UUID
            value.to_s
          else
            raise_unexpected_field_value(value)
          end
        end

        def validate(record, value)
          return if value.nil?
          return if value.as?(::UUID)

          if value.as?(::String)
            begin
              return if ::UUID.new(value.as(::String))
            rescue ArgumentError
            end
          end

          record.errors.add(id, "A valid UUID must be provided")
        end
      end
    end
  end
end
