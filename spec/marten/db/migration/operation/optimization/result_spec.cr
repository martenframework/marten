require "./spec_helper"

describe Marten::DB::Migration::Operation::Optimization::Result do
  describe "::completed" do
    it "creates a completed optimization result without operations" do
      result = Marten::DB::Migration::Operation::Optimization::Result.completed

      result.completed?.should be_true
      result.operations.should be_empty
    end

    it "creates a completed optimization result with operations" do
      operation_1 = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table_1")
      operation_2 = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table_2")
      result = Marten::DB::Migration::Operation::Optimization::Result.completed(operation_1, operation_2)

      result.completed?.should be_true
      result.operations.should eq [operation_1, operation_2]
    end
  end

  describe "::failed" do
    it "creates a failed optimization result without operations" do
      result = Marten::DB::Migration::Operation::Optimization::Result.failed

      result.failed?.should be_true
      result.operations.should be_empty
    end
  end

  describe "::unchanged" do
    it "creates an unchanged optimization result without operations" do
      result = Marten::DB::Migration::Operation::Optimization::Result.unchanged

      result.unchanged?.should be_true
      result.operations.should be_empty
    end
  end

  describe "#completed?" do
    it "returns true if the result type is 'completed'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.completed
      result.completed?.should be_true
    end

    it "returns false if the result type is not 'completed'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.failed
      result.completed?.should be_false
    end
  end

  describe "#failed?" do
    it "returns true if the result type is 'failed'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.failed
      result.failed?.should be_true
    end

    it "returns false if the result type is not 'failed'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.completed
      result.failed?.should be_false
    end
  end

  describe "#operations" do
    it "returns the associated operations" do
      operation_1 = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table_1")
      operation_2 = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table_2")
      result = Marten::DB::Migration::Operation::Optimization::Result.completed(operation_1, operation_2)

      result.operations.should eq [operation_1, operation_2]
    end
  end

  describe "#unchanged?" do
    it "returns true if the result type is 'unchanged'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.unchanged
      result.unchanged?.should be_true
    end

    it "returns false if the result type is not 'unchanged'" do
      result = Marten::DB::Migration::Operation::Optimization::Result.completed
      result.unchanged?.should be_false
    end
  end
end
