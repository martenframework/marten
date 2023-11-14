require "./spec_helper"
require "./context_spec/app"

describe Marten::CLI::Generator::Email::Context do
  with_installed_apps Marten::CLI::Generator::Email::ContextSpec::App

  describe "#email_filename" do
    it "returns the email filename" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.main, "TestEmail")

      context.email_filename.should eq "test_email.cr"
    end
  end

  describe "#class_name" do
    it "returns the expected class name if the email should be created in the main application" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.main, "TestEmail")

      context.class_name.should eq "TestEmail"
    end

    it "returns the expected class name if the email should be created in an application that isn't namespaced" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.get(:app), "TestEmail")

      context.class_name.should eq "TestEmail"
    end

    it "returns the expected class name if the email should be created in an application that is namespaced" do
      context = Marten::CLI::Generator::Email::Context.new(
        Marten.apps.get(:cli_generator_email_context_spec_app),
        "TestEmail"
      )

      context.class_name.should eq "Marten::CLI::Generator::Email::ContextSpec::TestEmail"
    end
  end

  describe "#html_template_filepath" do
    it "returns the expected filepath if the email should be created in the main application" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.main, "TestEmail")

      context.html_template_filepath.should eq "emails/test_email.html"
    end

    it "returns the expected filepath if the email should be created in a specific application" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.get(:app), "TestEmail")

      context.html_template_filepath.should eq "app/emails/test_email.html"
    end
  end

  describe "#text_template_filepath" do
    it "returns the expected filepath if the email should be created in the main application" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.main, "TestEmail")

      context.text_template_filepath.should eq "emails/test_email.txt"
    end

    it "returns the expected filepath if the email should be created in a specific application" do
      context = Marten::CLI::Generator::Email::Context.new(Marten.apps.get(:app), "TestEmail")

      context.text_template_filepath.should eq "app/emails/test_email.txt"
    end
  end
end
