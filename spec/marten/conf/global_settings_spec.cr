require "./spec_helper"

describe Marten::Conf::GlobalSettings do
  describe "#allowed_hosts" do
    it "returns an empty list by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts.empty?.should be_true
    end
  end
end
