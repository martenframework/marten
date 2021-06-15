require "./spec_helper"

describe Marten::DB::Management::Column::BigAuto do
  describe "#clone" do
    it "returns a cloned object" do
      column = Marten::DB::Management::Column::BigAuto.new("test")
      cloned_column = column.clone
      cloned_column.should_not be column
      cloned_column.should eq Marten::DB::Management::Column::BigAuto.new("test")
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::BigAuto.new("test")
      {% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
        column.sql_type(Marten::DB::Connection.default).should eq "bigserial"
      {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
        column.sql_type(Marten::DB::Connection.default).should eq "bigint AUTO_INCREMENT"
      {% else %}
        column.sql_type(Marten::DB::Connection.default).should eq "integer"
      {% end %}
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      column = Marten::DB::Management::Column::BigAuto.new("test")
      {% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
        column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
      {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
        column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
      {% else %}
        column.sql_type_suffix(Marten::DB::Connection.default).should eq "AUTOINCREMENT"
      {% end %}
    end
  end
end
