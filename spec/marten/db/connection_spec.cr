require "./spec_helper"

describe Marten::DB::Connection do
  describe "::default" do
    it "returns the default connection" do
      Marten::DB::Connection.default.should be_a Marten::DB::Connection::Base
      Marten::DB::Connection.default.alias.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
    end
  end

  describe "::for" do
    it "returns the default connection for any table names by default" do
      conn = Marten::DB::Connection.for("my_table")
      conn.should be_a Marten::DB::Connection::Base
      conn.alias.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
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
