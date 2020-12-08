require "./spec_helper"

describe Marten::DB::Field::BigAuto do
  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::BigAuto.new("my_field", db_column: "my_field_col", primary_key: true)
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::BigAuto
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

      field = Marten::DB::Field::BigAuto.new("id", primary_key: true)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end
  end
end
