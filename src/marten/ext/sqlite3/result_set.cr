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
  end
end
