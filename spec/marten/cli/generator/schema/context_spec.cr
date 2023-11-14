require "./spec_helper"
require "./context_spec/app"

describe Marten::CLI::Generator::Schema::Context do
  with_installed_apps Marten::CLI::Generator::Schema::ContextSpec::App

  describe "#class_name" do
    it "returns the expected class name if the schema should be created in the main application" do
      context = Marten::CLI::Generator::Schema::Context.new(
        app_config: Marten.apps.main,
        name: "MySchema",
        field_definitions: [] of Marten::CLI::Generator::Schema::FieldDefinition,
      )

      context.class_name.should eq "MySchema"
    end

    it "returns the expected class name if the schema should be created in an application that isn't namespaced" do
      context = Marten::CLI::Generator::Schema::Context.new(
        app_config: Marten.apps.get(:app),
        name: "MySchema",
        field_definitions: [] of Marten::CLI::Generator::Schema::FieldDefinition,
      )

      context.class_name.should eq "MySchema"
    end

    it "returns the expected class name if the schema should be created in an application that is namespaced" do
      context = Marten::CLI::Generator::Schema::Context.new(
        Marten.apps.get(:cli_generator_schema_context_spec_app),
        name: "MySchema",
        field_definitions: [] of Marten::CLI::Generator::Schema::FieldDefinition,
      )

      context.class_name.should eq "Marten::CLI::Generator::Schema::ContextSpec::MySchema"
    end
  end

  describe "#schema_filename" do
    it "returns the schema filename" do
      context = Marten::CLI::Generator::Schema::Context.new(
        app_config: Marten.apps.main,
        name: "ArticleSchema",
        field_definitions: [] of Marten::CLI::Generator::Schema::FieldDefinition,
      )

      context.schema_filename.should eq "article_schema.cr"
    end
  end
end
