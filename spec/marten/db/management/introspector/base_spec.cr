require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  around_each do |t|
    schema_editor = Marten::DB::Connection.default.schema_editor
    schema_editor.create_model(TestUser)

    t.run

    schema_editor.delete_model(TestUser)
  end

  describe "#table_names" do
    it "returns the table names of the associated database connection" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      introspector.table_names.should contain(TestUser.db_table)
      introspector.table_names.should_not contain("unknown_table")
    end
  end
end
