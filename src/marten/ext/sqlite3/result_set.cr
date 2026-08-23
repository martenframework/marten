__marten_defined?(::SQLite3::ResultSet) do
  class SQLite3::ResultSet < DB::ResultSet
    def read(t : Time.class) : Time
      read(Time?).not_nil!
    end

    def read(t : Time?.class) : Time?
      read(String?).try do |value|
        if value.matches?(/\A\d{4}-\d{2}-\d{2}\z/)
          Time.parse(value, "%F", location: SQLite3::TIME_ZONE)
        elsif value.includes?(".")
          Time.parse(value, SQLite3::DATE_FORMAT_SUBSECOND, location: SQLite3::TIME_ZONE)
        else
          Time.parse(value, SQLite3::DATE_FORMAT_SECOND, location: SQLite3::TIME_ZONE)
        end
      end
    end

    def read(t : BigDecimal.class) : BigDecimal
      read(BigDecimal | Nil).not_nil!
    end

    def read(t : (BigDecimal | Nil).class) : BigDecimal?
      case value = read
      when Nil
        nil
      when BigDecimal
        value
      when ::String, Float64, Float32, Int64, Int32, Int16, Int8
        BigDecimal.new(value.to_s)
      else
        raise ::DB::ColumnTypeMismatchError.new(
          context: "#{self.class}#read",
          column_index: @column_index - 1,
          column_name: column_name(@column_index - 1),
          column_type: value.class.to_s,
          expected_type: BigDecimal.to_s
        )
      end
    end
  end
end
