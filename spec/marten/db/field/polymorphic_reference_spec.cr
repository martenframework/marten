require "./spec_helper"

describe Marten::DB::Field::PolymorphicReference do
  describe "#default" do
    it "returns nil" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      field.default.should be_nil
    end
  end

  describe "#from_db" do
    it "returns an Int64 if the value is an Int64" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      result = field.from_db(42.to_i64)
      result.should eq 42
      result.should be_a Int64
    end

    it "returns an Int32 if the value is an Int32" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      result = field.from_db(42)
      result.should eq 42
      result.should be_a Int32
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      field.from_db(nil).should be_nil
    end

    it "returns the expected value if the value is an UUID" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      result = field.from_db(UUID.new("123e4567-e89b-12d3-a456-426614174000"))
      result.should eq UUID.new("123e4567-e89b-12d3-a456-426614174000").hexstring
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])
      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(["true"])
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])

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

    it "is able to read a string value from a DB result set" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'foo'") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a String
            value.should eq "foo"
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Post])

      column = field.to_column
      column.should be_a Marten::DB::Management::Column::BigInt
      column = column.as(Marten::DB::Management::Column::BigInt)
      column.name.should eq "polymorphic_reference"
      column.primary_key?.should be_false
      column.auto?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "raises InvalidField if the type models have different primary key types" do
      field = Marten::DB::Field::PolymorphicReference.new("polymorphic_reference", [TestUser, Product])

      expect_raises(
        Marten::DB::Errors::InvalidField,
        "All the types of a polymorphic field must have the same type of model primary key field. " \
        "Field 'polymorphic_reference'' has types Marten::DB::Field::BigInt, Marten::DB::Field::String."
      ) do
        field.to_column
      end
    end
  end

  describe "#to_db" do
    it "returns the expected value based on the target model primary key type" do
      field = Marten::DB::Field::PolymorphicReference.new(
        "polymorphic_reference",
        [TestUser] of Marten::DB::Model.class
      )

      result = field.to_db(42.to_i64)
      result.should eq 42.to_i64
      result.should be_a Int64
    end
  end
end
