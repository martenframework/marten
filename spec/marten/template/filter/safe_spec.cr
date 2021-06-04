require "./spec_helper"

describe Marten::Template::Filter::Safe do
  describe "#apply" do
    it "returns a safe string version of the of the initial value" do
      filter = Marten::Template::Filter::Safe.new

      val_1 = filter.apply(Marten::Template::Value.from("hello"))
      val_1.raw.should be_a Marten::Template::SafeString
      val_1.raw.should eq "hello"

      val_2 = filter.apply(Marten::Template::Value.from(42))
      val_2.raw.should be_a Marten::Template::SafeString
      val_2.should eq "42"
    end
  end
end
