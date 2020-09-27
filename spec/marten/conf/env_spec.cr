require "./spec_helper"

describe Marten::Conf::Env do
  describe "#<env_name>?" do
    it "returns true if <env_name> corresponds to the current MARTEN_ENV env var" do
      Marten::Conf::Env.new.test?.should be_true
    end

    it "returns false if <env_name> don't correspond to the current MARTEN_ENV env var" do
      Marten::Conf::Env.new.dummy?.should be_false
    end
  end

  describe "#==" do
    it "returns true if the value corresponds to the current MARTEN_ENV env var" do
      (Marten::Conf::Env.new == "test").should be_true
    end

    it "returns false if the value don't correspond to the current MARTEN_ENV env var" do
      (Marten::Conf::Env.new == "dummy").should be_false
    end
  end

  describe "#id" do
    it "returns the environment identifier" do
      Marten::Conf::Env.new.id.should eq "test"
    end
  end

  describe "#to_s" do
    it "returns the environment identifier" do
      Marten::Conf::Env.new.to_s.should eq "test"
    end
  end
end
