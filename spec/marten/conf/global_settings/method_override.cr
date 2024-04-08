require "./spec_helper"

describe Marten::Conf::GlobalSettings::MethodOverride do
  describe "#allowed_methods" do
    it "allows `DELETE`, `PATCH`, `PUT`" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new

      method_override_conf.allowed_methods.should_not be_empty
      method_override_conf.allowed_methods.size.should eq(3)
      method_override_conf.allowed_methods.should contain("DELETE")
      method_override_conf.allowed_methods.should contain("PATCH")
      method_override_conf.allowed_methods.should contain("PUT")
    end

    it "returns the configured allowed methods" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new
      method_override_conf.allowed_methods = ["post"]

      method_override_conf.allowed_methods.should eq ["POST"]
    end
  end

  describe "#allowed_methods=" do
    it "allows to set the allowed methods" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new

      method_override_conf.allowed_methods = ["post"]

      method_override_conf.allowed_methods.should eq ["POST"]
    end
  end

  describe "#input_name" do
    it "should equal `_method` by default" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new

      method_override_conf.input_name.should eq("_method")
    end

    it "returns the configured input name" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new
      method_override_conf.input_name = "_custom_method"

      method_override_conf.input_name.should eq "_custom_method"
    end
  end

  describe "#input_name=" do
    it "allows to set the input name" do
      method_override_conf = Marten::Conf::GlobalSettings::MethodOverride.new

      method_override_conf.input_name = "_custom_method"

      method_override_conf.input_name.should eq "_custom_method"
    end
  end
end
