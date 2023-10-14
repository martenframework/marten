require "./spec_helper"
require "./schema_spec/other_app/app"

describe Marten::CLI::Generator::Schema do
  around_each do |t|
    Marten::CLI::Generator::SchemaSpec.empty_main_app_path
    Marten::CLI::Generator::SchemaSpec.empty_other_app_path

    t.run

    Marten::CLI::Generator::SchemaSpec.empty_main_app_path
    Marten::CLI::Generator::SchemaSpec.empty_other_app_path
  end

  describe "#run" do
    context "when targetting the main application" do
      with_main_app_location "#{__DIR__}/schema_spec/main_app/"

      it "generates the expected schema file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["schema", "MySchema", "title:string", "label:string:optional"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/schema_spec/main_app/schemas/my_schema.cr")).should be_true,
          "Schema file does not exist"

        schema_content = File.read(File.join("#{__DIR__}/schema_spec/main_app/schemas/my_schema.cr"))

        schema_content.includes?("class MySchema < Marten::Schema").should be_true,
          "Schema file does not contain the expected class name"
        schema_content.includes?("field :title, :string").should be_true,
          "Schema file does not contain the expected title field"
        schema_content.includes?("field :label, :string, required: false").should be_true,
          "Schema file does not contain the expected title field"
      end

      it "generates the expected schema file when the --parent option is used" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["schema", "MySchema", "title:string", "label:string:optional", "--parent=BaseSchema"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/schema_spec/main_app/schemas/my_schema.cr")).should be_true,
          "Schema file does not exist"

        schema_content = File.read(File.join("#{__DIR__}/schema_spec/main_app/schemas/my_schema.cr"))

        schema_content.includes?("class MySchema < BaseSchema").should be_true,
          "Schema file does not contain the expected class name"
        schema_content.includes?("field :title, :string").should be_true,
          "Schema file does not contain the expected title field"
        schema_content.includes?("field :label, :string, required: false").should be_true,
          "Schema file does not contain the expected title field"
      end

      it "appends the Schema suffix to the schema name if it is not specified" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["schema", "ArticleCreate", "title:string", "label:string:optional"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/schema_spec/main_app/schemas/article_create_schema.cr")).should be_true,
          "Schema file does not exist"

        schema_content = File.read(File.join("#{__DIR__}/schema_spec/main_app/schemas/article_create_schema.cr"))

        schema_content.includes?("class ArticleCreateSchema < Marten::Schema").should be_true,
          "Schema file does not contain the expected class name"
        schema_content.includes?("field :title, :string").should be_true,
          "Schema file does not contain the expected title field"
        schema_content.includes?("field :label, :string, required: false").should be_true,
          "Schema file does not contain the expected title field"
      end
    end

    context "when targetting a specific application" do
      with_installed_apps Marten::CLI::Generator::SchemaSpec::App

      it "generates the expected schema file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: [
            "schema",
            "MySchema",
            "title:string",
            "label:string:optional",
            "--app=cli_generator_schema_spec_other_app",
          ],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/schema_spec/other_app/schemas/my_schema.cr")).should be_true,
          "Schema file does not exist"

        schema_content = File.read(File.join("#{__DIR__}/schema_spec/other_app/schemas/my_schema.cr"))

        schema_content.includes?("class Marten::CLI::Generator::SchemaSpec::MySchema < Marten::Schema").should be_true,
          "Schema file does not contain the expected class name"
        schema_content.includes?("field :title, :string").should be_true,
          "Schema file does not contain the expected title field"
        schema_content.includes?("field :label, :string, required: false").should be_true,
          "Schema file does not contain the expected title field"
      end

      it "prints the expected error message and exit if the application does not exist" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["schema", "ArticleCreate", "title:string", "label:string:optional", "--app=unknown"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr,
          exit_raises: true
        )

        exit_code = command.handle

        exit_code.should eq 1

        stderr.rewind.gets_to_end.includes?("Label 'unknown' is not associated with any installed apps").should be_true
      end
    end

    it "outputs the expected error if no schema name is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["schema"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("A schema name must be specified").should be_true
    end

    it "outputs the expected error if the specified schema name is not CamelCase" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["schema", "test_schema"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("The schema name must be CamelCase").should be_true
    end

    it "outputs the expected error if one of the field definitions is invalid" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["schema", "MySchema", "name:unknown"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stderr.rewind.gets_to_end

      output.includes?("'name:unknown' is not a valid field definition").should be_true
      output.includes?("The field type 'unknown' does not correspond to an existing field type.").should be_true
    end
  end
end

module Marten::CLI::Generator::SchemaSpec
  def self.empty_main_app_path
    Dir.glob(File.join("#{__DIR__}/schema_spec/main_app/", "/**/*")).map do |path|
      FileUtils.rm_rf(path)
    end
  end

  def self.empty_other_app_path
    Dir.glob(File.join("#{__DIR__}/schema_spec/other_app/", "/**/*"))
      .reject(&.ends_with?("app.cr"))
      .map do |path|
        FileUtils.rm_rf(path)
      end
  end
end
