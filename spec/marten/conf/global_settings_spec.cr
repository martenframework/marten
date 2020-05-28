require "./spec_helper"

describe Marten::Conf::GlobalSettings do
  describe "#allowed_hosts" do
    it "returns an empty list by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts.empty?.should be_true
    end

    it "returns the list of allowed hosts if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts = ["localhost"]
      global_settings.allowed_hosts.should eq ["localhost"]
    end
  end

  describe "#allowed_hosts=" do
    it "allows to set the list of allowed hosts for the application" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts = ["localhost"]
      global_settings.allowed_hosts.should eq ["localhost"]
    end
  end

  describe "#databases" do
    it "returns an empty list by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.databases.empty?.should be_true
    end

    it "returns the list of configured databases" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database do |db|
        db.backend = :sqlite
        db.name = "db.sql"
      end

      global_settings.database :other do |db|
        db.backend = :sqlite
        db.name = "other_db.sql"
      end

      global_settings.databases.size.should eq 2

      global_settings.databases[0].id.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "db.sql"

      global_settings.databases[1].id.should eq "other"
      global_settings.databases[1].backend.should eq "sqlite"
      global_settings.databases[1].name.should eq "other_db.sql"
    end
  end

  describe "#database" do
    it "allows to configure the default DB connection" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database do |db|
        db.backend = :sqlite
        db.name = "db.sql"
      end

      global_settings.databases.size.should eq 1

      global_settings.databases[0].id.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "db.sql"
    end

    it "allows to configure a non-default DB connection" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database :other do |db|
        db.backend = :sqlite
        db.name = "other_db.sql"
      end

      global_settings.databases.size.should eq 1

      global_settings.databases[0].id.should eq "other"
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "other_db.sql"
    end
  end

  describe "#debug" do
    it "returns false by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.debug.should be_false
    end

    it "returns true if debug mode is enabled" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.debug = true
      global_settings.debug.should be_true
    end
  end

  describe "#debug=" do
    it "allows to enable or disable the debug mode" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.debug = true
      global_settings.debug.should be_true

      global_settings.debug = false
      global_settings.debug.should be_false
    end
  end

  describe "#host" do
    it "returns localhost by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host.should eq "localhost"
    end

    it "returns the configured HTTP server host value" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host = "0.0.0.0"
      global_settings.host.should eq "0.0.0.0"
    end
  end

  describe "#host=" do
    it "allows to configure the HTTP server host" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host = "0.0.0.0"
      global_settings.host.should eq "0.0.0.0"
    end
  end
end
