defined?(::SQLite3::ResultSet) do
  class SQLite3::ResultSet < DB::ResultSet
    def read(t : Time?.class) : Time?
      read(String?).try do |v|
        Time.parse(v, SQLite3::DATE_FORMAT, location: SQLite3::TIME_ZONE)
      rescue Time::Format::Error
        Time.parse(v, "%F", location: SQLite3::TIME_ZONE)
      end
    end
  end
end
