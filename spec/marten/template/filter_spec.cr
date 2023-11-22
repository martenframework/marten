require "./spec_helper"

describe Marten::Template::Filter do
  describe "::get" do
    it "returns the right built-in filter classes for the expected filter names" do
      Marten::Template::Filter.registry.size.should eq 11
      Marten::Template::Filter.get("capitalize").should be_a Marten::Template::Filter::Capitalize
      Marten::Template::Filter.get("default").should be_a Marten::Template::Filter::Default
      Marten::Template::Filter.get("downcase").should be_a Marten::Template::Filter::DownCase
      Marten::Template::Filter.get("escape").should be_a Marten::Template::Filter::Escape
      Marten::Template::Filter.get("join").should be_a Marten::Template::Filter::Join
      Marten::Template::Filter.get("linebreaks").should be_a Marten::Template::Filter::LineBreaks
      Marten::Template::Filter.get("safe").should be_a Marten::Template::Filter::Safe
      Marten::Template::Filter.get("size").should be_a Marten::Template::Filter::Size
      Marten::Template::Filter.get("split").should be_a Marten::Template::Filter::Split
      Marten::Template::Filter.get("time").should be_a Marten::Template::Filter::Time
      Marten::Template::Filter.get("upcase").should be_a Marten::Template::Filter::UpCase
    end

    it "returns a registered filter class for a given name string" do
      Marten::Template::Filter.get("default").should be_a Marten::Template::Filter::Default
    end

    it "returns a registered filter class for a given name symbol" do
      Marten::Template::Filter.get(:default).should be_a Marten::Template::Filter::Default
    end

    it "raises an InvalidSyntax error if no filter class is registered for the given name" do
      expect_raises(Marten::Template::Errors::InvalidSyntax, "Unknown filter with name 'unknown'") do
        Marten::Template::Filter.get("unknown")
      end
    end
  end

  describe "::register" do
    it "allows to register a filter class from a name string" do
      Marten::Template::Filter.register("__spec_test__", Marten::Template::FilterSpec::Test)
      Marten::Template::Filter.get("__spec_test__").should be_a Marten::Template::FilterSpec::Test
    end

    it "allows to register a filter class from a name symbol" do
      Marten::Template::Filter.register(:__spec_test__, Marten::Template::FilterSpec::Test)
      Marten::Template::Filter.get(:__spec_test__).should be_a Marten::Template::FilterSpec::Test
    end
  end
end

module Marten::Template::FilterSpec
  class Test < Marten::Template::Filter::Base
    def apply(value : Value, arg : Value? = nil) : Value
      value
    end
  end
end
