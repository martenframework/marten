require "./spec_helper"

describe Marten::DB::CanFormatStringsOrSymbols do
  describe "#format_string_or_symbol" do
    it "returns the expected output for valid Crystal identifiers" do
      test = Marten::DB::CanFormatStringsOrSymbolsSpec::Test.new
      test.format_string_or_symbol("foobar").should eq %{:foobar}
      test.format_string_or_symbol("foobar123").should eq %{:foobar123}
      test.format_string_or_symbol("foobar_123").should eq %{:foobar_123}
      test.format_string_or_symbol("_foobar_123").should eq %{:_foobar_123}
    end

    it "returns the expected output for other values" do
      test = Marten::DB::CanFormatStringsOrSymbolsSpec::Test.new
      test.format_string_or_symbol("FooBar").should eq %{"FooBar"}
      test.format_string_or_symbol("this is a test").should eq %{"this is a test"}
    end
  end
end

module Marten::DB::CanFormatStringsOrSymbolsSpec
  class Test
    include Marten::DB::CanFormatStringsOrSymbols
  end
end
