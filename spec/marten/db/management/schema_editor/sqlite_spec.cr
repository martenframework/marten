require "./spec_helper"

for_sqlite do
  describe Marten::DB::Management::SchemaEditor::SQLite do
    describe "#column_type_for_built_in_column" do
      it "returns the expected column type for a big int column" do
        column = Marten::DB::Management::Column::BigInt.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "integer"
      end

      it "returns the expected column type for a big int column with auto increment" do
        column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "integer"
      end

      it "returns the expected column type for a bool column" do
        column = Marten::DB::Management::Column::Bool.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "bool"
      end

      it "returns the expected column type for a datetime column" do
        column = Marten::DB::Management::Column::DateTime.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "datetime"
      end

      it "returns the expected column type for a float column" do
        column = Marten::DB::Management::Column::Float.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "real"
      end

      it "returns the expected column type for an int column" do
        column = Marten::DB::Management::Column::Int.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "integer"
      end

      it "returns the expected column type for an int column with auto increment" do
        column = Marten::DB::Management::Column::Int.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "integer"
      end

      it "returns the expected column type for a string column" do
        column = Marten::DB::Management::Column::String.new("test", max_size: 155)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "varchar(%{max_size})"
      end

      it "returns the expected column type for a text column" do
        column = Marten::DB::Management::Column::Text.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "text"
      end

      it "returns the expected column type for a uuid column" do
        column = Marten::DB::Management::Column::UUID.new("test")
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_for_built_in_column(column).should eq "char(32)"
      end
    end

    describe "#column_type_suffix_for_built_in_column" do
      it "returns the expected suffix for a big int column with auto increment" do
        column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_suffix_for_built_in_column(column).should eq "AUTOINCREMENT"
      end

      it "returns the expected suffix for an int column with auto increment" do
        column = Marten::DB::Management::Column::Int.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.column_type_suffix_for_built_in_column(column).should eq "AUTOINCREMENT"
      end
    end

    describe "#ddl_rollbackable?" do
      it "returns true" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.ddl_rollbackable?.should be_true
      end
    end

    describe "#quoted_default_value_for_built_in_column" do
      it "returns the expected string representation for a byte value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column(Bytes[255, 97]).should eq "X'ff61'"
      end

      it "returns the expected string representation for a string value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column("hello").should eq "'hello'"
        schema_editor.quoted_default_value_for_built_in_column(%{value " quote}).should eq "'value \" quote'"
      end

      it "returns the expected string representation for a time value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        local_time = Time.local
        schema_editor.quoted_default_value_for_built_in_column(local_time).should eq(
          "'#{local_time.to_utc.to_s("%F %H:%M:%S.%L")}'"
        )
      end

      it "returns the expected string representation for a bool value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column(false).should eq "0"
        schema_editor.quoted_default_value_for_built_in_column(true).should eq "1"
      end

      it "returns the expected string representation for an integer value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column(42).should eq "42"
      end

      it "returns the expected string representation for a float value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column(42.45).should eq "42.45"
      end

      it "returns the expected string representation for a float value" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.quoted_default_value_for_built_in_column(42.44).should eq "42.44"
      end
    end
  end
end
