require "./spec_helper"

describe Marten::CLI::Generator::Schema::FieldDefinition do
  describe "::from_argument" do
    it "parses a simple field definition" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.from_argument("name:string")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
    end

    it "parses a field definition containing modifiers" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.from_argument("name:string:optional")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq [Marten::CLI::Generator::Schema::FieldDefinition::Modifier::OPTIONAL]
    end

    it "parses the field name in a case-insensitive way" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.from_argument("NAME:string")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
    end

    it "parses the field type in a case-insensitive way" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.from_argument("name:STRING")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
    end

    it "parses the field modifiers in a case-insensitive way" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.from_argument("name:string:OPTIONAL")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq [Marten::CLI::Generator::Schema::FieldDefinition::Modifier::OPTIONAL]
    end

    it "raises an ArgumentError exception if the passed value is malformed" do
      [
        "name",
        "this is bad",
        "name:string:this is bad",
      ].each do |bad_value|
        expect_raises(ArgumentError, "'#{bad_value}' is not a valid field definition") do
          Marten::CLI::Generator::Schema::FieldDefinition.from_argument(bad_value)
        end
      end
    end

    it "raises an ArgumentError exception if the field definition references an unknown field type" do
      expect_raises(ArgumentError, "'test:unknown' is not a valid field definition") do
        Marten::CLI::Generator::Schema::FieldDefinition.from_argument("test:unknown")
      end
    end

    it "raises an ArgumentError exception if the field definition references an unknown modifier" do
      expect_raises(ArgumentError, "'test:string:unknown' is not a valid field definition") do
        Marten::CLI::Generator::Schema::FieldDefinition.from_argument("test:string:unknown")
      end
    end
  end

  describe "#render" do
    it "returns the expected value for a simple field definition" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.new(
        name: "test",
        type: "big_int",
        modifiers: [] of Marten::CLI::Generator::Schema::FieldDefinition::Modifier,
      )

      field.render.should eq "field :test, :big_int"
    end

    it "returns the expected value for a field definition involving the OPTIONAL modifier" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [Marten::CLI::Generator::Schema::FieldDefinition::Modifier::OPTIONAL],
      )

      field.render.should eq "field :test, :string, required: false"
    end

    it "returns the expected value for a field definition involving the BLANK modifier" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [Marten::CLI::Generator::Schema::FieldDefinition::Modifier::BLANK],
      )

      field.render.should eq "field :test, :string, required: false"
    end

    it "returns the expected value for a field definition involving the REQUIRED modifier" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [Marten::CLI::Generator::Schema::FieldDefinition::Modifier::REQUIRED],
      )

      field.render.should eq "field :test, :string, required: true"
    end

    it "returns does not include the output of modifiers that have the same effect multiple times" do
      field = Marten::CLI::Generator::Schema::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Schema::FieldDefinition::Modifier::OPTIONAL,
          Marten::CLI::Generator::Schema::FieldDefinition::Modifier::BLANK,
        ],
      )

      field.render.should eq "field :test, :string, required: false"
    end
  end
end
