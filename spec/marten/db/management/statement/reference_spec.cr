require "./spec_helper"

describe Marten::DB::Management::Statement::Reference do
  describe "#references_column?" do
    it "returns false by default" do
      statement = Marten::DB::Management::Statement::ReferenceSpec::Test.new
      statement.references_column?("table", "column").should be_false
    end
  end

  describe "#references_table?" do
    it "returns false by default" do
      statement = Marten::DB::Management::Statement::ReferenceSpec::Test.new
      statement.references_table?("table").should be_false
    end
  end

  describe "#rename_column" do
    it "does nothing by default" do
      statement = Marten::DB::Management::Statement::ReferenceSpec::Test.new
      statement.rename_column("table", "column", "column_renamed").should be_nil
    end
  end

  describe "#rename_table" do
    it "does nothing by default" do
      statement = Marten::DB::Management::Statement::ReferenceSpec::Test.new
      statement.rename_table("table", "table_renamed").should be_nil
    end
  end
end

module Marten::DB::Management::Statement::ReferenceSpec
  class Test < Marten::DB::Management::Statement::Reference
  end
end
