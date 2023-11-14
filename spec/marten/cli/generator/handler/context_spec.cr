require "./spec_helper"
require "./context_spec/app"

describe Marten::CLI::Generator::Handler::Context do
  with_installed_apps Marten::CLI::Generator::Handler::ContextSpec::App

  describe "#class_name" do
    it "returns the expected class name if the handler should be created in the main application" do
      context = Marten::CLI::Generator::Handler::Context.new(
        app_config: Marten.apps.main,
        name: "TestHandler",
      )

      context.class_name.should eq "TestHandler"
    end

    it "returns the expected class name if the handler should be created in an application that isn't namespaced" do
      context = Marten::CLI::Generator::Handler::Context.new(
        app_config: Marten.apps.get(:app),
        name: "TestHandler",
      )

      context.class_name.should eq "TestHandler"
    end

    it "returns the expected class name if the handler should be created in an application that is namespaced" do
      context = Marten::CLI::Generator::Handler::Context.new(
        Marten.apps.get(:cli_generator_handler_context_spec_app),
        name: "TestHandler",
      )

      context.class_name.should eq "Marten::CLI::Generator::Handler::ContextSpec::TestHandler"
    end
  end

  describe "#handler_filename" do
    it "returns the handler filename" do
      context = Marten::CLI::Generator::Handler::Context.new(
        app_config: Marten.apps.main,
        name: "TestHandler",
      )

      context.handler_filename.should eq "test_handler.cr"
    end
  end
end
