require "./spec_helper"

describe Marten::DB::Management::Column::ForeignKey do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )
      )

      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).should eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          null: true
        )
      )

      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).should eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          unique: true
        )
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "other",
          to_table: "other_table",
          to_column: "other_column"
        )
      )
    end

    it "returns false if two column objects don't have the same target table" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "new_table",
          to_column: "other_column"
        )
      )
    end

    it "returns false if two column objects don't have the same target column" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "new_column"
        )
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).should_not eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          null: false
        )
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).should_not eq(
        Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          unique: false
        )
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.to_column.should eq "other_column"
      cloned_column_1.to_table.should eq "other_table"
      cloned_column_1.should eq Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )

      column_2 = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )

      column_3 = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column"
        )
      ).should be_true

      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          null: true
        )
      ).should be_true

      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          unique: true
        )
      ).should be_true
    end

    it "returns false if two column objects don't have the same target table" do
      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "new_table",
          to_column: "other_column"
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same target column" do
      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "new_column"
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          null: false
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::ForeignKey.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).same_config?(
        Marten::DB::Management::Column::ForeignKey.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          unique: false
        )
      ).should be_false
    end
  end

  describe "#serialize_args" do
    it "returns the expected serialized version of a simple column" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.serialize_args.should eq %{:test, :foreign_key, to_table: :other_table, to_column: :other_column}
    end

    it "returns the expected serialized version of a simple column that is a nullable" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )
      column.serialize_args.should eq(
        %{:test, :foreign_key, to_table: :other_table, to_column: :other_column, null: true}
      )
    end

    it "returns the expected serialized version of a simple column that is unique" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
      column.serialize_args.should eq(
        %{:test, :foreign_key, to_table: :other_table, to_column: :other_column, unique: true}
      )
    end

    it "returns the expected serialized version of a simple column that is not indexed" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        index: false
      )
      column.serialize_args.should eq(
        %{:test, :foreign_key, to_table: :other_table, to_column: :other_column, index: false}
      )
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      {% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
        column.sql_type(Marten::DB::Connection.default).should eq "bigint"
      {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
        column.sql_type(Marten::DB::Connection.default).should eq "bigint"
      {% else %}
        column.sql_type(Marten::DB::Connection.default).should eq "integer"
      {% end %}
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end

  describe "#to_column" do
    it "returns the targetted column name" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.to_column.should eq "other_column"
    end
  end

  describe "#to_table" do
    it "returns the targetted table name" do
      column = Marten::DB::Management::Column::ForeignKey.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.to_table.should eq "other_table"
    end
  end
end
