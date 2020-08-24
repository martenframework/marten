require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  describe "#table_names" do
    it "returns the table names of the associated database connection" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      schema_editor.create_model(Marten::DB::Management::Introspector::BaseSpec::TestModel)

      introspector = Marten::DB::Management::Introspector.for(connection)

      introspector.table_names.should contain(Marten::DB::Management::Introspector::BaseSpec::TestModel.table_name)
      introspector.table_names.should_not contain("unknown_table")
    end
  end
end

module Marten::DB::Management::Introspector::BaseSpec
  class TestModel < Marten::DB::Model
    table_name :introspector_test_model

    field :id, :big_auto, primary_key: true
    field :test, :string, max_size: 128
  end
end
