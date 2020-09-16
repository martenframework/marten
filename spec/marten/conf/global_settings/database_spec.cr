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
      db_config.backend = "sqlite"
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': missing database name"
      ) do
        db_config.validate
      end
    end

    it "raises if the DB name is set to an empty string" do
      db_config = Marten::Conf::GlobalSettings::Database.new("default")
      db_config.backend = "sqlite"
      db_config.name = ""
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Invalid configuration for database 'default': missing database name"
      ) do
        db_config.validate
      end
    end

    it "validates a valid config" do
      db_config_1 = Marten::Conf::GlobalSettings::Database.new("default")
      db_config_1.backend = "sqlite"
      db_config_1.name = "development.db"
      db_config_1.validate.should be_nil

      db_config_2 = Marten::Conf::GlobalSettings::Database.new("default")
      db_config_2.backend = "postgresql"
      db_config_2.name = "localdb"
      db_config_2.user = "postgres"
      db_config_2.password = ""
      db_config_2.validate.should be_nil
    end
  end
end
