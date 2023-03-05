require "./spec_helper"

describe Marten::DB::Management::SchemaEditor::Base do
  describe "#delete_table" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "deletes the considered table state" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo", default: 42),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.delete_table(table_state.name)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("schema_editor_test_table").should be_false
    end
  end
end
