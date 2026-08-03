require "./spec_helper"

describe Marten::Template::Filter::Truncate do
  describe "#apply" do
    it "returns the original string when it is shorter than or equal to the limit" do
      filter = Marten::Template::Filter::Truncate.new

      filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from(5)).should eq "hello"
      filter.apply(Marten::Template::Value.from("hi"), Marten::Template::Value.from(5)).should eq "hi"
    end

    it "truncates a string and appends an ellipsis" do
      filter = Marten::Template::Filter::Truncate.new

      filter.apply(
        Marten::Template::Value.from("Once upon a time in a world far far away"),
        Marten::Template::Value.from(27)
      ).should eq "Once upon a time in a wo..."
    end

    it "accounts for the ellipsis in the resulting size" do
      filter = Marten::Template::Filter::Truncate.new

      result = filter.apply(Marten::Template::Value.from("abcdefghij"), Marten::Template::Value.from(5))
      result.should eq "ab..."
      result.to_s.size.should eq 5
    end

    it "returns a prefix of the ellipsis when the limit is smaller than the omission" do
      filter = Marten::Template::Filter::Truncate.new

      filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from(2)).should eq ".."
      filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from(0)).should eq ""
    end

    it "accepts integer arguments provided as strings" do
      filter = Marten::Template::Filter::Truncate.new

      filter.apply(Marten::Template::Value.from("abcdefghij"), Marten::Template::Value.from("5")).should eq "ab..."
    end

    it "raises if the argument is not specified" do
      filter = Marten::Template::Filter::Truncate.new

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "The 'truncate' filter requires one argument"
      ) do
        filter.apply(Marten::Template::Value.from("hello"))
      end
    end

    it "raises if the argument is not an integer" do
      filter = Marten::Template::Filter::Truncate.new

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "The 'truncate' filter requires an integer argument, Bool given"
      ) do
        filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from(true))
      end
    end

    it "raises if the argument is negative" do
      filter = Marten::Template::Filter::Truncate.new

      expect_raises(
        Marten::Template::Errors::UnsupportedValue,
        "The 'truncate' filter requires a non-negative integer argument"
      ) do
        filter.apply(Marten::Template::Value.from("hello"), Marten::Template::Value.from(-1))
      end
    end
  end
end
