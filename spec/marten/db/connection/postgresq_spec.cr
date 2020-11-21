require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  describe Marten::DB::Connection::PostgreSQL do
    describe "#quote" do
      it "it produces expected quoted strings" do
        conn = Marten::DB::Connection.default
        conn.quote("column_name").should eq %{"column_name"}
      end
    end
  end
{% end %}
