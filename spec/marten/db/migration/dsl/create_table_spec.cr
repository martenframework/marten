require "./spec_helper"

describe Marten::DB::Migration::DSL::CreateTable do
  describe "#build" do
    it "allows to yield the table object in order to define a simple table" do
      obj = Marten::DB::Migration::DSL::CreateTableSpec::Test.new
      table_dsl = obj.build_simple_table
      operation = table_dsl.operation

      operation.should be_a Marten::DB::Migration::Operation::CreateTable

      operation.name.should eq "my_table"

      operation.columns.size.should eq 3
      operation.columns[0].name.should eq "id"
      operation.columns[1].name.should eq "foo"
      operation.columns[2].name.should eq "bar"
    end

    it "allows to yield the table object in order to define a table with constraints" do
      obj = Marten::DB::Migration::DSL::CreateTableSpec::Test.new
      table_dsl = obj.build_table_with_constraints
      operation = table_dsl.operation

      operation.should be_a Marten::DB::Migration::Operation::CreateTable

      operation.name.should eq "my_table"

      operation.columns.size.should eq 3
      operation.columns[0].name.should eq "id"
      operation.columns[1].name.should eq "foo"
      operation.columns[2].name.should eq "bar"

      operation.unique_constraints.size.should eq 1
      operation.unique_constraints[0].name.should eq "cname"
      operation.unique_constraints[0].column_names.should eq ["foo", "bar"]

      operation.indexes.size.should eq 1
      operation.indexes[0].name.should eq "index_name"
      operation.indexes[0].column_names.should eq ["foo", "bar"]
    end
  end
end

module Marten::DB::Migration::DSL::CreateTableSpec
  class Test
    include Marten::DB::Migration::DSL

    def build_simple_table
      table_dsl = Marten::DB::Migration::DSL::CreateTable.new("my_table")

      table_dsl.build do
        column :id, :big_int, primary_key: true, auto: true
        column :foo, :int, null: true
        column :bar, :int, null: true
      end
    end

    def build_table_with_constraints
      table_dsl = Marten::DB::Migration::DSL::CreateTable.new("my_table")

      table_dsl.build do
        column :id, :big_int, primary_key: true, auto: true
        column :foo, :int, null: true
        column :bar, :int, null: true

        unique_constraint :cname, [:foo, :bar]
        index :index_name, [:foo, :bar]
      end
    end
  end
end
