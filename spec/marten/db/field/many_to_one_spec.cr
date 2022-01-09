require "./spec_helper"

describe Marten::DB::Field::ManyToOne do
  describe "#default" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.default.should be_nil
    end
  end

  describe "#foreign_key?" do
    it "returns true by default" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.foreign_key?.should be_true
    end

    it "returns true if explicitly set to false" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: true)
      field.foreign_key?.should be_true
    end

    it "returns false if explicitly set to false" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: false)
      field.foreign_key?.should be_false
    end
  end

  describe "#from_db" do
    it "returns an Int64 if the value is an Int64" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: false)
      result = field.from_db(42.to_i64)
      result.should eq 42
      result.should be_a Int64
    end

    it "returns an Int32 if the value is an Int32" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: false)
      result = field.from_db(42)
      result.should eq 42
      result.should be_a Int32
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: false)
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, foreign_key: false)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)

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

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#related_model" do
    it "returns the related model" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.related_model.should eq Tag
    end
  end

  describe "#relation?" do
    it "returns true" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.relation?.should be_true
    end
  end

  describe "#relation_name" do
    it "returns the relation name" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.relation_name.should eq "tag"
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, db_column: "origin_tag_id")

      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Reference
      column.name.should eq "origin_tag_id"
      column.to_table.should eq Tag.db_table
      column.to_column.should eq "id"
      column.primary_key?.should be_false
      column.foreign_key?.should be_true
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_true
    end

    it "properly initializes the column if the field is configured to use a foreign key" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, db_column: "origin_tag_id", foreign_key: true)
      field.to_column.foreign_key?.should be_true
    end

    it "properly initializes the column if the field is configured to not use a foreign key" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag, db_column: "origin_tag_id", foreign_key: false)
      field.to_column.foreign_key?.should be_false
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.to_db(nil).should be_nil
    end

    it "returns an Int64 value if the initial value is an Int64" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.to_db(42.to_i64).should eq 42.to_i64
    end

    it "returns an Int32 value if the initial value is an Int32" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.to_db(42).should eq 42
    end

    it "returns a casted Int32 value if the value is an Int8" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.to_db(42.to_i8).should eq 42
    end

    it "returns a casted Int32 value if the value is an Int16" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)
      field.to_db(42.to_i16).should eq 42
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::ManyToOne.new("tag_id", "tag", Tag)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end
end
