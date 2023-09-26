require "./spec_helper"

describe Marten::CLI::Generator::Model::FieldDefinition do
  describe "::from_argument" do
    it "parses a simple field definition" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
      field.qualifier.should be_nil
    end

    it "parses a field definition containing one modifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string:unique")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq [Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQUE]
      field.qualifier.should be_nil
    end

    it "parses a field definition containing multiple modifiers" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string:unique:index")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq(
        [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQUE,
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::INDEX,
        ]
      )
      field.qualifier.should be_nil
    end

    it "parses a field definition containing a qualfier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string{128}:unique:index")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq(
        [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQUE,
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::INDEX,
        ]
      )
      field.qualifier.should eq "128"
    end

    it "parses the field name in a case-insensitive way" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("NAME:string")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
      field.qualifier.should be_nil
    end

    it "parses the field type in a case-insensitive way" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:STRING")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should be_empty
      field.qualifier.should be_nil
    end

    it "parses the field qualifiers in a case-insensitive way" do
      field = Marten::CLI::Generator::Model::FieldDefinition.from_argument("name:string{128}:UNIQUE:INdex")

      field.name.should eq "name"
      field.type.should eq "string"
      field.modifiers.should eq(
        [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQUE,
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::INDEX,
        ]
      )
      field.qualifier.should eq "128"
    end

    it "raises an ArgumentError exception if the passed value is malformed" do
      [
        "name",
        "this is bad",
        "name:string:unique{this is bad}:index",
      ].each do |bad_value|
        expect_raises(ArgumentError, "'#{bad_value}' is not a valid field definition") do
          Marten::CLI::Generator::Model::FieldDefinition.from_argument(bad_value)
        end
      end
    end

    it "raises an ArgumentError exception if the field definition references an unknown field type" do
      expect_raises(ArgumentError, "'test:unknown' is not a valid field definition") do
        Marten::CLI::Generator::Model::FieldDefinition.from_argument("test:unknown")
      end
    end

    it "raises an ArgumentError exception if the field definition references an unknown modifier" do
      expect_raises(ArgumentError, "'test:string:unknown' is not a valid field definition") do
        Marten::CLI::Generator::Model::FieldDefinition.from_argument("test:string:unknown")
      end
    end
  end

  describe "#render" do
    it "returns the expected value for a simple field definition" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "big_int",
        modifiers: [] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field.render.should eq "field :test, :big_int"
    end

    it "returns the expected value for a field definition involving a qualifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: "128",
      )

      field.render.should eq "field :test, :string, max_size: 128"
    end

    it "returns the expected value for a field definition involving the auto modifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "big_int",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::PRIMARY_KEY,
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::AUTO,
        ],
        qualifier: nil,
      )

      field.render.should eq "field :test, :big_int, primary_key: true, auto: true"
    end

    it "returns the expected value for a field definition involving the index modifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "big_int",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::INDEX,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field.render.should eq "field :test, :big_int, index: true"
    end

    it "returns the expected value for a field definition involving the null modifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "big_int",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::NULL,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field.render.should eq "field :test, :big_int, blank: true, null: true"
    end

    it "returns the expected value for a field definition involving the primary key modifier" do
      field_1 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::PRIMARY,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_1.render.should eq "field :test, :string, max_size: 255, primary_key: true"

      field_2 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::PRIMARY_KEY,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_2.render.should eq "field :test, :string, max_size: 255, primary_key: true"
    end

    it "returns the expected value for a field definition involving the unique modifier" do
      field_1 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQ,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_1.render.should eq "field :test, :string, max_size: 255, unique: true"

      field_2 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::UNIQUE,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_2.render.should eq "field :test, :string, max_size: 255, unique: true"
    end
  end

  describe "#primary_key?" do
    it "returns true if the field definition contains the primary key modifier" do
      field_1 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::PRIMARY,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_1.primary_key?.should be_true

      field_2 = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [
          Marten::CLI::Generator::Model::FieldDefinition::Modifier::PRIMARY_KEY,
        ] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field_2.primary_key?.should be_true
    end

    it "returns false if the field definition does not contain the primary key modifier" do
      field = Marten::CLI::Generator::Model::FieldDefinition.new(
        name: "test",
        type: "string",
        modifiers: [] of Marten::CLI::Generator::Model::FieldDefinition::Modifier,
        qualifier: nil,
      )

      field.primary_key?.should be_false
    end
  end
end
