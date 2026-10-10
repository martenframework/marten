require "./spec_helper"

describe Marten::DB::Connection do
  describe "::default" do
    it "returns the default connection" do
      Marten::DB::Connection.default.should be_a Marten::DB::Connection::Base
      Marten::DB::Connection.default.alias.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
    end
  end

  describe "::for" do
    it "returns the default connection when no routers are configured" do
      conn = Marten::DB::Connection.for(Tag)
      conn.should be_a Marten::DB::Connection::Base
      conn.alias.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
    end

    it "returns the connection suggested by routers for reads" do
      routers = [Marten::DB::ConnectionSpec::OtherDBRouter] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        Marten::DB::Connection.for(Tag).alias.should eq "other"
      end
    end

    it "returns the connection suggested by routers for writes" do
      routers = [Marten::DB::ConnectionSpec::PrimaryReplicaRouter] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        Marten::DB::Connection.for(Tag).alias.should eq "other"
        Marten::DB::Connection.for(Tag, write: true).alias.should eq "default"
      end
    end
  end

  describe "::get" do
    it "is able to return the default connection" do
      conn = Marten::DB::Connection.get(Marten::DB::Connection::DEFAULT_CONNECTION_NAME)
      conn.should be_a Marten::DB::Connection::Base
      conn.alias.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
    end

    it "is able to return a custom connection" do
      conn = Marten::DB::Connection.get(:other)
      conn.should be_a Marten::DB::Connection::Base
      conn.alias.should eq "other"

      conn = Marten::DB::Connection.get("other")
      conn.should be_a Marten::DB::Connection::Base
      conn.alias.should eq "other"
    end

    it "raises if the connection does not exist" do
      expect_raises(
        Marten::DB::Errors::UnknownConnection,
        "Unknown database connection 'unknown'"
      ) do
        Marten::DB::Connection.get(:unknown)
      end
    end
  end
end

module Marten::DB::ConnectionSpec
  class OtherDBRouter < Marten::DB::Router::Base
    def db_for_read(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end

    def db_for_write(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end
  end

  class PrimaryReplicaRouter < Marten::DB::Router::Base
    def db_for_read(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end

    def db_for_write(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "default"
    end
  end
end
