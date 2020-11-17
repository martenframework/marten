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

    it "reuses any already opened transaction" do
      conn = Marten::DB::Connection.default

      conn.transaction do
        conn.open do |db|
          db.should be_a(DB::Connection)
        end
      end
    end
  end

  describe "#sanitize_like_pattern" do
    it "properly escapes % characters" do
      conn = Marten::DB::Connection.default
      conn.sanitize_like_pattern("test%foo").should eq "test\\%foo"
    end

    it "properly escapes _ characters" do
      conn = Marten::DB::Connection.default
      conn.sanitize_like_pattern("test_foo").should eq "test\\_foo"
    end
  end

  describe "#transaction" do
    it "wraps DB operations in a transaction" do
      conn = Marten::DB::Connection.default

      TestUser.connection.should eq conn

      expect_raises Exception, "Unexpected" do
        conn.transaction do
          TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
          raise "Unexpected error"
          TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
        end
      end

      TestUser.all.size.should eq 0
    end
  end
end
