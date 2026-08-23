__marten_defined?(::MySql::ResultSet) do
  class MySql::ResultSet < DB::ResultSet
    def read(t : BigDecimal.class) : BigDecimal
      read(BigDecimal | Nil).not_nil!
    end

    def read(t : (BigDecimal | Nil).class) : BigDecimal?
      mysql_read do |row_packet, column|
        case column.column_type
        when MySql::Type::NewDecimal, MySql::Type::Decimal
          BigDecimal.new(row_packet.read_lenenc_string)
        else
          value = column.column_type.read(row_packet)
          case value
          when ::String, Float64, Float32, Int8, Int16, Int32, Int64
            BigDecimal.new(value.to_s)
          else
            raise ::DB::ColumnTypeMismatchError.new(
              context: "#{self.class}#read",
              column_index: @column_index - 1,
              column_name: column.name,
              column_type: value.class.to_s,
              expected_type: BigDecimal.to_s
            )
          end
        end
      end
    end
  end
end

__marten_defined?(::MySql::TextResultSet) do
  class MySql::TextResultSet < DB::ResultSet
    def read(t : BigDecimal.class) : BigDecimal
      read(BigDecimal | Nil).not_nil!
    end

    def read(t : (BigDecimal | Nil).class) : BigDecimal?
      mysql_read do |row_packet, _column, length|
        value = row_packet.read_string(length)
        BigDecimal.new(value)
      end
    end
  end
end
