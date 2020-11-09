require "./spec_helper"

describe Marten::DB::Connection::Base do
  describe "#alias" do
    it "returns the alias associated with the connection database" do
      db_config_1 = Marten::Conf::GlobalSettings::Database.new("default")
      db_config_1.backend = "sqlite"
      db_config_1.name = "development.db"

      db_config_2 = Marten::Conf::GlobalSettings::Database.new("other")
      db_config_2.backend = "postgresql"
      db_config_2.name = "localdb"
      db_config_2.user = "postgres"
      db_config_2.password = ""

      conn_1 = Marten::DB::Connection::SQLite.new(db_config_1)
      conn_2 = Marten::DB::Connection::PostgreSQL.new(db_config_2)

      conn_1.alias.should eq "default"
      conn_2.alias.should eq "other"
    end
  end

  describe "#build_sql" do
    it "allows to build a SQL statement" do
      conn = Marten::DB::Connection::SQLite.new(Marten::Conf::GlobalSettings::Database.new("default"))

      sql = conn.build_sql do |s|
        s << "SELECT *"
        s << "FROM my_table"
        s << "WHERE id = 1"
      end

      sql.should eq "SELECT * FROM my_table WHERE id = 1"
    end
  end

  describe "#open" do
    it "allows to open a DB connection" do
      conn = Marten::DB::Connection.default

      conn.open do |db|
        result = db.scalar("SELECT 1")
        result.should eq 1
      end
    end
  end
end
