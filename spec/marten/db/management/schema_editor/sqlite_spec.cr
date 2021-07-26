require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "sqlite" || !env("MARTEN_SPEC_DB_CONNECTION") %}
  describe Marten::DB::Management::SchemaEditor::SQLite do
    describe "#column_type_for_built_in_column" do
      it "returns the expected column types" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        expected_mapping = {
          "Marten::DB::Management::Column::Auto"       => "integer",
          "Marten::DB::Management::Column::BigAuto"    => "integer",
          "Marten::DB::Management::Column::BigInt"     => "integer",
          "Marten::DB::Management::Column::Bool"       => "bool",
          "Marten::DB::Management::Column::DateTime"   => "datetime",
          "Marten::DB::Management::Column::ForeignKey" => "integer",
          "Marten::DB::Management::Column::Int"        => "integer",
          "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
          "Marten::DB::Management::Column::Text"       => "text",
          "Marten::DB::Management::Column::UUID"       => "char(32)",
        }

        expected_mapping.each do |column_id, column_type|
          schema_editor.column_type_for_built_in_column(column_id).should eq column_type
        end
      end
    end

    describe "#column_type_suffix_for_built_in_column" do
      it "returns nil" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        expected_mapping = {
          "Marten::DB::Management::Column::Auto"       => "AUTOINCREMENT",
          "Marten::DB::Management::Column::BigAuto"    => "AUTOINCREMENT",
          "Marten::DB::Management::Column::BigInt"     => nil,
          "Marten::DB::Management::Column::Bool"       => nil,
          "Marten::DB::Management::Column::DateTime"   => nil,
          "Marten::DB::Management::Column::ForeignKey" => nil,
          "Marten::DB::Management::Column::Int"        => nil,
          "Marten::DB::Management::Column::String"     => nil,
          "Marten::DB::Management::Column::Text"       => nil,
          "Marten::DB::Management::Column::UUID"       => nil,
        }

        expected_mapping.each do |column_id, column_suffix|
          schema_editor.column_type_suffix_for_built_in_column(column_id).should eq column_suffix
        end
      end
    end

    describe "#ddl_rollbackable?" do
      it "returns true" do
        Marten::DB::Connection.default.schema_editor.ddl_rollbackable?.should be_true
      end
    end

    describe "#quoted_default_value_for_built_in_column" do
      it "returns the expected string representation for a byte value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(Bytes[255, 97]).should eq "X'ff61'"
      end

      it "returns the expected string representation for a string value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column("hello").should eq "'hello'"
        schema_editor.quoted_default_value_for_built_in_column(%{value " quote}).should eq "'value \" quote'"
      end

      it "returns the expected string representation for a time value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        local_time = Time.local
        schema_editor.quoted_default_value_for_built_in_column(local_time).should eq(
          "'#{local_time.to_utc.to_s("%F %H:%M:%S.%L")}'"
        )
      end

      it "returns the expected string representation for a bool value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(false).should eq "0"
        schema_editor.quoted_default_value_for_built_in_column(true).should eq "1"
      end

      it "returns the expected string representation for an integer value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(42).should eq "42"
      end

      it "returns the expected string representation for a float value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(42.44).should eq "42.44"
      end
    end
  end
{% end %}
