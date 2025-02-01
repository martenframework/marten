require "./spec_helper"

describe Marten::Routing::ReverseResult do
  describe "when initialized with a URL" do
    result = Marten::Routing::ReverseResult.new("/test/hello")

    it "sets the URL correctly" do
      result.url.should eq "/test/hello"
    end

    it "has a nil mismatch" do
      result.mismatch.should be_nil
    end

    it "reports success" do
      result.success?.should be_true
    end
  end

  describe "when initialized with a mismatch" do
    mismatch = Marten::Routing::ReverseResult::Mismatch.new(
      ["param1"],
      ["param2"],
      [{"param3", "value3".as(Marten::Routing::Parameter::Types)}]
    )
    result = Marten::Routing::ReverseResult.new(mismatch)

    it "leaves the URL nil" do
      result.url.should be_nil
    end

    it "stores a non-nil mismatch" do
      result.mismatch.should_not be_nil
    end

    it "reports failure" do
      result.success?.should be_false
    end

    it "contains the correct mismatch details" do
      mismatch = result.mismatch.not_nil!
      mismatch.missing_params.should eq ["param1"]
      mismatch.extra_params.should eq ["param2"]
      mismatch.invalid_params.should eq [{"param3", "value3".as(Marten::Routing::Parameter::Types)}]
    end
  end

  describe Marten::Routing::ReverseResult::Mismatch, "#empty?" do
    it "returns true when all arrays are empty" do
      mismatch = Marten::Routing::ReverseResult::Mismatch.new(
        [] of String,
        [] of String,
        [] of Tuple(String, Marten::Routing::Parameter::Types),
      )
      mismatch.empty?.should be_true
    end

    it "returns true when at least one array is empty (even if others are non-empty)" do
      # Here, missing_params is empty while extra_params and invalid_params are non-empty.
      mismatch = Marten::Routing::ReverseResult::Mismatch.new(
        [] of String,
        ["extra"],
        [{"invalid", 32.as(Marten::Routing::Parameter::Types)}]
      )
      mismatch.empty?.should be_true
    end

    it "returns false when all arrays are non-empty" do
      mismatch = Marten::Routing::ReverseResult::Mismatch.new(
        ["missing"],
        ["extra"],
        [{"invalid", 32.as(Marten::Routing::Parameter::Types)}]
      )
      mismatch.empty?.should be_false
    end
  end
end
