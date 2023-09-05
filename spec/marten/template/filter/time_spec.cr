require "./spec_helper"

describe Marten::Template::Filter::Time do
  describe "#apply" do
    it "returns the expected formatted time when no argument is specified" do
      time = Time.local
      filter = Marten::Template::Filter::Time.new

      filter.apply(Marten::Template::Value.from(time)).should eq time.to_s
    end

    it "returns the expected formatted time when an argument is specified" do
      time = Time.local
      filter = Marten::Template::Filter::Time.new

      filter.apply(Marten::Template::Value.from(time), Marten::Template::Value.from("%Y-%m-%d"))
        .should eq time.to_s("%Y-%m-%d")
    end

    it "raises the expected exception when the passed template value is not a time object" do
      filter = Marten::Template::Filter::Time.new

      bad_value = 42

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "The time filter can only be used on time objects, #{bad_value.class} given"
      ) do
        filter.apply(Marten::Template::Value.from(bad_value))
      end
    end
  end
end
