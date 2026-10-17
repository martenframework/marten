require "./spec_helper"

describe Marten::Core::Validation::Error do
  describe "::new" do
    it "allows to initialize an error from a message and a specific type string" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid")
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should be_nil
    end

    it "allows to initialize an error from a message and a specific type symbol" do
      error = Marten::Core::Validation::Error.new("This is not valid", :invalid)
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should be_nil
    end

    it "allows to initialize an error associated with a specific field string" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should eq "content"
    end

    it "allows to initialize an error associated with a specific field symbol" do
      error = Marten::Core::Validation::Error.new("This is not valid", :invalid, :content)
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should eq "content"
    end
  end

  describe "#message" do
    it "returns the specified error message" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.message.should eq "This is not valid"
    end
  end

  describe "#type" do
    it "returns the specified error type" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.type.should eq "invalid"
    end
  end

  describe "#field" do
    it "defaults to nil" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid")
      error.field.should be_nil
    end

    it "returns the specified error field" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.field.should eq "content"
    end
  end

  describe "#to_json" do
    it "serializes a field error as an object with field, type, and message" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.to_json.should eq %({"field":"content","type":"invalid","message":"This is not valid"})
    end

    it "serializes a global error with a null field" do
      error = Marten::Core::Validation::Error.new("This is not valid", :invalid)
      error.to_json.should eq %({"field":null,"type":"invalid","message":"This is not valid"})
    end
  end
end
