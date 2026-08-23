require "./spec_helper"
require "./decimal_spec/**"

describe Marten::DB::Field::Decimal do
  with_installed_apps Marten::DB::Field::DecimalSpec::App

  describe "::new" do
    it "initializes a decimal field instance with the expected values" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.id.should eq "my_field"
      field.max_digits.should eq 10
      field.decimal_places.should eq 2
      field.default.should be_nil
      field.primary_key?.should be_false
      field.blank?.should be_false
      field.null?.should be_false
      field.unique?.should be_false
      field.db_column.should eq field.id
      field.index?.should be_false
    end

    it "initializes a decimal field instance with a specific default value" do
      field = Marten::DB::Field::Decimal.new(
        "my_field",
        max_digits: 10,
        decimal_places: 2,
        default: BigDecimal.new("42.45")
      )
      field.default.should eq BigDecimal.new("42.45")
    end

    it "raises if max_digits is not positive" do
      expect_raises(ArgumentError, "max_digits must be a positive integer") do
        Marten::DB::Field::Decimal.new("my_field", max_digits: 0, decimal_places: 0)
      end
    end

    it "raises if decimal_places is greater than max_digits" do
      expect_raises(ArgumentError, "decimal_places must be less than or equal to max_digits") do
        Marten::DB::Field::Decimal.new("my_field", max_digits: 2, decimal_places: 3)
      end
    end
  end

  describe "#from_db" do
    it "is able to process a BigDecimal object" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.from_db(BigDecimal.new("42.45")).should eq BigDecimal.new("42.45")
    end

    it "is able to process a string value" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.from_db("42.45").should eq BigDecimal.new("42.45")
    end

    it "is able to process integer values" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.from_db(42).should eq BigDecimal.new("42")
    end

    it "is able to process a nil value" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a decimal value from a DB result set" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)

      Marten::DB::Connection.default.open do |db|
        sql = "SELECT CAST('19.99' AS DECIMAL(10, 2))"
        for_sqlite { sql = "SELECT CAST('19.99' AS DECIMAL(10, 2))" }
        for_postgresql { sql = "SELECT CAST('19.99' AS NUMERIC(10, 2))" }
        for_mysql { sql = "SELECT CAST('19.99' AS DECIMAL(10, 2))" }

        db.query(sql) do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a BigDecimal
            value.should eq BigDecimal.new("19.99")
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end

    it "persists and reloads decimal values without losing precision" do
      value = BigDecimal.new("12345678.99")
      product = Marten::DB::Field::DecimalSpec::Product.create!(price: value)
      product.reload.price.should eq value
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Decimal.new("my_field", db_column: "my_field_col", max_digits: 10, decimal_places: 2)
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Decimal
      column = column.as(Marten::DB::Management::Column::Decimal)
      column.name.should eq "my_field_col"
      column.max_digits.should eq 10
      column.decimal_places.should eq 2
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Decimal.new(
        "my_field",
        db_column: "my_field_col",
        max_digits: 10,
        decimal_places: 2,
        default: BigDecimal.new("42.5")
      )
      column = field.to_column
      column.default.should eq "42.5"
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.default.should be_nil
    end

    it "returns the configured default" do
      field = Marten::DB::Field::Decimal.new(
        "my_field",
        max_digits: 10,
        decimal_places: 2,
        default: BigDecimal.new("42.45")
      )
      field.default.should eq BigDecimal.new("42.45")
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.to_db(nil).should be_nil
    end

    it "returns a string if the initial value is a BigDecimal" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.to_db(BigDecimal.new("42.45")).should eq "42.45"
    end

    it "returns a casted string if the value is an integer" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.to_db(42).should eq "42.0"
    end

    it "returns a casted string if the value is a string" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)
      field.to_db("19.99").should eq "19.99"
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Decimal.new("my_field", max_digits: 10, decimal_places: 2)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "#validate" do
    it "adds an error if the number has too many decimal places" do
      obj = Tag.new(name: "test")
      field = Marten::DB::Field::Decimal.new("price", max_digits: 5, decimal_places: 2)

      field.validate(obj, BigDecimal.new("1.234"))

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "price"
      obj.errors.first.message.should eq "Ensure that there are no more than 2 decimal places."
    end

    it "adds an error if the number has too many digits in total" do
      obj = Tag.new(name: "test")
      field = Marten::DB::Field::Decimal.new("price", max_digits: 5, decimal_places: 2)

      field.validate(obj, BigDecimal.new("1234.56"))

      obj.errors.any? do |e|
        e.field == "price" &&
          e.message == I18n.t("marten.db.field.decimal.errors.max_digits", max_digits: 5)
      end.should be_true
    end

    it "adds an error if the number has too many digits before the decimal point" do
      obj = Tag.new(name: "test")
      field = Marten::DB::Field::Decimal.new("price", max_digits: 5, decimal_places: 2)

      field.validate(obj, BigDecimal.new("1234"))

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "price"
      obj.errors.first.message.should eq I18n.t(
        "marten.db.field.decimal.errors.max_whole_digits",
        max_whole_digits: 3
      )
    end

    it "does not add an error for a valid decimal" do
      obj = Tag.new(name: "test")
      field = Marten::DB::Field::Decimal.new("price", max_digits: 5, decimal_places: 2)

      field.validate(obj, BigDecimal.new("999.99"))

      obj.errors.size.should eq 0
    end

    it "adds an error if the value cannot be parsed as a decimal" do
      obj = Tag.new(name: "test")
      field = Marten::DB::Field::Decimal.new("price", max_digits: 5, decimal_places: 2)

      field.validate(obj, "not-a-number")

      obj.errors.size.should eq 1
      obj.errors.first.message.should eq "Enter a valid number."
    end
  end

  describe "::contribute_to_model" do
    it "properly generates a #<field_name>=(value) setter that takes BigDecimal values" do
      product = Marten::DB::Field::DecimalSpec::Product.new(price: BigDecimal.new("19.99"))
      product.price.should eq BigDecimal.new("19.99")
    end

    it "properly generates a #<field_name>=(value) setter that takes Float values" do
      product = Marten::DB::Field::DecimalSpec::Product.new
      product.price = 19.99
      product.price.should eq BigDecimal.new("19.99")
    end

    it "properly generates a #<field_name>=(value) setter that takes Int values" do
      product = Marten::DB::Field::DecimalSpec::Product.new
      product.price = 20
      product.price.should eq BigDecimal.new("20")
    end

    it "properly generates a #<field_name>=(value) setter that takes String values" do
      product = Marten::DB::Field::DecimalSpec::Product.new
      product.price = "19.99"
      product.price.should eq BigDecimal.new("19.99")
    end

    it "properly generates a #<field_name>=(value) setter that takes nil values" do
      product = Marten::DB::Field::DecimalSpec::Product.new(price: BigDecimal.new("19.99"))
      product.price = nil
      product.price.should be_nil
    end
  end
end
