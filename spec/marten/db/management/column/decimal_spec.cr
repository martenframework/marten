require "./spec_helper"

describe Marten::DB::Management::Column::Decimal do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2)
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2).should eq(
        Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2)
      )

      Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2, null: true).should eq(
        Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2, null: true)
      )

      Marten::DB::Management::Column::Decimal.new(
        "test",
        max_digits: 10,
        decimal_places: 2,
        unique: true,
        default: "19.99"
      ).should eq(
        Marten::DB::Management::Column::Decimal.new(
          "test",
          max_digits: 10,
          decimal_places: 2,
          unique: true,
          default: "19.99"
        )
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2).should_not eq(
        Marten::DB::Management::Column::Decimal.new("other", max_digits: 10, decimal_places: 2)
      )
    end

    it "returns false if two column objects don't have the same max digits" do
      Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2).should_not eq(
        Marten::DB::Management::Column::Decimal.new("test", max_digits: 12, decimal_places: 2)
      )
    end

    it "returns false if two column objects don't have the same decimal places" do
      Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2).should_not eq(
        Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 4)
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column = Marten::DB::Management::Column::Decimal.new(
        "test",
        max_digits: 10,
        decimal_places: 2,
        null: true,
        default: "1.5"
      )
      cloned_column = column.clone
      cloned_column.should_not be column
      cloned_column.should eq column
      cloned_column.max_digits.should eq 10
      cloned_column.decimal_places.should eq 2
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::Decimal.new("foo", max_digits: 10, decimal_places: 2).same_config?(
        Marten::DB::Management::Column::Decimal.new("bar", max_digits: 10, decimal_places: 2)
      ).should be_true
    end

    it "returns false if two column objects don't have the same max digits" do
      Marten::DB::Management::Column::Decimal.new("foo", max_digits: 10, decimal_places: 2).same_config?(
        Marten::DB::Management::Column::Decimal.new("bar", max_digits: 12, decimal_places: 2)
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::Decimal.new("foo", max_digits: 10, decimal_places: 2).same_config?(
        Marten::DB::Management::Column::Float.new("foo")
      ).should be_false
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2)

      for_mysql do
        column.sql_type(Marten::DB::Connection.default).should eq "numeric(10,2)"
      end
      for_postgresql do
        column.sql_type(Marten::DB::Connection.default).should eq "numeric(10,2)"
      end
      for_sqlite do
        column.sql_type(Marten::DB::Connection.default).should eq "decimal(10, 2)"
      end
    end
  end

  describe "#sql_type_suffix" do
    it "returns nil" do
      column = Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2)
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end

  describe "#serialize_args" do
    it "returns the expected serialized arguments" do
      column = Marten::DB::Management::Column::Decimal.new("test", max_digits: 10, decimal_places: 2, null: true)
      column.serialize_args.should eq %{:test, :decimal, max_digits: 10, decimal_places: 2, null: true}
    end
  end
end
