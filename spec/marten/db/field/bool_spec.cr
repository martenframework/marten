require "./spec_helper"

describe Marten::DB::Field::Bool do
  describe "#from_db" do
    it "returns true if the value is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db(true).should be_true
    end

    it "returns false if the value is false" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db(false).should be_false
    end

    it "assumes that \"true\" is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db("true").should be_true
    end

    it "assumes that 1 is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db(1).should be_true
    end

    it "assumes that \"1\" is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db("1").should be_true
    end

    it "assumes that \"yes\" is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.from_db("yes").should be_true
    end

    it "assumes that nil is false if the field does not allow null values" do
      field = Marten::DB::Field::Bool.new("my_field", null: false)
      field.from_db(nil).should be_false
    end

    it "assumes that nil is nil if the field allows null values" do
      field = Marten::DB::Field::Bool.new("my_field", null: true)
      field.from_db(nil).should be_nil
    end
  end

  describe "#from_db_result_set" do
    for_db_backends :mysql, :postgresql do
      it "is able to read a true boolean value from a DB result set" do
        field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

        Marten::DB::Connection.default.open do |db|
          db.query("SELECT true") do |rs|
            rs.each do
              field.from_db_result_set(rs).should be_true
            end
          end
        end
      end

      it "is able to read a false boolean value from a DB result set" do
        field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

        Marten::DB::Connection.default.open do |db|
          db.query("SELECT false") do |rs|
            rs.each do
              field.from_db_result_set(rs).should be_false
            end
          end
        end
      end
    end

    it "assumes that \"true\" is truthy" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'true'") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_true
          end
        end
      end
    end

    it "assumes that 1 is truthy" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 1") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_true
          end
        end
      end
    end

    it "assumes that \"1\" is truthy" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT '1'") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_true
          end
        end
      end
    end

    it "assumes that \"yes\" is truthy" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'yes'") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_true
          end
        end
      end
    end

    it "assumes that null is false if the field does not allow null values" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col", null: false)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_false
          end
        end
      end
    end

    it "assumes that null is nil if the field allows null values" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col", null: true)

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
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Bool
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Bool.new("my_field", db_column: "my_field_col", default: true)
      column = field.to_column
      column.default.should be_true
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      field = Marten::DB::Field::Bool.new("my_field", default: true)
      field.default.should be_true
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns true if the value is true" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.to_db(true).should be_true
    end

    it "returns false if the value is false" do
      field = Marten::DB::Field::Bool.new("my_field")
      field.to_db(false).should be_false
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Bool.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db("dummy")
      end
    end
  end
end
