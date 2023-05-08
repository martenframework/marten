require "./spec_helper"

describe Marten::Conf::GlobalSettings::Database do
  describe "::new" do
    it "initializes a database config from a DB alias" do
      db_config_1 = Marten::Conf::GlobalSettings::Database.new("default")
      db_config_2 = Marten::Conf::GlobalSettings::Database.new("legacy")
      db_config_1.id.should eq "default"
      db_config_2.id.should eq "legacy"
    end
  end

  describe "#id" do
    it "returns the alias of the configured databases" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.id.should eq "default"
    end
  end

  describe "#backend=" do
    it "allows to set the backend identifier from a symbol" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = :sqlite
      db_config.backend.should eq "sqlite"
    end

    it "allows to set the backend identifier from a string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = "sqlite"
      db_config.backend.should eq "sqlite"
    end

    it "allows to set the backend identifier to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = "sqlite"
      db_config.backend = nil
      db_config.backend.should be_nil
    end
  end

  describe "#backend" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend.should be_nil
    end

    it "returns the configured backend" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = "sqlite"
      db_config.backend.should eq "sqlite"
    end
  end

  describe "#checkout_timeout" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.checkout_timeout.should eq 5.0
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.checkout_timeout = 7.5
      db_config.checkout_timeout.should eq 7.5
    end
  end

  describe "#checkout_timeout=" do
    it "allows to set the checkout timeout" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.checkout_timeout = 7.5
      db_config.checkout_timeout.should eq 7.5
    end
  end

  describe "#host=" do
    it "allows to set the host from a symbol" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.host = :localhost
      db_config.host.should eq "localhost"
    end

    it "allows to set the host identifier from a string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.host = "localhost"
      db_config.host.should eq "localhost"
    end

    it "allows to set the host identifier to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.host = "localhost"
      db_config.host = nil
      db_config.host.should be_nil
    end
  end

  describe "#host" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.host.should be_nil
    end

    it "returns the configured host" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.host = "localhost"
      db_config.host.should eq "localhost"
    end
  end

  describe "#initial_pool_size" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.initial_pool_size.should eq 1
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.initial_pool_size = 2
      db_config.initial_pool_size.should eq 2
    end
  end

  describe "#initial_pool_size=" do
    it "allows to set the initial pool size" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.initial_pool_size = 2
      db_config.initial_pool_size.should eq 2
    end
  end

  describe "#max_idle_pool_size" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_idle_pool_size.should eq 1
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_idle_pool_size = 2
      db_config.max_idle_pool_size.should eq 2
    end
  end

  describe "#max_idle_pool_size=" do
    it "allows to set the max idle pool size" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_idle_pool_size = 2
      db_config.max_idle_pool_size.should eq 2
    end
  end

  describe "#max_pool_size" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_pool_size.should eq 0
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_pool_size = 100
      db_config.max_pool_size.should eq 100
    end
  end

  describe "#max_pool_size=" do
    it "allows to set the max pool size" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.max_pool_size = 100
      db_config.max_pool_size.should eq 100
    end
  end

  describe "#name=" do
    it "allows to set the DB name from a symbol" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name = :localdb
      db_config.name.should eq "localdb"
    end

    it "allows to set the DB name from a string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name = "localdb"
      db_config.name.should eq "localdb"
    end

    it "allows to set the DB name to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name = "localdb"
      db_config.name = nil
      db_config.name.should be_nil
    end
  end

  describe "#name" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name.should be_nil
    end

    it "returns the configured name" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name = "localdb"
      db_config.name.should eq "localdb"
    end
  end

  describe "#options" do
    it "returns an empty hash by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")

      db_config.options.should be_empty
    end

    it "returns the configured DB options" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.options = {"sslmode" => "disable"}

      db_config.options.should eq({"sslmode" => "disable"})
    end
  end

  describe "#options=" do
    it "allows to configure DB options" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.options = {"sslmode" => "disable"}

      db_config.options.should eq({"sslmode" => "disable"})
    end
  end

  describe "#password=" do
    it "allows to set the DB password from a symbol" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.password = :pwd
      db_config.password.should eq "pwd"
    end

    it "allows to set the DB password from a string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.password = "pwd"
      db_config.password.should eq "pwd"
    end

    it "allows to set the DB password to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.password = "pwd"
      db_config.password = nil
      db_config.password.should be_nil
    end
  end

  describe "#password" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.password.should be_nil
    end

    it "returns the configured DB password" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.password = "pwd"
      db_config.password.should eq "pwd"
    end
  end

  describe "#port=" do
    it "allows to set the DB port" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.port = 1234
      db_config.port.should eq 1234
    end

    it "allows to set the DB port to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.port = 1234
      db_config.port = nil
      db_config.port.should be_nil
    end
  end

  describe "#port" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.port.should be_nil
    end

    it "returns the configured DB port" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.port = 1234
      db_config.port.should eq 1234
    end
  end

  describe "#retry_attempts" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_attempts.should eq 1
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_attempts = 2
      db_config.retry_attempts.should eq 2
    end
  end

  describe "#retry_attempts=" do
    it "allows to set the retry attempts number" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_attempts = 2
      db_config.retry_attempts.should eq 2
    end
  end

  describe "#retry_delay" do
    it "returns the expected default value if not configured" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_delay.should eq 1.0
    end

    it "returns the configured value" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_delay = 2.5
      db_config.retry_delay.should eq 2.5
    end
  end

  describe "#retry_delay=" do
    it "allows to set the retry delay" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.retry_delay = 2.5
      db_config.retry_delay.should eq 2.5
    end
  end

  describe "#user=" do
    it "allows to set the DB user from a symbol" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.user = :testuser
      db_config.user.should eq "testuser"
    end

    it "allows to set the DB user from a string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.user = "testuser"
      db_config.user.should eq "testuser"
    end

    it "allows to set the DB user to nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.user = "testuser"
      db_config.user = nil
      db_config.user.should be_nil
    end
  end

  describe "#user" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.user.should be_nil
    end

    it "returns the configured DB user" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.user = "testuser"
      db_config.user.should eq "testuser"
    end
  end

  describe "#validate" do
    it "raises if the backend is not specified" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': missing database backend"
      ) do
        db_config.validate
      end
    end

    it "raises if the backend does not exist" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = "unknown"
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': unknown database backend 'unknown'"
      ) do
        db_config.validate
      end
    end

    it "raises if the DB name is nil" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")

      for_mysql { db_config.backend = "mysql" }
      for_postgresql { db_config.backend = "postgresql" }
      for_sqlite { db_config.backend = "sqlite" }

      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': missing database name"
      ) do
        db_config.validate
      end
    end

    it "raises if the DB name is set to an empty string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")

      for_mysql { db_config.backend = "mysql" }
      for_postgresql { db_config.backend = "postgresql" }
      for_sqlite { db_config.backend = "sqlite" }

      db_config.name = ""

      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': missing database name"
      ) do
        db_config.validate
      end
    end

    it "raises if MySQL is used and the database driver shard is missing" do
      db_config = Marten::Conf::GlobalSettings::DatabaseSpec::TestDatabaseWithoutMySQLDriver.new("default")
      db_config.backend = "mysql"
      db_config.name = "test"
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        (
          "Invalid configuration for database 'default': database driver is not installed (please add " \
          "'crystal-lang/crystal-mysql' to your shard.yml file"
        )
      ) do
        db_config.validate
      end
    end

    it "raises if PostgreSQL is used and the database driver shard is missing" do
      db_config = Marten::Conf::GlobalSettings::DatabaseSpec::TestDatabaseWithoutPostgreSQLDriver.new("default")
      db_config.backend = "postgresql"
      db_config.name = "test"
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        (
          "Invalid configuration for database 'default': database driver is not installed (please add " \
          "'will/crystal-pg' to your shard.yml file"
        )
      ) do
        db_config.validate
      end
    end

    it "raises if SQLite is used and the database driver shard is missing" do
      db_config = Marten::Conf::GlobalSettings::DatabaseSpec::TestDatabaseWithoutSQLiteDriver.new("default")
      db_config.backend = "sqlite"
      db_config.name = "test.db"
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        (
          "Invalid configuration for database 'default': database driver is not installed (please add " \
          "'crystal-lang/crystal-sqlite3' to your shard.yml file"
        )
      ) do
        db_config.validate
      end
    end

    it "validates a valid config" do
      for_mysql do
        db_config_1 = Marten::Conf::GlobalSettings::Database.new("default")
        db_config_1.backend = "mysql"
        db_config_1.name = "localdb"
        db_config_1.user = "root"
        db_config_1.password = ""
        db_config_1.validate.should be_nil
      end

      for_postgresql do
        db_config_2 = Marten::Conf::GlobalSettings::Database.new("default")
        db_config_2.backend = "postgresql"
        db_config_2.name = "localdb"
        db_config_2.user = "postgres"
        db_config_2.password = ""
        db_config_2.validate.should be_nil
      end

      for_sqlite do
        db_config_3 = Marten::Conf::GlobalSettings::Database.new("default")
        db_config_3.backend = "sqlite"
        db_config_3.name = "development.db"
        db_config_3.validate.should be_nil
      end
    end
  end

  describe "#with_target_env" do
    it "allows to temporarily persist the configured env" do
      db_config = Marten::Conf::GlobalSettings::DatabaseSpec::TestDatabase.new("default")

      db_config.target_env.should be_nil

      db_config.with_target_env("test") do |c1|
        c1.target_env.should eq "test"

        c1.with_target_env("production") do |c2|
          c2.target_env.should eq "production"
        end

        c1.target_env.should eq "test"
      end

      db_config.target_env.should be_nil
    end
  end

  describe "#name_set_with_env" do
    it "returns nil by default" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.name = "test"
      db_config.name_set_with_env.should be_nil
    end

    it "returns the current env targetted when setting the DB name" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.with_target_env("test") do |c|
        c.name = "test_db"
      end
      db_config.name_set_with_env.should eq "test"
    end
  end
end

module Marten::Conf::GlobalSettings::DatabaseSpec
  class TestDatabase < Marten::Conf::GlobalSettings::Database
    getter target_env
  end

  class TestDatabaseWithoutMySQLDriver < Marten::Conf::GlobalSettings::Database
    def mysql_database_driver_installed?
      false
    end
  end

  class TestDatabaseWithoutPostgreSQLDriver < Marten::Conf::GlobalSettings::Database
    def postgresql_database_driver_installed?
      false
    end
  end

  class TestDatabaseWithoutSQLiteDriver < Marten::Conf::GlobalSettings::Database
    def sqlite3_database_driver_installed?
      false
    end
  end
end
