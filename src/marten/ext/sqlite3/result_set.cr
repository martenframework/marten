__marten_defined?(::SQLite3::ResultSet) do
  class SQLite3::ResultSet < DB::ResultSet
    def read(t : Time?.class) : Time?
      read(String?).try do |v|
        if v.includes? "."
          Time.parse(v, SQLite3::DATE_FORMAT_SUBSECOND, location: SQLite3::TIME_ZONE)
        else
          Time.parse(v, SQLite3::DATE_FORMAT_SECOND, location: SQLite3::TIME_ZONE)
        end
      rescue Time::Format::Error
        Time.parse(v, "%F", location: SQLite3::TIME_ZONE)
      end
    end
  end
end
