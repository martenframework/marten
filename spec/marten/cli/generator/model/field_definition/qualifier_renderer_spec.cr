require "./spec_helper"

describe Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer do
  describe "#registry" do
    it "exposes the expected qualifier renderer logic for many-to-many fields" do
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["many_to_many"].call("Tag")
        .should eq "to: Tag"
    end

    it "exposes the expected qualifier renderer logic for many-to-one fields" do
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["many_to_one"].call("Tag")
        .should eq "to: Tag"
    end

    it "exposes the expected qualifier renderer logic for one-to-one fields" do
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["one_to_one"].call("Tag")
        .should eq "to: Tag"
    end

    it "exposes the expected qualifier renderer logic for string fields" do
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["string"].call(nil)
        .should eq "max_size: 255"
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["string"].call("128")
        .should eq "max_size: 128"
    end

    it "exposes the expected qualifier renderer logic for text fields" do
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["text"].call(nil)
        .should be_nil
      Marten::CLI::Generator::Model::FieldDefinition::QualifierRenderer.registry["text"].call("128")
        .should eq "max_size: 128"
    end
  end
end
