require "./spec_helper"
require "./context_spec/app"

describe Marten::CLI::Generator::Model::Context do
  with_installed_apps Marten::CLI::Generator::Model::ContextSpec::App

  describe "#class_name" do
    it "returns the expected class name if the model should be created in the main application" do
      context = Marten::CLI::Generator::Model::Context.new(
        app_config: Marten.apps.main,
        name: "AuthorProfile",
        field_definitions: [] of Marten::CLI::Generator::Model::FieldDefinition,
        no_timestamps: false,
      )

      context.class_name.should eq "AuthorProfile"
    end

    it "returns the expected class name if the email should be created in an application that isn't namespaced" do
      context = Marten::CLI::Generator::Model::Context.new(
        app_config: Marten.apps.get(:app),
        name: "AuthorProfile",
        field_definitions: [] of Marten::CLI::Generator::Model::FieldDefinition,
        no_timestamps: false,
      )

      context.class_name.should eq "AuthorProfile"
    end

    it "returns the expected class name if the email should be created in an application that is namespaced" do
      context = Marten::CLI::Generator::Model::Context.new(
        Marten.apps.get(:cli_generator_model_context_spec_app),
        name: "AuthorProfile",
        field_definitions: [] of Marten::CLI::Generator::Model::FieldDefinition,
        no_timestamps: false,
      )

      context.class_name.should eq "Marten::CLI::Generator::Model::ContextSpec::AuthorProfile"
    end
  end

  describe "#field_definitions" do
    it "returns all the specified field definitions except the primary key" do
      context = Marten::CLI::Generator::Model::Context.new(
        Marten.apps.get(:cli_generator_model_context_spec_app),
        name: "AuthorProfile",
        field_definitions: [
          Marten::CLI::Generator::Model::FieldDefinition.from_argument("id:big_int:primary_key:auto"),
          Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string:unique:index"),
        ],
        no_timestamps: false,
      )

      context.field_definitions.size.should eq 1
      context.field_definitions[0].name.should eq "name"
    end
  end

  describe "#model_filename" do
    it "returns the model filename" do
      context = Marten::CLI::Generator::Model::Context.new(
        app_config: Marten.apps.main,
        name: "AuthorProfile",
        field_definitions: [] of Marten::CLI::Generator::Model::FieldDefinition,
        no_timestamps: false,
      )

      context.model_filename.should eq "author_profile.cr"
    end
  end

  describe "#pk_field_definition" do
    it "returns the PK field definition extracted from the field definitions specified at initialization time" do
      pk_field_definition = Marten::CLI::Generator::Model::FieldDefinition.from_argument(
        "custom_id:big_int:primary_key:auto"
      )

      context = Marten::CLI::Generator::Model::Context.new(
        Marten.apps.get(:cli_generator_model_context_spec_app),
        name: "AuthorProfile",
        field_definitions: [
          pk_field_definition,
          Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string:unique:index"),
        ],
        no_timestamps: false,
      )

      context.pk_field_definition.should eq pk_field_definition
    end

    it "returns a default PK field definition if no primary key field was specified at initialization time" do
      context = Marten::CLI::Generator::Model::Context.new(
        Marten.apps.get(:cli_generator_model_context_spec_app),
        name: "AuthorProfile",
        field_definitions: [
          Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string:unique:index"),
        ],
        no_timestamps: false,
      )

      context.pk_field_definition.name.should eq "id"
      context.pk_field_definition.type.should eq "big_int"
      context.pk_field_definition.primary_key?.should be_true
      context.pk_field_definition.modifiers
        .includes?(Marten::CLI::Generator::Model::FieldDefinition::Modifier::AUTO)
        .should be_true
    end
  end
end
