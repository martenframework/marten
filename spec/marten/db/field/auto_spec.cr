require "./spec_helper"

describe Marten::DB::Field::Auto do
  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::Auto.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a Int32 | Int64
            value.should eq 42
          end
        end
      end
    end

    it "is able to read a nil value from a DB result set" do
      field = Marten::DB::Field::Auto.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_nil
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Auto.new("my_field", db_column: "my_field_col", primary_key: true)
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Auto
      column.name.should eq "my_field_col"
      column.primary_key?.should be_true
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
    end
  end

  describe "#perform_validation" do
    it "does not add any errors for nil values since they are created at the DB level" do
      obj = Tag.new(id: nil)

      field = Marten::DB::Field::Auto.new("id", primary_key: true)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end
  end
end
