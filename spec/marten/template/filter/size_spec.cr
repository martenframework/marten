require "./spec_helper"

describe Marten::Template::Filter::Size do
  describe "#apply" do
    it "returns the size of a string" do
      filter = Marten::Template::Filter::Size.new

      val = filter.apply(Marten::Template::Value.from("hello"))
      val.raw.should eq 5
    end

    it "returns the size of an array" do
      filter = Marten::Template::Filter::Size.new

      val = filter.apply(Marten::Template::Value.from(["foo", "bar"]))
      val.raw.should eq 2
    end

    it "returns the size of a hash" do
      filter = Marten::Template::Filter::Size.new

      val = filter.apply(Marten::Template::Value.from({"foo" => "bar", "test" => "xyz"}))
      val.raw.should eq 2
    end

    it "raises for unsupported values" do
      filter = Marten::Template::Filter::Size.new

      expect_raises(Marten::Template::Errors::UnsupportedType, "Nil objects don't have a size") do
        filter.apply(Marten::Template::Value.from(nil))
      end

      expect_raises(Marten::Template::Errors::UnsupportedType, "Int32 objects don't have a size") do
        filter.apply(Marten::Template::Value.from(12))
      end
    end
  end
end
