require "./spec_helper"

describe Marten::DB::Migration::Operation::Base do
  describe "#faked?" do
    it "returns false by default" do
      operation = Marten::DB::Migration::Operation::BaseSpec::Test.new
      operation.faked?.should be_false
    end

    it "returns true if faking is enabled" do
      operation = Marten::DB::Migration::Operation::BaseSpec::Test.new
      operation.faked = true
      operation.faked?.should be_true
    end
  end

  describe "#faked=" do
    it "allows to enable faking" do
      operation = Marten::DB::Migration::Operation::BaseSpec::Test.new
      operation.faked = true
      operation.faked?.should be_true
    end
  end
end

class Marten::DB::Migration::Operation::BaseSpec
  class Test < Marten::DB::Migration::Operation::Base
    def describe : String
      "Dummy operation"
    end

    def mutate_db_backward(
      app_label : String,
      schema_editor : Management::SchemaEditor::Base,
      from_state : Management::ProjectState,
      to_state : Management::ProjectState
    ) : Nil
      # noop
    end

    def mutate_db_forward(
      app_label : String,
      schema_editor : Management::SchemaEditor::Base,
      from_state : Management::ProjectState,
      to_state : Management::ProjectState
    ) : Nil
      # noop
    end

    def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
      # noop
    end

    def optimize(operation : Base) : Optimization::Result
      Marten::DB::Migration::Operation::Optimization::Result.failed
    end

    def references_column?(other_table_name : String, other_column_name : String) : Bool
      false
    end

    def references_table?(other_table_name : String) : Bool
      false
    end

    def serialize : String
      raise NotImplementedError.new("Can't be serialized")
    end
  end
end
