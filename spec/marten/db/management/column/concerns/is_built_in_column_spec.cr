require "./spec_helper"

describe Marten::DB::Management::Column::IsBuiltInColumn do
  describe "#sql_quoted_default_value" do
    it "returns nil if the default value is nil" do
      obj = Marten::DB::Management::Column::IsBuiltInColumnSpec::Test.new(nil)
      obj.sql_quoted_default_value(Marten::DB::Connection.default).should be_nil
    end

    it "returns a quoted value" do
      obj = Marten::DB::Management::Column::IsBuiltInColumnSpec::Test.new("hello")
      obj.sql_quoted_default_value(Marten::DB::Connection.default).should eq %{'hello'}
    end
  end
end

module Marten::DB::Management::Column::IsBuiltInColumnSpec
  class Test
    include Marten::DB::Management::Column::IsBuiltInColumn

    getter default

    def initialize(@default : ::DB::Any)
    end
  end
end
