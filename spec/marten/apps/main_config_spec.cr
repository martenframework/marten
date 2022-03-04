require "./spec_helper"

describe Marten::Apps::MainConfig do
  describe "::label" do
    it "returns the expected reserved label" do
      Marten::Apps::MainConfig.label.should eq "main"
    end
  end

  describe "::_marten_app_location" do
    it "returns the relative src folder path" do
      Marten::Apps::MainConfig._marten_app_location.should eq Path["src"].expand.to_s
    end
  end
end
