require "./spec_helper"

describe Marten::DB::Management::Column::Date do
  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::Date.new("test")
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.should eq Marten::DB::Management::Column::Date.new("test")

      column_2 = Marten::DB::Management::Column::Date.new("test", null: true)
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::Date.new("test", null: true)

      column_3 = Marten::DB::Management::Column::Date.new("test", unique: true)
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::Date.new("test", unique: true)

      column_4 = Marten::DB::Management::Column::Date.new("test", index: true)
      cloned_column_4 = column_4.clone
      cloned_column_4.should_not be column_4
      cloned_column_4.should eq Marten::DB::Management::Column::Date.new("test", index: true)

      tz = Time.local
      column_5 = Marten::DB::Management::Column::Date.new("test", default: tz)
      cloned_column_5 = column_5.clone
      cloned_column_5.should_not be column_5
      cloned_column_5.should eq Marten::DB::Management::Column::Date.new("test", default: tz)
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::Date.new("test")

      for_mysql { column.sql_type(Marten::DB::Connection.default).should eq "date" }
      for_postgresql { column.sql_type(Marten::DB::Connection.default).should eq "date" }
      for_sqlite { column.sql_type(Marten::DB::Connection.default).should eq "date" }
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      column = Marten::DB::Management::Column::Date.new("test")
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end
end
