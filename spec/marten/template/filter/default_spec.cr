require "./spec_helper"

describe Marten::Template::Filter::Default do
  describe "#apply" do
    it "returns the default value if the initial value is false" do
      filter = Marten::Template::Filter::Default.new
      filter.apply(Marten::Template::Value.from(false), Marten::Template::Value.from("default")).should eq "default"
    end

    it "returns the default value if the initial value is 0" do
      filter = Marten::Template::Filter::Default.new
      filter.apply(Marten::Template::Value.from(0), Marten::Template::Value.from("default")).should eq "default"
    end

    it "returns the default value if the initial value is nil" do
      filter = Marten::Template::Filter::Default.new
      filter.apply(Marten::Template::Value.from(nil), Marten::Template::Value.from("default")).should eq "default"
    end

    it "returns the initial value if it is an empty string" do
      filter = Marten::Template::Filter::Default.new
      filter.apply(Marten::Template::Value.from(""), Marten::Template::Value.from("default")).should eq ""
    end

    it "returns the initial value if it is truthy" do
      filter = Marten::Template::Filter::Default.new
      filter.apply(Marten::Template::Value.from(42), Marten::Template::Value.from("default")).should eq 42
      filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from("default")).should eq "hello"
    end

    it "raises if the initial value is not specified" do
      filter = Marten::Template::Filter::Default.new
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "The 'default' filter requires one argument"
      ) do
        filter.apply(Marten::Template::Value.from(42))
      end
    end
  end
end
