module Marten
  module DB
    module Field
      class UUID < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::UUID?
          value = result_set.read(::String?)
          ::UUID.new(value) unless value.nil?
        end

        def to_column : Management::Column::Base
          Management::Column::UUID.new(
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

          if (v = value.as?(::String))
            begin
              return if ::UUID.new(v)
            rescue ArgumentError
            end
          end

          record.errors.add(id, I18n.t("marten.db.field.uuid.errors.invalid"))
        end
      end
    end
  end
end
